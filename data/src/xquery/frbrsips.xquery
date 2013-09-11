(: Copyright 2013 The Perseus Project, Tufts University, Medford MA
This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
See http://www.gnu.org/licenses/. 
:)


module namespace frbr = "http://perseus.org/xquery/frbr";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace cts="http://chs.harvard.edu/xmlns/cts/ti";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace xsi ="http://www.w3.org/2001/XMLSchema-instance";
declare namespace saxon="http://saxon.sf.net/";
declare namespace existtx="http://exist-db.org/xquery/transform";
declare namespace mads="http://www.loc.gov/mads/";
declare namespace cite="http://shot.holycross.edu/xmlns/cite";


declare variable $e_collection as xs:string external;
declare variable $e_ids as xs:string external;
declare variable $e_idTypes as xs:string external;
declare variable $e_lang as xs:string external;
declare variable $e_authorUrl as xs:string external;
declare variable $e_authorId as xs:string external;
declare variable $e_authorNames as xs:string external;
declare variable $e_titles as xs:string* external;
declare variable $e_perseus as xs:string external;
declare variable $e_updateDate as xs:string external;

declare variable $frbr:e_pidBase := 'http://data.perseus.org/catalog/';
declare variable $frbr:e_catalogBase := 'http://catalog.perseus.org/catalog/';
declare variable $frbr:e_collectionsBase := 'http://data.perseus.org/collections/';


