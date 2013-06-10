declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace cts="http://chs.harvard.edu/xmlns/cts3/ti";
declare namespace atom="http://www.w3.org/2005/Atom";


declare variable $e_dir as xs:string external; 

let $collection := collection($e_dir)
let $textgroups := distinct-values($collection//cts:textgroup/@urn)
let $proto_feed := ($collection/atom:feed)[1]
let $allgroups :=
    for $textgroup in $textgroups
        let $allfeeds := $collection/atom:feed[//cts:textgroup[@urn = $textgroup]]
        let $allworks := $allfeeds//cts:work
        let $all_mods := 
            for $entry in $allfeeds//atom:entry[atom:id[matches(.,concat('.*?/',$textgroup ,'\..*/atom#mods'))]]
            return 
                element atom:entry {
                    $entry/atom:id,
                    $entry/atom:link,
                    $entry/atom:author,
                    $entry/atom:title
                }
        let $distinct_mads := distinct-values($allfeeds//atom:entry[atom:id[matches(.,concat('.*?/',$textgroup ,'\..*/atom#mads.*'))]]/atom:link[@rel='alternate']/@href)
        let $all_mads :=
            for $author at $a_i in $distinct_mads return
                let $proto_mads :=
                    (: TODO  remove hack of pulling urn:cts: out of textgroup with next feed build (after 20130513):)                
                    ($allfeeds//atom:entry[atom:link[@rel='alternate' and @href = $author]])[1]
                let $proto_id := substring-before(substring-before($proto_mads/atom:id,'/atom#mads'),substring-after($textgroup,'urn:cts:'))
                return 
                    element atom:entry {
                        element atom:id { concat( $proto_id,$textgroup,'/atom-#mads',$a_i) },
                        $proto_mads/atom:link[@rel='alternate'],
                        $proto_mads/atom:author,
                        element atom:title { 
                            concat('The Perseus Catalog: MADS file for author in CTS textgroup ' , $textgroup)
                        }
                    }
        let $proto := ($collection//cts:textgroup[@urn = $textgroup])[1]
        return 
            element cts:textgroup {
                $proto/@*,
                $proto/cts:groupname,
                $allworks,
                $all_mods,
                $all_mads
            }
let $ti :=
    element cts:TextInventory {
        attribute tiversion {"3.0.rc1"},
        ($collection//cts:TextInventory)[1]/*[not(local-name(.) = 'textgroup')],
        for $group in $allgroups
        order by $group/@urn
        return $group
    }

return 
    element atom:feed {
        $proto_feed/atom:author,
        $proto_feed/atom:updated,
        $proto_feed/atom:rights,
        element atom:entry {
            element atom:id { 'TextInventory'},
            element atom:content {
                attribute type { 'text/xml' },
                $ti
            }
        }
    }