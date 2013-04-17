#!/usr/bin/perl
use strict;
use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;
use Encode;

my $file = $ARGV[0];
my $e_lang = $ARGV[1];

unless ($file && $e_lang)
{
    print "Usage $0 <file> <lang>";
    exit -1;
}

my $ua = LWP::UserAgent->new;
my $service = "http://localhost:8080/exist/rest/db/xq/frbrsips.xq";

my @no_ids;
my @stoa_assign;
my @need_stoa;
open NOIDS, ">noids.out" or die $!;
open FILE, "<$file" or die "Can't read $file: " . $! . "\n";

my $count = 1;
while (<FILE>)
{
    chomp;
    my ($line) = $_;
    my $orig = $line;
    $line =~ s/"//g;
    # replace commas in quote
    #my $fixed;
    #my $redo = 1;
    #while ($redo)
    #{
    #	$fixed  = fix_commas($line);
    #	if ($fixed eq $line)
    #	{
    #	   $redo = 0; 
    #	}
    #   $line = $fixed;
    #}
    my @cols = split /\t/, $line;
    my (@ids,$author_url,$author_id,@author_names,@titles,$perseus,@id_types);    
    my $format_tried = 'none';
    my $lang = '';
    if ($e_lang eq 'lat')
    {
        $lang = $e_lang;

        $author_url = $cols[0]
		unless !($cols[0]) || $cols[0] =~ /\bnone\b/i;
        $author_id = $cols[1]
		unless !($cols[1]) || $cols[1] =~ /\bnone\b/i;
	for (my $i=2; $i<9; $i++)
	{
	    push @author_names, $cols[$i] 
		unless !($cols[$i]) || $cols[$i] =~ /\bnone\b/i;
	}
	for (my $i=9; $i<13; $i++)
	{
	    push @titles, $cols[$i]
		unless !($cols[$i]) || $cols[$i] =~ /\bnone\b/i;
	}
	format_phi($cols[19],\@ids,\@id_types);
	format_stoa($cols[20],\@ids,\@id_types);
	if ($cols[20] =~ /^"?\s*(stoa\d+-unassigned)\s*"?$/)
	{
		push @stoa_assign, $orig;
	}
	else
	{
		#push @need_stoa, $orig;
	}
	$perseus = $cols[14] =~ /yes/i ? 1 : 0;
    }
    elsif ($e_lang eq 'grc')
    {
        $lang = $e_lang;
        $author_url = $cols[0];
        $author_id = $cols[1];
        push @author_names, $cols[2];
        push @author_names, $cols[3];
        push @author_names, $cols[4];
        push @author_names, $cols[5];
	push @titles, $cols[6];
	push @titles, $cols[7];
	push @titles, $cols[8];
	if ($cols[14] =~ /^\d+\.\d+$/)
    	{
		format_phi($cols[14],\@ids,\@id_types);
	}
	elsif ($cols[14] =~ /stoa/)
	{
		format_stoa($cols[14],\@ids,\@id_types);
	}
	else
	{
		format_tlg($cols[13],\@ids,\@id_types);
	}
	$perseus = $cols[15] =~ /yes/i ? 1 : 0;
    }
    # idmatches
    else {
        my $abo_col = 14;
        my $phi_col = 16;
        my $stoa_col = 15;
        my $tlg_col = 17;
        my $title_col = 5;
        my $author_col = 0;
        my $perseus_col = 14;
        if ( $file =~ /Anon/i)
        {
            $phi_col = 6;
            $stoa_col = 5;
            $tlg_col = 7;
            $perseus_col=4;
            $title_col = 1;
        }
        $format_tried = 'idmatches';
        push @author_names, $cols[$author_col];
        push @titles, $cols[$title_col];	
	$perseus = $cols[$perseus_col] =~ /none/i ? 0 : 1;
        # override for Nepos and Suetonius to use abo
        if ($cols[$abo_col] && ($cols[$abo_col] =~ /phi,1348/ || $cols[$abo_col] =~ /phi,0588/)) {
            $format_tried = 'abo';
	    format_abo($cols[$abo_col],\@ids,\@id_types);
            $lang = 'lat';
        } 
        # override for Seneca the Younger to use stoa over phi
        if ($cols[$stoa_col] && $cols[$stoa_col] =~ /^stoa0255-/)  {
            $format_tried = 'stoa';
	    format_stoa($cols[$stoa_col],\@ids,\@id_types);
            $lang = 'lat';
        }
        elsif ($cols[$phi_col] && $cols[$phi_col] !~ /none/ && $cols[$phi_col] !~ /no/) 
        {
            $format_tried = 'phi';
	    format_phi($cols[$phi_col],\@ids,\@id_types);
            $lang = 'lat';
        } 
        elsif ($cols[$stoa_col] && $cols[$stoa_col] !~ /none/ && $cols[$stoa_col] !~ /no/) 
        {
            $format_tried = 'stoa';
	    format_stoa($cols[$stoa_col],\@ids,\@id_types);
            $lang = 'lat';
        } 
        else
        {
            $format_tried = 'tlg';
	    format_tlg($cols[$tlg_col],\@ids,\@id_types);
            $lang = 'grc';
        } 
       
    } 
    if (scalar @ids == 0)
    {
	push @no_ids, $orig;
	print "$orig\t";
        print NOIDS join ",", ($format_tried,$cols[15],$cols[16],$cols[17]);
	if ($count == 1)
	{
		print qq!"CTS URN"!
	}
	print NOIDS "\n";
	print "\n";
        next;
    }
    my %params = (
    	"e_ids" => (join ",", @ids),
        "e_idTypes" => (join ",", @id_types),
	#"e_collection" => ($lang eq 'lat' ? 'FRBR/Latin' : 'FRBR/Greek'),
	"e_collection" => ('FRBR'),
        "e_titles" => (join ",", @titles),
        "e_authorNames" => (join ",", @author_names),
        "e_authorId" => $author_id,
        "e_authorUrl" => $author_url,
        "e_Perseus" => $perseus,
	"e_lang" => $lang,
	"e_updateDate" => "2011-04-20T00:00:00Z"
    );
    my $qs = join "&" , map { "$_=" . uri_escape($params{$_}) } keys %params;
    my $request = "$service?$qs";
    my $response = $ua->post($service,\%params);
    #warn "Calling $request\n"; 
    #my $response = $ua->get($request);
    if ($response->is_success)
    {
        my $decoded = decode_utf8($response->decoded_content);
        my $ctsurn;
        if ($decoded =~ /^<error>/)
        {
	    open ERRORS, ">>feeds/errors.xml" or die $!;
            print ERRORS "$qs\n";
            close ERRORS;
        } else {
            ($ctsurn) = $decoded =~ /<atom:id>http:\/\/data.perseus.org\/catalog\/urn:cts:(?:.*?):(.*?)\/atom/;
	    print qq!$orig\turn:cts:$ctsurn\n!;
            open XML, ">feeds/$ctsurn.xml" or die $!;
            print XML encode_utf8($decoded);
            close XML;
        }
  	
    }
    else
    {
	die "$request returned " . $response->error_as_HTML;
    }

    my $cmd = "call ant frbr-sip";
    $cmd .= " -Dfrbr.file=feed_" . $lang . "_" . ($count++) . ".xml";
    $cmd .= qq! -Dfrbr.ids="! . (join ",", @ids) . qq!"!;
    $cmd .= qq! -Dfrbr.id_types="! . (join ",", @id_types) . qq!"!;
    $cmd .= " -Dfrbr.lang=$lang";
    $cmd .= qq! -Dfrbr.collection="FRBR"!; 
    $cmd .= qq! -Dfrbr.titles="! . (join ",", @titles) . qq!"!;
    $cmd .= qq! -Dfrbr.author_names="! . (join ",", @author_names) . qq!"!;
    $cmd .= qq! -Dfrbr.author_id="$author_id"!;
    $cmd .= qq! -Dfrbr.author_url="$author_url"!;
    $cmd .= " -Dfrbr.perseus=$perseus";
#    #print $cmd . "\n";

}

