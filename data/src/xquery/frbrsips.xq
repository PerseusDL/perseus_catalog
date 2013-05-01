import module namespace frbr = "http://perseus.org/xquery/frbr" at "frbrsips.xquery";
import module namespace request="http://exist-db.org/xquery/request";
declare namespace mods="http://www.loc.gov/mods/v3";

declare option exist:serialize "method=xml media-type=text/xml";

let $e_collection := request:get-parameter("e_collection", ())
let $e_ids := request:get-parameter("e_ids",())
let $e_idTypes := request:get-parameter("e_idTypes",())
let $e_lang := request:get-parameter("e_lang",(""))
let $e_authorUrl := request:get-parameter("e_authorUrl",(""))
let $e_authorId := request:get-parameter("e_authorId",(""))
let $e_authorNames := request:get-parameter("e_authorNames",(""))
let $e_titles := request:get-parameter("e_titles",(""))
let $e_perseus := xs:boolean(request:get-parameter("e_perseus",false()))
let $e_updateDate := request:get-parameter("e_updateDate",current-dateTime())
let $e_debug := request:get-parameter("e_debug",())

let $frbr := collection($e_collection)

(: try to find the mods record using the identifier :)

let $idlist := if (matches($e_ids,",")) then tokenize($e_ids,',') else ($e_ids)
let $typelist := if (matches($e_idTypes,",")) then tokenize($e_idTypes,',') else ($e_idTypes)
let $mods := frbr:find_mods($frbr,$idlist,$typelist,$e_lang)

(: return the Fedora SIP with the following data streams: CTS, MODS, MARC, PERSEUS :)
let $result :=
    if ($mods)
    then
        let $deduped := 
            for $item in $mods/expressions/mods:mods 
                let $dupes :=
                    for $url in $item/mods:location/mods:url[matches(.,'.*(perseus|google|archive\.org|openlibrary|hdl\.handle)')] return
                            (:loop through previous records with the same location url  as possible dupes:)
                            for $possible in $item/preceding::mods:mods/mods:location[mods:url = $url]
                               (:loop through the other locations in this record to see if there mismatches on any of the other locations:)
                               (: this is the first test:)
                                let $still_possible :=
                                    if ($possible/../mods:location[mods:url != $url]) 
                                    then
                                        for $purl in $possible/../mods:location[mods:url != $url]
                                            let $check := $item/mods:mods/mods:location[@displayLabel = $purl/@displayLabel]
                                            return
                                                if ($check and $check/mods:url != $purl/mods:url)
                                                (: found another location url in this same record which doesn't match the same type of location
                                                   in the original record, so it is likely not a dupe
                                                 :)
                                                then () 
                                                else $purl
                                   (: if this was the only location in the record, then just assume this is a dupe for this test:)    
                                    else $possible
                               return
                                    (:last test is on language :)
                                    for $last in $still_possible return
                                        (: can only do this if we have any languages identified :)
                                        if ($last/../mods:language[@objectPart='text' or not(@objectPart)]) 
                                        then
                                            (: loop through the languages in this record and compare them to the languages in the original :)
                                            for $lang in $still_possible/../mods:language[@objectPart='text' or not(@objectPart)]/mods:languageTerm
                                            return
                                                if ($item/mods:language[@objectPart='text' or not(@objectPart)]/mods:languageTerm[. = $lang]) 
                                                then
                                                    $still_possible 
                                                else ()
                                       (:can't dedupe on language if we don't have any so assume it is a dupe:)
                                       else $last
                return if ($dupes) then () else $item
        let $related :=
            for $item in $mods/related/mods:mods
                let $dupes :=
                    for $url in $item/mods:location/mods:url return
                        (: note deduping assumption is that if a location url is the same then it is a duplicate but
                           this might not be valid for urls which aren't at the page level and represent an edition with a facing translation 
                        :)
                        if ($item/preceding::mods:mods/mods:location[mods:url = $url])
                        then $url else () 
                return if ($dupes) then () else $item
        let $id := frbr:make_id(string($mods/id),string($mods/type))    
        return 
            (:<request><collection>{$e_collection}</collection><id>{$id}</id><mods>{$mods}</mods><related>{$related}</related><titles>{$e_titles}</titles></request>:)
            frbr:make_sip($e_collection,$e_lang,$id,$deduped,$related,$e_titles,$e_updateDate)
                        
                                          
    else 
        (: if we couldn't find a mods record for it, look for a perseus record :)
        let $perseus := frbr:find_perseus(doc('/FRBR/perseuscts.xml'),$idlist,$typelist)
        let $id := frbr:make_id(string($perseus[1]),string($perseus[2]))
        return 
            if ($perseus) then frbr:make_sip($e_collection,$e_lang,$id,(),(),$e_titles,$e_updateDate)
        else 
        <error>Not Found,
        { for $id at $a_i in $idlist
            let $ns := if ($e_lang = 'grc') then "greekLit:" else "latinLit:"
            return <urn>{concat('urn:cts:',$ns,frbr:make_id($id,$typelist[$a_i]))}</urn>
        }
        </error>
        
return 
  if ($e_debug) 
  then <all><mods>{$mods}</mods><sips>{$result}</sips></all> 
  else $result 