xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace api = "http://teipublisher.com/api/custom";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

(: Add your own module imports here :)
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace app = "teipublisher.com/app" at "app.xql";
import module namespace config = "http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace teis="http://www.tei-c.org/tei-simple/query/tei" at "query-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation/tei" at "navigation-tei.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "query.xql";
import module namespace vapi="http://teipublisher.com/api/view" at "lib/api/view.xql";
import module namespace capi="http://teipublisher.com/api/collection" at "lib/api/collection.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace templates="http://exist-db.org/xquery/html-templating";

(:~
 : Keep this. This function does the actual lookup in the imported modules.
 :)
declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function functx:capitalize-first($arg as xs:string?)  as xs:string? {
   concat(upper-case(substring($arg,1,1)), substring($arg,2))
};

declare function api:get-manifest($node as node(), $model as map(*)) {
    (: Information about the document:)
    let $docId := $model?doc
    let $doc := doc($config:data-root || "/" ||$docId)
    let $id := $doc/tei:TEI/string(@xml:id)
    
    (: Information about the manifest :)
    let $manifestFile := doc($config:data-root || "/manifest.xml")
    let $manifest := $manifestFile//tei:item[@n=$id]
        =>substring-after("l/")
    let $manifestN := $manifestFile//tei:item/string(@n)
    
    return if($id = $manifestN) then
        <span>
            <a href="../mirador.html?manifest={$manifest}" target="_blank">
                <pb-i18n key="notice.comparar">Comparar</pb-i18n>
                <img src="resources/images/logos/mirador.png"
                     alt="Logo de Mirador" height="22"
                     style="display:inline-block; padding-left:10px; vertical-align:middle;"/>
            </a>
        </span>
        else()
};

(:declare function api:get-manifest($node as node(), $model as map(*)) {
    let $id := $model?doc
    let $doc := doc($config:data-root || "/" ||$id)
    let $manifest := $doc//tei:facsimile/string(@facs)
        =>substring-after("l/")
    return
        <span>
            <a href="../mirador.html?manifest={$manifest}" target="_blank">
                <pb-i18n key="notice.comparar">Comparar</pb-i18n>
                <img src="resources/images/logos/mirador.png"
                     alt="Logo de Mirador" height="22"
                     style="display:inline-block; padding-left:10px; vertical-align:middle;"/>
            </a>
        </span>
};:)

(:Retrieve one manifest:)
declare function api:manifest($requests as map(*)) {
    let $id := xmldb:decode($requests?parameters?id)
    return
        if ($id) then
            let $doc := config:get-document($id)
            let $manifest := $doc//tei:facsimile/string(@facs)
            return
                map {
                "manifest": $manifest
                }
        else
            error($errors:BAD_REQUEST, "No document specified")
};

(:Retrieve a list of manifests:)
declare function api:manifests-list($requests as map(*)){
    let $doc := $requests?parameters?doc
    for $text in collection($config:data-root || "/Pliegos")
        let $manifest := $text//tei:facsimile/string(@facs)
        return $manifest      
};

declare function api:download-pdf($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    
    let $pliego := $ID
    => substring-before('.')
    
    let $doi := doc($config:data-root || "/Pliegos/" || $ID)//tei:idno[@type = "DOI"]
    => substring-after('o.')
    
    return
        <paper-button
            class="page-pliegos__button-descargar"
            raised="">
            <a
                href="https://zenodo.org/records/{$doi}/files/{$pliego}.pdf?download"
                target="_blank">PDF</a>
        </paper-button>
};

declare function api:download-tei($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    
    let $doi := doc($config:data-root || "/Pliegos/" || $ID)//tei:idno[@type = "DOI"]
    => substring-after('o.')
    
    return
        <paper-button
            class="page-pliegos__button-descargar"
            raised="">
            <a
                href="https://zenodo.org/records/{$doi}/files/{$ID}?download"
                target="_blank">XML TEI</a>
        </paper-button>
};

