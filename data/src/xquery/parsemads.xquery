declare namespace mads="http://www.loc.gov/mads/";
declare namespace mads2="http://www.loc.gov/mads/v2";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace frbr = "http://perseus.org/xquery/frbr" at "frbrsips.xquery";

let $collection := collection('/db/FRBR_MADS/PrimaryAuthors')

let $rows :=
    for $madsfile in ($collection/mads:mads,$collection/mads2:mads)
        let $docpath := replace(base-uri($madsfile),'/db/FRBR_MADS/','')
        
        (: pull the author authority name :)
        let $auth_name := if ($madsfile/*:authority[*:name/*:namePart]) then frbr:format_name($madsfile/*:authority/*:name[*:namePart]) else ()
        let $rel_names :=
            for $related in $madsfile/*:related[*:name/*:namePart]
            return frbr:format_name($related/*:name)
        let $var_names := 
            for $var in $madsfile/*:variant[*:name/*:namePart]
                return frbr:format_name($var/*:name)
        let $all_names := ($auth_name,$rel_names,$var_names)
        let $best_name := 
            if ($auth_name) then $auth_name
            else if (count($var_names) > 0) then $var_names[1]
            else if (count($rel_names) > 0) then $rel_names[1]
            else ""
        let $identifiers :=
            if (count($all_names) > 0)
            then
              for $id in $madsfile/*:identifier[matches(@type,'.*(tlg|stoa|phi).*') and text() != '']
                let $id_type := if (matches($id/@type,'.*stoa')) then 'stoa'
                    else if (matches($id/@type,'.*tlg')) then 'tlg' else 'phi'
                let $id_tg := if (matches($id,'\.')) then substring-before($id,'.')
                    else if (matches($id,'-')) then substring-before($id,'-') 
                    else $id
                let $id_num := replace($id_tg,$id_type,'')
                let $id_raw := replace(replace(replace(xs:string($id_num),'^\s+',''),'\s+$',''),'&#x0a;','') 
                let $needs := xs:int(4) - string-length($id_raw) - 1
                let $padding := for $i in 0 to $needs return '0'
                return if ($id_num) then concat($id_type,(string-join($padding,'')),$id_raw) else ()
             else
                ()
        
        let $related_work_ids := 
            for $id in $madsfile/*:extension/*:identifier[matches(@type,'.*(tlg|stoa|phi).*') and text() != '']
                let $id_type :=
                    if (starts-with($id,'Perseus:abo:'))
                    then
                        substring-before(substring-after($id,'Perseus:abo:'),',')
                    else if (matches($id/@type,'.*stoa')) 
                    then 'stoa'
                    else if (matches($id/@type,'.*tlg')) 
                    then 'tlg' 
                    else 'phi'
                let $no_abo := if (starts-with($id,'Perseus:abo:')) 
                    then substring-after($id,concat('Perseus:abo:',$id_type,','))
                    else $id
                let $id_tg := if (matches($no_abo,'\.')) then substring-before($no_abo,'.')
                              else if (matches($no_abo,'-')) then substring-before($no_abo,'-') 
                              else if (matches($no_abo,',')) then substring-before($no_abo,',') 
                              else $no_abo
                let $id_num := replace($id_tg,$id_type,'')
                let $id_raw := replace(replace(replace(xs:string($id_num),'^\s+',''),'\s+$',''),'&#x0a;','') 
                let $needs := xs:int(4) - string-length($id_raw) - 1
                let $padding := for $i in 0 to $needs return '0'
                let $this_tg := concat($id_type,(string-join($padding,'')),$id_raw)
                
                let $id_wk := if (matches($no_abo,'\.')) then substring-after($no_abo,'.')
                    else if (matches($no_abo,'-')) then substring-after($no_abo,'-') 
                    else if (matches($no_abo,',')) then substring-after($no_abo,',') 
                    else ()
                let $wk_num := replace($id_wk,$id_type,'')
                let $wk_raw := replace(replace(replace(xs:string($wk_num),'^\s+',''),'\s+$',''),'&#x0a;','') 
                let $wk_needs := xs:int(3) - string-length($wk_raw) - 1
                let $wk_padding := for $i in 0 to $wk_needs return '0'
                let $related_work := if ($wk_num) then concat($this_tg,'.',$id_type,(string-join($wk_padding,'')),$wk_raw) else $this_tg
                return 
                    <related>
                        <idmatch>{for $autid in $identifiers return if ($this_tg = $autid) then $this_tg else ()}</idmatch>
                        (:it may still genuinely be an alternate id if we don't have a work identifier :)
                        <altid>{if ($wk_num) then () else $this_tg}</altid>
                        (: if we have work identifiers then we only want to include them if they don't match one of the explicitly defined author ids :)
                        <mismatch>{if ($wk_num and count($identifiers[.=$this_tg]) = 0) then $related_work else ()}
                        </mismatch>
                    </related>
        let $counts := 
            for $id in $identifiers return <id tg="{$id}">{count($related_work_ids//idmatch[.=$id])}</id>
        let $ordered_counts := for $id in $counts order by xs:int($id) return $id
        let $best_id := if ($ordered_counts[1]) then $ordered_counts[1]/@tg else ($related_work_ids//altid)[1]
        let $alt_ids := distinct-values(($ordered_counts[position() > 1]/@tg,$related_work_ids//altid))[. != $best_id and . != '']
        let $work_ids := distinct-values($related_work_ids//mismatch[. != ''])
        return 
            if (ends-with($docpath,'MADSTemplate.xml')) then () else
            <row>{concat('"',$best_name,'"|',$best_id,'|"',$docpath,'"|"',string-join($alt_ids,','),'"|"', string-join($work_ids,','),'"|published||feed_aggregator|&#x0a;')}</row>
    let $sorted_rows := for $row at $a_i in $rows order by $row return $row       
    return
        ('urn|authority_name|canonical_id|mads_file|alt_ids|related_works|urn_status|redirect_to|created_by|edited_by|&#x0a;',    
            for $row at $a_i in $sorted_rows return
                concat(concat('urn:cite:perseus:primauth.',$a_i,'.1|'),$row)
        )
    
 