declare function frbr:make_sip($a_collection as xs:string, $a_lang as xs:string,$a_id as xs:string, $a_mods as node()*,$a_related as node()*,$a_titles as xs:string,$a_updateDate) as node()
{        
        let $ns := if ($a_lang = 'grc') then "greekLit" else "latinLit"
        let $ctsplus := frbr:make_cts($a_lang,$a_id,$a_mods,$ns,$a_titles)
        let $mads := frbr:find_mads($a_id,$ctsplus)
        return
        element atom:feed {
           element atom:id { concat($frbr:e_pidBase,'urn:cts:',$ns,':',$a_id,'/atom') },
           element atom:author { 'Perseus Digital Library' },
           element atom:rights { 'This data is licensed under a Creative Commons Attribution-ShareAlike 3.0 United States License' },
           element atom:title { concat('The Perseus Catalog: atom feed for CTS work urn:cts:',$ns,':',$a_id) },
           element atom:link {
            attribute type { 'application/atom+xml'},
            attribute rel { 'self' },
            attribute href { concat($frbr:e_pidBase,'urn:cts:',$ns,':',$a_id,'/atom')}
           },
           element atom:link {
             attribute type {'text/html'},
             attribute rel {'alternate'},
             attribute href {concat($frbr:e_catalogBase,'urn:cts:',$ns,':',$a_id)}
           },
            element atom:updated {$a_updateDate},
            element atom:entry {
                element atom:id { concat($frbr:e_pidBase,'urn:cts:',$ns,':',$a_id,'/atom#ctsti') },
                element atom:author { 'Perseus Digital Library' },
                element atom:link {
                    attribute type { 'application/atom+xml'},
                    attribute rel { 'self' },
                    attribute href { concat($frbr:e_pidBase,'urn:cts:',$ns,':',$a_id,'/atom#ctsti')}
                },
                element atom:link {
                    attribute type {'text/html'},
                    attribute rel {'alternate'},
                    attribute href {concat($frbr:e_catalogBase,'urn:cts:',$ns,':',$a_id)}
                },
                element atom:title { concat('The Perseus Catalog: Text Inventory for CTS work urn:cts:',$ns,':',$a_id) },                
                (: add external data streams for the XML content unless under copyright :)
                (: TODO PUT THIS BACK IN WHEN WE ARE READY TO PUBLISH TEXT LINKS?? WHAT IS THE FINAL LOCATION ?? :)
                (:
                for $online at $a_i in 
                	$ctsplus//cts:*[cts:memberof[not(contains(@collection,'-protected'))]]/cts:online return                    
                    let $docname := $online/@docname
                    let $projid := if (matches($online/parent::*/@projid,':')) then 
                        substring-after($online/parent::*/@projid,':') else $online/parent::*/@projid 
                    let $id := 
                        concat('urn:cts:',$ns,':',$a_id,'.',$projid)
                    let $url := concat('http://www.perseus.tufts.edu/hopper/opensource/downloads/texts/tei/',$docname[1])
                    return 
                        element atom:link {
                            attribute id { concat('TEI.',$docname[1]) }, 
                            attribute href { $url },
                            attribute type { 'text/xml' },
                            attribute rel { 'self' }
                        },
                  :)
                    element atom:content{
        				attribute type { "text/xml" },                           
        				frbr:exclude-mods($ctsplus)
        			} (: end CTS content element :)
        			(:if ($ctsplus//refindex) then
        				element atom:content{
        			     	attribute type { "text/xml" },
        				    $ctsplus//refindex                                              
        				} (: end content element :)
        			else ()
        	     :)
            }, (: end entry element :)
            for $edition at $a_i in $ctsplus//mods:mods[mods:identifier[@type="ctsurn"]] return
                (: we should only possibly have dupes for Perseus MODS files in which case just use the first found :)
                if ( ($ctsplus//mods:mods)[position() < $a_i and mods:identifier[@type="ctsurn"] = $edition/mods:identifier[@type='ctsurn']]) then ()
                else 
                    element atom:entry {
                        element atom:id { concat($frbr:e_pidBase,$edition/mods:identifier[@type="ctsurn"][1],'/atom#mods') },
                        element atom:author { 'Perseus Digital Library' },
                        element atom:title { concat('The Perseus Catalog: MODS file for CTS version ', $edition/mods:identifier[@type='ctsurn'][1]) },
                        element atom:link {
                            attribute type { 'application/atom+xml'},
                            attribute rel { 'self' },
                            attribute href { concat($frbr:e_pidBase,$edition/mods:identifier[@type="ctsurn"][1],'/atom#mods')}
                        },
                        element atom:link {
                            attribute type { 'text/html'},
                            attribute rel { 'alternate' },
                            attribute href { concat($frbr:e_catalogBase,$edition/mods:identifier[@type="ctsurn"][1])}
                        },
                	    element atom:content{
                                attribute type { "text/xml" },
                                $edition                                             
                    	} (: end MODS content element :)
                    }, (: end entry element :)
              for $related at $a_i in $a_related return
                element atom:entry {
                    element atom:id { concat($frbr:e_pidBase, 'urn:cts:',$ns, ':',$a_id, '/atom#mods-relateditem-',$a_i)},
                    element atom:author { 'Perseus Digital Library' },
                    element atom:title { concat('The Perseus Catalog: MODS file for text related to CTS work urn:cts:', $ns, ':',$a_id) },
                    element atom:link {
                        attribute type { 'application/atom+xml'},
                        attribute rel { 'self' },
                        attribute href { concat($frbr:e_pidBase, $ns, ':',$a_id, '/atom#mods-relateditem-',$a_i) }
                    },
            	    element atom:content{
                            attribute type { "text/xml" },
                            element mods:mods {
                                attribute xsi:schemaLocation { "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd" },
                                for $node in $related/*
                                return
                                    if ( node-name($node) = QName("http://www.loc.gov/mods/v3","identifier")) 
                                    then frbr:normalize_display_label($node)
                                    else $node
                            }
                	} (: end MODS content element :)
                }, (: end entry element :)
               for $mads at $a_i in $mads/match return
                  element atom:entry {
                    element atom:id { concat($frbr:e_pidBase, 'urn:cts:',$ns, ':',$a_id, '/atom#mads-',$a_i)},
                    element atom:author { 'Perseus Digital Library' },
                    element atom:title { concat('The Perseus Catalog: MADS file for author of CTS work urn:cts:', $ns, ':',$a_id) },
                    element atom:link {
                        attribute type { 'application/atom+xml'},
                        attribute rel { 'self' },
                        attribute href { concat($frbr:e_pidBase, $ns, ':',$a_id, '/atom#mads-',$a_i) }
                    },
                    element atom:link {
                        attribute type { 'text/xml'},
                        attribute rel { 'alternate' },
                        attribute href { concat($frbr:e_collectionsBase,$mads/@urn) }
                    },
            	    element atom:content{
                            attribute type { "text/xml" },
                            $mads/*
                  } (: end MADS content element :)
                } (: end entry element :)
        }     (: end feed element :)        
};

declare function frbr:exclude-mods($a_nodes as node()*) as node()*
{
    for $node in $a_nodes return 
        if (node-name($node) = QName("http://www.loc.gov/mods/v3","mods") or 
            node-name($node) = QName("","refindex"))            
        then ()
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*[not(local-name(.) = 'projid')],
                frbr:exclude-mods($node/node())
            }
        else 
            $node              
};

declare function frbr:make_id($a_id as xs:string, $a_type as xs:string) as xs:string {
    if ($a_type = 'tlg' or $a_type = 'phi')
    then 
        let $parts := tokenize($a_id,"\.")
        let $combined := for $part in $parts return concat($a_type,$part)
        return string-join($combined,".")
    else
    if ($a_type = 'tlg_frag') then
        let $temp := 
            if (matches($a_id,'x?-','i')) then replace($a_id,'-','.')
            else if (matches($a_id,'x','i')) then replace($a_id,'x','.X','i')
            else $a_id
        let $parts := tokenize($temp,"\.")
        let $combined := for $part in $parts return concat('tlg',$part)
        return string-join($combined,".")
    else 
    if ($a_type = 'stoa')
    then    
           replace($a_id,"-",".")
    else
    if ($a_type = 'abo')
    then 
        (: See bug 1159 :)
        let $parts := tokenize($a_id,"\.")
        return concat('phi',$parts[1],'.','abo',$parts[2])
    else 
        $a_id    
};

declare function frbr:make_groupname($a_mods as node()*) {
    let $names := 
        for $creator in ($a_mods/mods:name[mods:role/mods:roleTerm='creator']) 
        return
            frbr:format_name($creator)
    return 
        $names
};


declare function frbr:make_cts($a_lang as xs:string,$a_id as xs:string,$a_mods as node()*,$a_ns as xs:string,$a_titles as xs:string) as node()
{        
    let $perseusInv := doc('/FRBR/perseuscts.xml')
    let $wordCounts := doc('/FRBR/wordcounts.xml')
    let $textgroup_id := concat($a_ns,":",substring-before($a_id,"."))
    let $work_id := concat($a_ns,":",substring-after($a_id,"."))
    let $perseusExpressions := $perseusInv//cts:textgroup[@projid=$textgroup_id]/cts:work[@projid=$work_id]/*[local-name(.) = 'edition' or local-name(.) = 'translation']
    let $groupname :=
     if ($perseusExpressions) 
                then $perseusExpressions[1]/ancestor::cts:textgroup/cts:groupname/text() 
                else frbr:make_groupname($a_mods)[1]       
    let $work_title := 	
        if ($perseusExpressions)
        then $perseusExpressions[1]/ancestor::cts:work/*:title/text()
        else $a_titles[1]
    return element cts:TextInventory {
        $perseusInv//cts:TextInventory/@*,
        $perseusInv//cts:TextInventory/node()[not(local-name() = 'textgroup')],
        element cts:textgroup {
            (:attribute projid {
                $textgroup_id
            },:)
            attribute urn {
                concat('urn:cts:',$textgroup_id)
            },
            element cts:groupname {
                attribute xml:lang { "eng"},
                $groupname  
            },            
            element cts:work {
                (:attribute projid {
                    $work_id
                },:)              
                attribute urn {
                    concat('urn:cts:',$a_ns,':',$a_id)
                },
                attribute xml:lang { $a_lang},
                element cts:title {
					attribute xml:lang { "eng"},
                	$work_title
                },
                (: add any perseus entries we have, inserting the cts urn :)
                (for $expression in $perseusExpressions
                    return 
                        if ($expression/@urn) then $expression 
                        else 
                            let $vtype := name($expression)
                            return 
                                element {$vtype} {
                                    attribute urn {
                                        concat('urn:cts:', $a_ns,':',$a_id,'.',substring-after($expression/@projid,':'))
                                    },
                                    $expression/@*[not(local-name(.) = 'projid')],
                                    $expression/*
                                }
                ),
                
                    let $opplangs := distinct-values(($a_lang,$a_mods//mods:mods/mods:language[@objectPart = 'text' or not(@objectPart)]/mods:languageTerm))
                    let $all_opp := 
                        for $thislang in $opplangs
                            for $mods at $a_i in $a_mods
                                return
                                    if ($mods//mods:mods/mods:language[@objectPart = 'text' or not(@objectPart)]/mods:languageTerm = $thislang)
                                    then frbr:make_opp_version($a_id,$a_ns,$perseusExpressions,$a_lang,$work_title,$mods,$a_i)
                                    else ()
                    return
                        (for $mods in $all_opp[@modsonly]
                        return $mods/*,
                        for $thislang in $opplangs 
                            for $mods at $a_i in $all_opp[*[contains(@urn,concat('opp-',$thislang))]]
                                let $renumbered :=
                                    existtx:transform($mods,doc('/db/xslt/fixoppver.xsl'),
                                        <parameters>
                                            <param name="e_base" value="{concat('urn:cts:',$a_ns,':',$a_id)}"/>
                                            <param name="e_lang" value="{$thislang}"/>
                                            <param name="e_ns" value="{$a_ns}"/>
                                            <param name="e_newVer" value="{$a_i}"/>
                                        </parameters>)
                               return $renumbered/*
                   )
                
            } (:end work:)        
        } (:end textgroup:)
    } (: end TextInventory:)
};

declare function frbr:make_opp_version($a_id,$a_ns,$a_perseusExpressions,$a_lang,$a_title,$a_mods,$a_i)
{
    let $wordCounts := doc('/FRBR/wordcounts.xml')
    let $lang := ($a_mods/mods:language[@objectPart = 'text' or not(@objectPart)]/mods:languageTerm)[1]
    let $persLoc := $a_mods/mods:location/mods:url[starts-with(text(),"http://www.perseus.tufts.edu/hopper")]
    let $xId := concat($a_ns,':opp-',(if ($lang) then $lang else $a_lang),$a_i)
    let $projid :=
        if ($persLoc) then 
            let $persDoc := 
                (: handle subdocs :)
                let $full := substring-after($persLoc[1],"?doc=Perseus:text:")
                return if (contains($full,':')) then substring-before($full,':') else $full
            let $perseusId := 
                $a_perseusExpressions//cts:online[@docname = concat($persDoc,".xml")][1]/parent::*/@projid
            return if ($perseusId) then string($perseusId) else $xId                                 
        (: no perseus url id mods :)
        else $xId
    let $urn := concat('urn:cts:', $a_ns,':',$a_id,'.',substring-after($projid,':'))
    let $type :=
    if ($a_mods/mods:name[mods:role/mods:roleTerm = 'translator'] or 
        $a_mods/mods:subject[@authority='lcsh' and matches(mods:topic, "translation","i")] or
        $lang != $a_lang ) then "translation" else "edition"                                    
    return 
        element temp {
            (: only add new editions if we didn't have a perseus edition :)
            (if (not(contains($projid,$xId)))
            then
                attribute modsonly { 1 } 
            else
                let $titles := frbr:version_title($a_mods/mods:titleInfo)
                let $hosttitles := frbr:version_title($a_mods/mods:relatedItem[@type='host']/mods:titleInfo)
                let $langs := ($titles/@*:lang,$hosttitles/@*:lang)
                let $title_langs := if (count($langs) > 1) then distinct-values($langs) else $langs
            
                return element  {concat ('cts:',$type) } {
                    if ($type = 'edition') 
                    then () 
                    else attribute xml:lang { if ($lang) then $lang else $a_lang },
                    (:attribute projid { $projid },:)
                    attribute urn { $urn },
                    element cts:label {
                       (: if we have no or multiple languages just say eng :)
                        attribute xml:lang { if (count($title_langs) > 1 or count($title_langs) = 0) then 'eng' else $title_langs[1]},
                        if (count($titles) > 0 or count($hosttitles) > 0) then string-join(($titles/*, $hosttitles/*),', ')
                        else $a_title
                    },                                                                                                      
                    element cts:description{
                        attribute xml:lang { "eng" },
                        string-join(
                            for $name in $a_mods/mods:name return 
                            string-join(($name/mods:namePart,$name/mods:role),",")
                            ," ")
                    }                                               
                } (:end edition/translation:)
            ),                       
            let $uniformTitle := $a_mods/mods:titleInfo[mods:title = $a_title][1]
            let $wordCount := $wordCounts//count[@work=$a_id]
            return                                                    
                (: plugin the mods record, adding a cts identifier and word count if we have it:)                                             
                element mods:mods {
                    attribute xsi:schemaLocation { "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd" },
                    (: add the uniform title from the spreadsheet :)
                    if ($uniformTitle) then 
                        element mods:titleInfo {
                            $uniformTitle/@*[not(local-name(.) = 'type')],
                            if ($uniformTitle/@*[local-name(.) = 'lang']) then ()
                            else attribute xml:lang { 'en' },
                            attribute type { 'uniform' },
                            $uniformTitle/mods:title
                        }
                    else                                 
    	               element mods:titleInfo {
    	                   attribute xml:lang { 'en' },
    	                   attribute type { 'uniform' },
    	                   element mods:title { $a_title }
    	               },
    	            (: add the wordcount if we have it :)
    	            if ($wordCount) then 
                        element mods:part {
    	                   element mods:extent {
    	                       attribute unit { 'words' },
    	                       element mods:total { xs:int($wordCount) }
    	                   }
    	                }
    	            else (), (: no wordcount :)
    	            (: include other titleInfo :)
    	            for $node in $a_mods/mods:titleInfo[not(@type='uniform') and not(mods:title = $a_title)] return
    	               $node,
    	            (: cleanup identifiers:)
    	            for $node in $a_mods/mods:identifier[not(@type='ctsurn') and not(@type='cts-urn')] return
    	               frbr:normalize_display_label($node),
                     element mods:identifier {
                        attribute type {"ctsurn"},
                        concat("urn:cts:",$a_ns,":",$a_id,".",substring-after($projid,":"))                                                   
                     },
                    for $node in $a_mods/*[not(local-name(.) = 'titleInfo') and not(local-name(.) = 'identifier')]
                    return
                        $node
                } (: end mods :)
                              
        } (: end temp wrapping element :)
};

declare function frbr:normalize_display_label($a_node as node()) as node() {
    let $origLabel := $a_node/@displayLabel
    let $newLabel := 
        if (matches($origLabel,'^(is)?commm?entaryon$','i'))
        then 'isCommentaryOn'
        else if (matches($origLabel,'^(is)?scholiato$','i'))
        then 'isScholiaTo' 
        else if (matches($origLabel,'^(is)?summaryof$','i'))
        then 'isSummaryOf' 
        else if (matches($origLabel,'^(is)?indexof$','i'))
        then 'isIndexOf'
        else if (matches($origLabel,'^(is)?epitomeof$','i'))
        then 'isEpitomeOf'
        else if (matches($origLabel,'^(is)?introductionto$','i'))
        then 'isIntroductionTo' 
        else if (matches($origLabel,'^(is)?paraphraseof$','i'))
        then 'isParaphraseOf'
        else if (matches($origLabel,'^(is)?quotedby$','i'))
        then 'isQuotedBy'
        else if (matches($origLabel, '^(is)?translationof\??$','i'))
        then 'isTranslationOf'
        else if (matches($origLabel,'^(is)?adaptationof','i'))
        then 'isAdaptationOf' 
        else if (matches($origLabel,'attributed','i'))
        then 'isAttributedTo'
        else $origLabel
    let $origText := $a_node/text()

return 
        element mods:identifier {
            if ($newLabel) then 
                attribute displayLabel {$newLabel}
            else (),
            $a_node/@*[not(local-name(.) = 'displayLabel')],
            $a_node/text()
        }    
};

declare function frbr:find_perseus($a_inv as node(), $a_ids as xs:string*,$a_types as xs:string*) as node()*
{        
    
    let $a_id :=  $a_ids[1]
    let $a_type := $a_types[1]
    let $ns := if (matches($a_type,'tlg')) then "greekLit" else "latinLit"    
    return
        (: if we don't have both an id and a type, just return :)
        if (not ($a_id) or not($a_type))
        then         
            ()       
        else
            let $textgroup_id := concat($ns,":", $a_type, substring-before($a_id,"."))
            let $work_id := concat($ns,":",$a_type, substring-after($a_id,"."))
            (: find any Perseus with this id as an identifier :)
            let $perseus := $a_inv//cts:textgroup[@projid=$textgroup_id]/cts:work[@projid=$work_id]/*
            return                
                if ($perseus)
                then
                    (<id>{$a_id}</id>,<type>{$a_type}</type>,())
                (: recurse for remaining ids if nothing found :)    
                else
                    frbr:find_perseus($a_inv,$a_ids[position() > 1], $a_types[position() > 1])
};

declare function frbr:find_mods($a_coll as node()*,$a_ids as xs:string*, $a_types as xs:string*,$a_lang as xs:string) 
{
    let $a_id :=  $a_ids[1]
    let $a_type := $a_types[1]
    let $check_type := if ($a_type = 'tlg_frag') then 'tlg' else $a_type
    let $alt_id := if (contains($a_id,'x')) then upper-case($a_id) else if (contains($a_id,'X')) then lower-case($a_id) else $a_id
    (: alternate version of id without leading 0 :)
    let $strip1 := replace($a_ids[1],"^0+","")
    let $stripped := if ($check_type = 'abo') then concat('Perseus:',$check_type,":phi,",replace($a_id,"\.",",")) else replace($strip1,"^([^\.]+\.)0+","$1")
    
    (: match on secondary sources :)
    let $secondSrcMatch := '^(is)?((commm?entaryon)|(scholiato)|(summaryof)|(indexof)|(epitomeof)|(introductionto)|(paraphraseof)|(quotedby)|(lexiconto)|(grammarto))$'
    return
        (: if we don't have both an id and a type, just return :)
        if (not ($a_id) or not($a_type))
        then         
            ()       
        else
            (: find any mods records with this id as an identifier, and/or any consitituent records with this id as identifier :)        
            let $mods := $a_coll//mods:mods[mods:identifier[(not(@displayLabel) or not(matches(@displayLabel,$secondSrcMatch,'i'))) 
                            and contains(@type,$check_type) and (text() = $a_id or text() = $stripped or text() = $alt_id)]]                 
            let $constituent := $a_coll//mods:mods/descendant::mods:relatedItem[@type='constituent' and 
					                    mods:identifier[(not(@displayLabel) or not(matches(@displayLabel,$secondSrcMatch,'i'))) and
					                                    contains(@type,$check_type) and (text()= $a_id or text() = $stripped or text() = $alt_id)]]		
            let $related := $a_coll//mods:mods/descendant::mods:relatedItem[@type='constituent' and 
					                    mods:identifier[matches(@displayLabel,$secondSrcMatch,'i') and
					                                    contains(@type,$check_type) and (text() = $a_id or text() = $stripped or text() = $alt_id)]]		
            let $newmods :=       
                for $item in $constituent return
                    (: make a mods record from the consituent item :)
	               <mods 
	                   xmlns="http://www.loc.gov/mods/v3" 
	                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	                   xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
	                   {($item/*, frbr:reverse_related($item))}
	               </mods>
	         let $newrel :=       
                for $item in $related return
                    (: make a mods record from the related item :)
	               <mods 
	                   xmlns="http://www.loc.gov/mods/v3" 
	                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	                   xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
	                   {$item/*}                    	 	    
	                   <relatedItem type="host" xmlns="http://www.loc.gov/mods/v3">
	                       {$item/parent::mods:mods/*[local-name(.) != 'relatedItem']}
	                   </relatedItem>
	               </mods>
	       return
	           if ($mods or $newmods)
	           then 
	               let $all_mods := 
	                   for $item in ($mods,$newmods)
	                       (: gather the languages for the text in this MODS record ... sometimes we have @objectPart specified and sometimes not:)
	                       let $languages := distinct-values($item/mods:language[@objectPart = 'text' or not(@objectPart)]/mods:languageTerm) 
	                       return
	                           (:split mods files that combine facing translations in a single record :)
	                           (: but exclude the Perseus ones which are already split :)
	                           if (count($languages) > 0 and count($item/mods:identifier[matches(.,'^Perseus:text:.*')]) != 1)
	                           then
	                               for $lang in $languages return
	                                     <mods 
	                                       xmlns="http://www.loc.gov/mods/v3" 
	                                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	                                       xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
	                                       {
	                                           $item/*[not(local-name(.) = 'language') and not(local-name(.) = 'name') and not(local-name(.) = 'subject')],
	                                           $item/mods:language[mods:languageTerm[text() = $lang]],
	                                           (: eliminate translator role, translation subject for source language only :)
	                                           (for $name in $item/mods:name return
	                                               if ($name/mods:role/mods:roleTerm = 'translator' and $lang = $a_lang) then
	                                                   <mods:name>{
	                                                       $name/@*,
	                                                       $name/mods:role[mods:roleTerm != 'translator']
	                                                   }</mods:name> 
	                                               else $name
	                                           ), 
	                                           (for $subject in $item/mods:subject return
	                                               if ($subject/@authority='lcsh' and matches($subject/mods:topic,"translation","i") and $lang = $a_lang) then () else $subject)
	                                        }
	                                     </mods>
	                          else 
	                               $item
	               return <found><id>{$a_id}</id>,<type>{$a_type}</type>,<expressions>{$all_mods}</expressions><related>{$newrel}</related></found>
			   else (: recurse for remaining ids if nothing found :)
                    frbr:find_mods($a_coll,$a_ids[position() > 1], $a_types[position() > 1],$a_lang)
};

declare function frbr:reverse_related($a_node as node()) as node() {
        if ( $a_node/parent::mods:relatedItem )
        then 
        <relatedItem type="host" xmlns="http://www.loc.gov/mods/v3">
                {(
                    $a_node/parent::mods:relatedItem/@*[local-name(.) != 'type'],
                    $a_node/parent::mods:relatedItem/*[local-name(.) != 'relatedItem'],
                    frbr:reverse_related($a_node/parent::mods:relatedItem)
                )}
	       </relatedItem>
        else 
           <relatedItem type="host" xmlns="http://www.loc.gov/mods/v3">
                {$a_node/parent::mods:mods/*[local-name(.) != 'relatedItem']}
	       </relatedItem>
};

declare function frbr:format_name($a_person as node()*) as xs:string {
    (:  if we have a namePart without a type and another namePart other than 'given', 
         then concatonate them
     :) 
     if ($a_person) then
        let $parts :=
           if ($a_person/*:namePart[not(@type) or @type != 'given'])
               then $a_person/*:namePart[not(@type) or @type != 'given']
               (: only use given if we don't have other nameParts:)
               else
                   $a_person/*:namePart
        let $cleaned := for $part in $parts
           let $chopped := replace($part,'[\.|\?]$','')
           let $stripped := replace(replace($chopped,'^\s+',''),'\s+$','')
           return replace(replace($stripped,'<200f>',''),'&#x0a;','')
           
         return string-join($cleaned,' ')
      else ""
};

declare function frbr:find_mads($a_id as xs:string,$a_mods as node()*) as node()* {
    (: format the groupname using same rules we used to catalog the MADS files :)
    (: but only look at names for the primary sources -- i.e the editions not translations :)
    let $version_mods :=
        for $version in $a_mods//cts:edition return $a_mods//mods:mods[mods:identifier[@type='ctsurn' and text() = $version/@urn]]
    let $name_lookups := frbr:make_groupname($version_mods)            
    let $alt_ids := for $id in $a_mods//mods:mods/mods:identifier[matches(@type,'.*(phi)|(tlg)|(stoa)') and text() != '']
        let $id_type := 
         if (matches($id/@type,'.*stoa')) then 'stoa'
             else if (matches($id/@type,'.*tlg')) then 'tlg' else 'phi'
        let $id_tg := if (matches($id,'\.')) then substring-before($id,'.')
            else if (matches($id,'-')) then substring-before($id,'-') 
            else $id
        let $id_num := replace($id_tg,$id_type,'')
        let $id_raw := replace(replace(replace(xs:string($id_num),'^\s+',''),'\s+$',''),'&#x0a;','') 
        let $needs := xs:int(4) - string-length($id_raw) - 1
        let $padding := for $i in 0 to $needs return '0'
        return concat($id_type,(string-join($padding,'')),$id_raw)
    (: first lookup records where textgroup id matches the author's canonical id:)
    let $csUri := 'http://sosol.perseus.tufts.edu/testcoll/list?coll=urn%3Acite%3Aperseus%3Aprimauth'
    let $idMatches := httpclient:get(xs:anyURI(concat($csUri,'&amp;prop=canonical_id&amp;canonical_id=',substring-before($a_id,'.'))),false(),())
    (: if we couldn't match on the canonical id then try the alternate ids :)
    let $altIdMatches := if ($idMatches//cite:citeObject) then () else  
        for $id in $alt_ids
            return httpclient:get(xs:anyURI(concat($csUri,'&amp;prop=alt_ids&amp;alt_ids=',concat($id,':CONTAINS'))),false(),())
            (: lookup phi for stoa and vice versa :)
            (:if ( (starts-with($id,'phi') and starts-with($a_id,'stoa')) or 
                 (starts-with($id,'stoa') and starts-with($a_id,'phi'))
                )
            :)
    let $wkIdMatches := httpclient:get(xs:anyURI(concat($csUri,'&amp;prop=related_works&amp;related_works=',concat($a_id,':CONTAINS'))),false(),())
    (: add matches on the author names :)
    let $nameMatches :=
        for $name in $name_lookups 
        return httpclient:get(xs:anyURI(concat($csUri,'&amp;prop=authority_name&amp;authority_name=',encode-for-uri($name))),false(),())
    let $all_matches := ($idMatches//cite:citeObject,$altIdMatches//cite:citeObject,$nameMatches//cite:citeObject,$wkIdMatches//cite:citeObject)        
    let $authors := distinct-values($all_matches/@urn) 
    return 
        <matches>
            <altids>{$alt_ids}</altids>
            <names>{$name_lookups}</names>
            {
                for $match in $authors
                    let $mads_file := ($all_matches[@urn=$match])[1]/cite:citeProperty[@name='mads_file']
                    let $urn_no_ver := replace($match,'^(urn:cite:perseus:primauth\.\d+)\.\d+$','$1')
                    return <match urn="{$urn_no_ver}">{doc(concat('/db/FRBR_MADS/',$mads_file))}</match>
             }
        </matches>
};

declare function frbr:version_title($a_titles as node()*) as node()* {
    (: take unqualified titles above others :)
    if ($a_titles[not(@type)])
    then 
        $a_titles[not(@type)]
    (: try alternative :)
    else if ($a_titles[@type='alternative']) 
    then 
        $a_titles[@type = 'alternative']
    (: then abbreviated :)
    else if ($a_titles[@type='abbreviated'])
    then 
        $a_titles[@type = 'abbreviated'] 
    else if ($a_titles[@type='translated'])
    then 
        $a_titles[@type='translated']
    (: use uniform title as last resort because it's also used as the title of the work itself :)
    else 
        $a_titles[@type = 'uniform']
                        
};