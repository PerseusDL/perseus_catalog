#!/usr/bin/perl
use strict;
use Data::Dumper;

my $DATE = $ARGV[0];
my $idmatches = "feeds.idmatches.$DATE";
my $anon = "feeds.anon.$DATE";
my $greek = "feeds.greek.$DATE";
my $latin = "feeds.latin.$DATE";
my $all = "feeds.all.$DATE";

my %old_files;
my %new_files;
opendir(my $dh, $greek) || die "$! $greek\n";
map { $_ =~ s/\.xml$//; $old_files{$_} = 1 }
grep { /^(.*?)\.xml$/ } readdir($dh);
closedir $dh;
opendir(my $dh, $latin) || die "$! $latin\n";
map { $_ =~ s/\.xml$//; $old_files{$_} = 1 }
grep { /^(.*?)\.xml$/ } readdir($dh);
closedir $dh;
opendir(my $dh, $idmatches) || die "$! $idmatches\n";
map { $_ =~ s/\.xml$//; $new_files{$_} = 1 }
grep { /^(.*?).xml$/ } readdir($dh);
closedir $dh;
opendir(my $dh, $anon) || die "$! $anon\n";
map { $_ =~ s/\.xml$//; $new_files{$_} = 1 }
grep { /^(.*?).xml$/ } readdir($dh);
closedir $dh;

print "IDMATCHES ONLY\n";
my $count = 0;
my %both; 
foreach my $file (sort keys %new_files)
{
    unless (exists $old_files{$file}) 
    { 
        print "$file\n";
        if (-e "$idmatches/$file.xml")
        {
            `cp $idmatches/$file.xml $all`;
        }
        else
        {
            `cp $anon/$file.xml $all`;
        }
        $count++;
    }
    else 
    {
        $both{$file} = 1;
    }
}
print "UNIQUE TO IDMATCHES: $count\n";
$count = 0;
print "\nABBR ONLY\n";
foreach my $file (sort keys %old_files)
{
    unless (exists $new_files{$file}) 
    { 
        print "$file\n";
        if ($file =~ /tlg/)
        {
        	`cp $greek/$file.xml $all`;
        }
        else
        {
        	`cp $latin/$file.xml $all`;
        }
        $count++;
    }
    else 
    {
        $both{$file} = 1;
    }
}
print "UNIQUE TO ABBR: $count\n";
$count = 0;
print "BOTH:\n";
foreach my $file (sort keys %both)
{
        print "$file\n";
        if (-e "$idmatches/$file.xml")
        {
            `cp $idmatches/$file.xml $all`;
        }
        else
        {
            `cp $anon/$file.xml $all`;
        }
        $count++;
}
print "FOUND IN BOTH: $count\n";
`cp $idmatches/errors.xml $all/errors.idmatches.csv`;
`cp $anon/errors.xml $all/errors.anon.csv`;
`cp $latin/errors.xml $all/errors.aae-latin.csv`;
`cp $greek/errors.xml $all/errors.aae-greek.csv`;
`cp $greek/noids.out $all/errors-noids.aae-greek.csv`;
`cp $latin/noids.out $all/errors-noids.aae-latin.csv`;
`cp $anon/noids.out $all/errors-noids.anon.csv`;
`cp $idmatches/noids.out $all/errors-noids.idmatches.csv`;
`rm $all/errors.xml`;
`rm $all/noids.out`;