sub format_abo {
    my ($abo,$ids, $id_types) = @_;
    my ($pabo,$group,$work) = $abo =~ /(Perseus:abo:phi,(\d+),(\d+))\s*$/;
    # we only do this for works of Nepos and Suetonius
    if ($group && $work && ($group eq '0588' || $group eq '1348')) {
        $group = sprintf("%04d",$group);
        $work = sprintf("%03d",$work);
        push @$id_types, 'Perseus:abo';
        push @$ids, "$group.$work"
    }
}

sub format_phi {
	my ($phi_ids,$ids, $id_types) = @_;
        my $added = 0;
	$phi_ids =~ s/^"\s*//;
	$phi_ids =~ s/\s*"$//;
	$phi_ids =~ s/\?//g;
	$phi_ids =~ s/\(//g;
	$phi_ids =~ s/\)//g;
	$phi_ids =~ s/;//g;
	my @phi_ids = split /,|\s+/, $phi_ids;
	foreach my $phi_id (@phi_ids)
	{
	    $phi_id =~ s/^\s*//;
	    $phi_id =~ s/\s*$//;
	    if ($phi_id =~ /^"?\s*(\d+\.\d+)\??\s*"?$/i)
	    {
                my ($group,$work) = split /\./, $1;

                $group = sprintf("%04d",$group);
                $work = sprintf("%03d",$work);
		push @$ids, "$group.$work";
		push @$id_types, 'phi';
                $added++;
	    }
	}
        if (! $added)
        {
            #push @no_ids, $phi_ids;
        }
        
}