(: Display the illustrations with IIIF URI + Coordinates:)
declare function api:display-illustration($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    let $doc := doc($config:data-root || "/Illustraciones/" || $ID)
    let $URI := concat("https://iiif.hedera.unige.ch/iiif/3/pliegos/", $doc//tei:figure/tei:graphic/string(@url))
    
    
    return
        <img class="page-illustration__img" src="{$URI}"/>
};

(: Display breadcrumb Illustration :)
declare function api:breadcrumbs-illustration($node as node(), $model as map(*)) {
    let $ID := $model?doc
    => substring-after('/')
    => substring-before('.')
    
    return
        <span class="page-illustration__filariane"><a href="../inicio.html"><pb-i18n key="inicio.titre"/></a> / <a href="../index.html?collection=Illustraciones"><pb-i18n key="collection.illustration"/></a> / <span>{$ID}</span></span>
};

(: Display breadcrumb Pliegos :)
declare function api:breadcrumbs-pliegos($node as node(), $model as map(*)) {
    let $XML := $model?doc
    => substring-after('/')
    
    let $ID := $XML
    => substring-before('.')
    
    let $collection := doc($config:data-root || "/Pliegos/" || $XML)//tei:collection
    
    return if ($collection[contains(., "Moreno")]) then (
        <span class="page-pliegos__filariane">
            <a href="../inicio.html"><pb-i18n key="inicio.titre"/></a> / <a href="../index.html?collection=Pliegos&amp;facet-collection=Colleción+Moreno"><pb-i18n key="collection.moreno"/></a> / <span>{$ID}</span>
        </span>)
        
        else (
         <span class="page-pliegos__filariane">
            <a href="../inicio.html"><pb-i18n key="inicio.titre"/></a> / <a href="../index.html?collection=Pliegos&amp;facet-collection=Colección+Varios"><pb-i18n key="collection.varios"/></a> / <span>{$ID}</span>
        </span>)
};

(: New endpoint for static pages : based on the code of the Escher Briefedition project :)
declare function api:view-about($request as map(*)) {
    let $id := xmldb:decode($request?parameters?doc)
    let $docid := if (ends-with($id, '.xml')) then $id else $id || '.xml'
    let $template := doc($config:app-root || "/templates/pages/static.html")
    let $title := (doc($config:data-root || "/Documentation/" || $docid)//tei:text//tei:head)[1]
    let $model := map {
        "doc": 'Documentation/' || $docid,
        "template": "static",
        "title": $title,
        "docid": $id,
        "uri": "Documentation/" || $id
    }
    return
        templates:apply($template, vapi:lookup#2, $model, tpu:get-template-config($request))
};

(: New endpoint for places :)
(: Shows the places on a map :)
declare function api:places-all($request as map(*)) {
    let $places := doc($config:data-root || "/places.xml")//tei:listPlace/tei:place
    return 
        array { 
            for $place in $places
                let $tokenized := tokenize($place/tei:location/tei:geo, ",")
                return 
                    map {
                        "latitude":$tokenized[1],
                        "longitude":$tokenized[2],
                        "label":$place/@n/string()
                    }
            }        
};

declare function api:places($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category
    let $limit := $request?parameters?limit
    let $places :=
        if($search and $search != '') then
            doc($config:data-root || "/places.xml")//tei:listPlace/tei:place[matches(@n, "^" || $search, "i")]
        else
            doc($config:data-root || "/places.xml")//tei:listPlace/tei:place
    let $sorted := sort($places, "?lang=es-ES", function($place) {lower-case($place/@n)})
    let $letter :=
        if (count($places) < $limit) then
            "All"
        else if ($letterParam = '') then
            substring($sorted[1], 1, 1) => upper-case()
        else
            $letterParam
    let $byLetter :=
        if ($letter = 'All') then
            $sorted
        else
            filter($sorted, function($entry) {
                starts-with(lower-case($entry/@n), lower-case($letter))
            
            })
    return
        map {
            "items": api:output-place($byLetter, $letter, $search),
            "categories":
                if (count($places) < $limit) then
                    []
                else array {
                    for $index in 1 to string-length('AÁBCDEÉFGHIJKLMNOPQRSTUÚVWXYZ')
                    let $alpha := substring('AÁBCDEÉFGHIJKLMNOPQRSTUÚVWXYZ', $index, 1)
                    let $hits := count(filter($sorted, function($entry) {starts-with(lower-case($entry/@n), lower-case($alpha))}))
                    where $hits > 0
                    return 
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                        map {
                            "category": "All",
                            "count": count($sorted)
                        }
                }
        }
};

declare function api:output-place($list, $category as xs:string, $search as xs:string?) {
    array {
        for $place in $list
            let $categoryParam := if ($category = "all") then substring($place/@n, 1, 1) else $category
            let $params := "category=" || $categoryParam || "&amp;search=" || $search
            let $label := $place/@n/string()
            let $name := $place/tei:placeName[@type="main"]
            let $coords := tokenize($place/tei:location/tei:geo, ",")
            return
                if ($place/parent::tei:listPlace[@xml:id="conocidos"]) then
                <span class="place">
                    <a href="places/{$label}?{$params}">{$name}</a>
                    <pb-geolocation latitude="{$coords[1]}" longitude="{$coords[2]}" label="{$label}" emit="map" event="click">
                        <iron-icon icon="maps:map"></iron-icon>
                    </pb-geolocation>
                </span>
                else(
                        <span class="place">
                            <a href="places/{$label}?{$params}">{$name}</a>*
                        </span>
                )
    }
};

declare function api:document-list($list) {
    for $doc in $list
        let $title := $doc//tei:fileDesc/tei:titleStmt/tei:title/string()
        let $id := $doc/@xml:id/string()
        return
            <li>
                <a href="../../Pliegos/{functx:capitalize-first($id)}.xml" target="_blank">
                    {$title}
                </a>
            </li>
};

declare %templates:default("type", "place")
function api:place-mentions($node as node(), $model as map(*), $type as xs:string) {
    let $pliegos := collection($config:data-root || "/Pliegos")//tei:TEI[.//tei:placeName/@key = $model?key]
    let $conocidos := doc($config:data-root || "/places.xml")//tei:listPlace[@xml:id="conocidos"]/tei:place[@n = $model?key]
    let $main-name := doc($config:data-root || "/places.xml")//tei:place[@n = $model?key]//tei:placeName[@type="main"]
    let $alt-name := doc($config:data-root || "/places.xml")//tei:place[@n = $model?key]//tei:placeName[@type="alt"]
    let $ref := doc($config:data-root || "/places.xml")//tei:place[@n = $model?key]//tei:ref
    let $coords := tokenize($conocidos/tei:location/tei:geo, ",")
    return
        if($conocidos) then
                <div>
                    <div>
                        <h3 class="content-body__wkd-title"><pb-i18n key="places.wikidata">Equivalente Wikidata: </pb-i18n></h3>
                        <span> <a href="{$ref/@target/string()}" target="_blank"> {$ref/text()}</a></span>
                    </div>
                    {
                        if(count($alt-name) > 0) then
                         <div>
                            <h3 class="content-body__wkd-title"><pb-i18n key="places.variantes">Grafía alternativa: </pb-i18n></h3>
                            <span>{$alt-name}</span>
                         </div>
                        else ()
                    }
                    {
                        if(count($pliegos)) then
                            if(count($pliegos) > 0) then
                                        <div>
                                            <h3><pb-i18n key="places.documents">Número de documentos: </pb-i18n> {count($pliegos)}</h3>
                                            <ul>{api:document-list($pliegos)}</ul>
                                        </div>
                                    else ()
                             else ()
                    }
                </div>
        else(
            <div class="ambiguous">
                <h2>{$main-name}</h2>
                    <div>
                        <h3 class="content-body__wkd-title"><pb-i18n key="places.type">Tipo: </pb-i18n></h3>
                        <span><pb-i18n key="places.inclassable">Inclasificables</pb-i18n></span>
                    </div>
                        { if(count($pliegos)) then
                            if(count($pliegos) > 0) then
                                        <div>
                                            <h3><pb-i18n key="places.documents">Número de documentos: </pb-i18n> {count($pliegos)}</h3>
                                            <ul>{api:document-list($pliegos)}</ul>
                                        </div>
                                    else ()
                             else ()
                        }
                </div>
        )
};

declare function api:folhetos($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category
    let $limit := $request?parameters?limit
    let $folhetos := if($search and $search != '') then
            doc($config:data-root || "/folhetos.xml")//tei:listBibl/tei:bibl[matches(@n, "^" || $search, "i")]
        else
            doc($config:data-root || "/folhetos.xml")//tei:listBibl/tei:bibl
    let $sorted := sort($folhetos, "?lang=es-ES", function($folhetos) {lower-case($folhetos/@n)})
    let $letter :=
        if (count($folhetos) < $limit) then
            "All"
        else if ($letterParam = '') then
            substring($sorted[1], 1, 1) => upper-case()
        else
            $letterParam
    let $byLetter :=
        if ($letter = 'All') then
            $sorted
        else
            filter($sorted, function($entry) {
                starts-with(lower-case($entry/@n), lower-case($letter))
            
            })
    return
        map {
            "items": api:output-folhetos($byLetter, $letter, $search),
            "categories":
                if (count($folhetos) < $limit) then
                    []
                else array {
                    for $index in 1 to string-length('AÁBCDEÉFGHIJKLMNOPQRSTUÚVWXYZ')
                    let $alpha := substring('AÁBCDEÉFGHIJKLMNOPQRSTUÚVWXYZ', $index, 1)
                    let $hits := count(filter($sorted, function($entry) {starts-with(lower-case($entry/@n), lower-case($alpha))}))
                    where $hits > 0
                    return 
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                        map {
                            "category": "All",
                            "count": count($sorted)
                        }
                }
        }
};

declare function api:output-folhetos($list, $category as xs:string, $search as xs:string?) {
    array {
    <ul>
        {for $folhetos in $list
            let $categoryParam := if ($category = "all") then substring($folhetos/@n, 1, 1) else $category
            let $params := "category=" || $categoryParam || "&amp;search=" || $search
            let $title := $folhetos/tei:title/string()
            let $author := $folhetos/tei:author/string()
            let $engraver := if ($folhetos/tei:editor != '') then concat(", ", $folhetos/tei:editor/string(), " (graveur)") else ()
            let $date := $folhetos/tei:date/string()
            let $pages := $folhetos/tei:measure/string()
            let $idno := $folhetos/tei:idno/string()
            
            return
                <li>{$author}, <i>{$title}</i>, {$date}, {$pages}{$engraver}, {$idno}</li>
                }
    </ul>
    }
};