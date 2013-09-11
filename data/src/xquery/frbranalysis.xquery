(: Copyright 2013 The Perseus Project, Tufts University, Medford MA
This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
See http://www.gnu.org/licenses/. 
:)

declare namespace frbral = "http://perseus.org/xquery/frbr-analysis";
declare namespace cts="http://chs.harvard.edu/xmlns/cts3/ti";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace atom="http://www.w3.org/2005/Atom";

(: Module designed to answer the following questions from the FRBR Catalog data 
a) How many works exist in our universe?
b) Do we have any idea how many words each work should contain?
c) For what percentage of these works do we have 1 TEI XML transcription? 2 transcriptions? 3 transcriptions?
d) For what percentage of these works do we 1 image book edition? 2 image book editions?
:)

declare variable $frbral:e_feeddir as xs:string external;
declare variable $frbral:e_ns as xs:string external;

declare function frbral:get_work_count($a_coll) {
    count($a_coll/cts:textgroup/cts:work)
};

declare function frbral:get_xml_counts($a_coll) {
    let $edition_w_one := count($a_coll/cts:textgroup/cts:work[count(cts:edition/cts:online) = 1])
    let $edition_w_two := count($a_coll/cts:textgroup/cts:work[count(cts:edition/cts:online) = 2])
    let $edition_w_three := count($a_coll/cts:textgroup/cts:work[count(cts:edition/cts:online) = 3])
    let $trans_w_one := count($a_coll/cts:textgroup/cts:work[count(cts:translation/cts:online) = 1])
    let $trans_w_two := count($a_coll/cts:textgroup/cts:work[count(cts:translation/cts:online) = 2])
    let $trans_w_three := count($a_coll/cts:textgroup/cts:work[count(cts:translation/cts:online) = 3])
    return 
        <teixml>
            <version count="1">{$edition_w_one}</version>
            <version count="2">{$edition_w_two}</version>
            <version count="3">{$edition_w_three}</version>
            <translation count="1">{$trans_w_one}</translation>
            <translation count="2">{$trans_w_two}</translation>
            <translation count="3">{$trans_w_three}</translation>
        </teixml>
};

declare function frbral:get_image_counts($a_coll,$a_index) {
    let $counts := 
       for $work in $a_coll/cts:textgroup/cts:work 
            let $urn := concat(
                substring-after($work/parent::cts:textgroup/@projid,':'),'.',substring-after($work/@projid,':'))
            let $entry := $a_index[atom:id[ends-with(.,$urn)]]
            let $google := if ($entry//refindex/location[starts-with(.,'http://books.google.com')]) then 1 else 0
            let $archive := if ($entry//refindex/location[starts-with(.,'http://www.archive.org')]) then 1 else 0
            let $hathi := if ($entry//refindex/location[starts-with(.,'http://hdl.handle.net')]) then 1 else 0
            let $total := sum(($google,$archive,$hathi))
            return <work count="{$total}"/> 
    return 
        <imagebooks>
            <images count="0">{count($counts[@count="0"])}</images>
            <images count="1">{count($counts[@count="1"])}</images>
            <images count="2">{count($counts[@count="2"])}</images>
            <images count="3">{count($counts[@count="3"])}</images>
        </imagebooks>
};    

declare function frbral:get_word_counts($a_coll) as node() {
    let $counts:= 
        for $work in $a_coll/cts:textgroup/cts:work 
            let $urn := concat(
                substring-after($work/parent::cts:textgroup/@projid,':'),'.',substring-after($work/@projid,':'))
            let $count := doc(concat($frbral:e_feeddir,'/wordcounts.xml'))//count[@work=$urn]
            return if ($count) then xs:int($count) else ()
    return
        <wordcounts>
            <works>{count($counts)}</works>
            <count>{sum($counts)}</count>
        </wordcounts>
};

let $collection := 
    if ($frbral:e_ns = 'all')
    then 
        collection($frbral:e_feeddir)//cts:TextInventory
    else
        collection($frbral:e_feeddir)//cts:TextInventory[starts-with(cts:textgroup/@projid,$frbral:e_ns)]

let $refindex :=
    collection($frbral:e_feeddir)/atom:feed/atom:entry[descendant::refindex]
return 

    <totals>
        <works>{frbral:get_work_count($collection)}</works>
        {(
            frbral:get_xml_counts($collection),
            frbral:get_image_counts($collection,$refindex),
            frbral:get_word_counts($collection)
        )}
    </totals>
 