declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace cts="http://chs.harvard.edu/xmlns/cts3/ti";
declare namespace atom="http://www.w3.org/2005/Atom";


declare variable $e_dir as xs:string external; 

let $collection := collection($e_dir)
let $textgroups := distinct-values($collection//cts:textgroup/@urn)
let $allgroups :=
    for $textgroup in $textgroups
        let $allfeeds := $collection/atom:feed[//cts:textgroup[@urn = $textgroup]]
        let $allworks := $allfeeds//cts:work
        let $all_mods := 
            for $entry in $allfeeds//atom:entry[atom:id[matches(.,concat('.*?/',$textgroup ,'\..*/atom#mods'))]]
            return 
                element atom:entry {
                    $entry/atom:id,
                    $entry/atom:link
                }
        let $proto := ($collection//cts:textgroup[@urn = $textgroup])[1]
        return 
            element cts:textgroup {
                $proto/@*,
                $proto/cts:groupname,
                $allworks,
                $all_mods
            }
let $ti :=
    element cts:TextInventory {
        attribute tiversion {"3.0.rc1"},
        ($collection//cts:TextInventory)[1]/*[not(local-name(.) = 'textgroup')],
        for $group in $allgroups
        order by $group/@urn
        return $group
    }

return $ti