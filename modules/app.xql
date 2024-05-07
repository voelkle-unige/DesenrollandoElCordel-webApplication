xquery version "3.1";

(: 
 : Module for app-specific template functions
 :
 : Add your own templating functions here, e.g. if you want to extend the template used for showing
 : the browsing view.
 :)
module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %templates:wrap
function app:foo($node as node(), $model as map(*)) {
    <p>Dummy templating function.</p>
};

declare
    %templates:wrap
function app:load-place($node as node(), $model as map(*), $name as xs:string) {
    let $geo := doc($config:data-root || "/places.xml")//tei:place[@n = xmldb:decode($name)]
    let $geo-token := tokenize($geo//tei:geo/text(), ",")
    return
        map {
            "title": $geo/tei:placeName[@type="main"]/string(),
            "key": $geo/@n,
            "latitude": $geo-token[1],
            "longitude": $geo-token[2]
        }
};