sub format_stoa {
	my ($stoa_ids,$ids, $id_types) = @_;
	if ($stoa_ids =~ /^\s*(stoa[\d\w]+-stoa[\d\w]+)/)
	{
		push @$ids, $1;
		push @$id_types, 'stoa';
	}
        else 
        {
		#push @no_ids, $stoa_ids;
        }
}

sub fix_commas {
   my $a_line = shift;
   $a_line =~ s/("[^"]*?),([^",]+")/$1 $2/g;
   return $a_line;
}
for (my $i=0; $i<scalar @no_ids; $i++)
{
#	print "$no_ids[$i]\n"; 
}
for (my $i=0; $i<scalar @need_stoa; $i++)
{
#	print "$need_stoa[$i]\n"; 
}
for (my $i=0; $i<scalar @stoa_assign; $i++)
{
#	print "$stoa_assign[$i]\n"; 
}

sub format_tlg {
    my ($tlgids,$ids,$id_types) = @_;
    $tlgids =~ s/^"\s*//;
    $tlgids =~ s/\s*"$//;
    $tlgids =~ s/\?//g;
    $tlgids =~ s/\(//g;
    $tlgids =~ s/\)//g;
    $tlgids =~ s/;//g;
    my @tlgids = split /,|\s+/, $tlgids;
    foreach my $tlgid (@tlgids)
    {
	$tlgid =~ s/^\s*//;
	$tlgid =~ s/\s*$//;
	next unless $tlgid;
	# fragments may be entered as \d\d\d\dx-?\d\d
	# another author. We will catalog under the fragmentary author
	if ($tlgid =~ /^(x?\d+x-?\d+)$/i)
	{
    		push @$ids,$1;
    		push @$id_types, 'tlg_frag';
	}
	# for a range, try all of them, starting with the first
	elsif ($tlgid =~ /^(x?\d+\.\d+)-(\d+\.\d+)$/)
	{
    		my $start_tlg = $1;
    		my $end_tlg = $2;
    		push @$ids, $start_tlg;
    		push @$id_types, 'tlg';
    		my ($start_group) = $start_tlg =~ /^(x?\d+\.)\d+$/;
    		my ($end_group) = $end_tlg =~ /^(x?\d+\.)\d+$/;
    		# only add the middle of the range if its the same author group
    		if ($start_group eq $end_group)
    		{

                	my ($start) = $start_tlg =~ /^x?\d+\.(\d+)$/;
		     	my ($end) = $end_tlg =~ /^x?\d+\.(\d+)$/;
		       	while (++$start < $end)
		       	{
				push @$ids, $start;
			    	push @$id_types, 'tlg';
		       	}
	  	}
		push @$ids, $end_tlg;
		push @$id_types, 'tlg';
	}
	elsif ( $tlgid =~ /^(x?\d+\.\d+)$/ )
	{
		push @$ids,$1;
		push @$id_types,'tlg';
	}
	elsif ( $tlgid =~ /^(\d+\.\d+x\d+)$/ )
        {
		push @$ids,$1;
		push @$id_types,'tlg';
        }
	else 
	{
             #push @no_ids, $tlgid;
	}
    }	
}
