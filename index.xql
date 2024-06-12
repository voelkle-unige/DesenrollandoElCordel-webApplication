xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

(: Categorize dates in periods:)
declare function idx:parse-date($date) {
    if (matches($date, "184\d")) then
        "1840-1849/" || $date
    else if (matches($date, "177\d")) then
        "1770-1779/" || $date
    else if (matches($date, "178\d")) then
        "1780-1789/" || $date
    else if (matches($date, "181\d")) then
        "1810-1819/" || $date
    else if (matches($date, "182\d")) then
        "1820-1829/" || $date
    else if (matches($date, "183\d")) then
        "1830-1839/" || $date
    else if (matches($date, "185\d")) then
        "1850-1859/" || $date
    else if (matches($date, "186\d")) then
        "1860-1869/" || $date
    else if (matches($date, "187\d")) then
        "1870-1879/" || $date
    else if (matches($date, "188\d")) then
        "1880-1889/" || $date
    else if (matches($date, "189\d")) then
        "1890-1899/" || $date
    else if (matches($date, "[s.a]")) then
        $date
    else ()
};

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
 
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return
                string-join((
                    $header//tei:titleStmt/tei:title
                ), " - ")
                
            (:Facets for pliegos:)
            case "language" return
                head((
                    $header//tei:langUsage/tei:language
                ))
            (:case "date" return head((
                $header//tei:sourceDesc/tei:biblFull/tei:publicationStmt/tei:date
            )):)
            case "date" return (
            idx:parse-date($root//tei:sourceDesc/tei:biblFull/tei:publicationStmt/tei:date
            ))
            case "collection" return head((
                $header//tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:collection
            ))
            case "pubplace" return head((
                $header//tei:sourceDesc//tei:pubPlace
            ))
            case "publisher" return head((
                $header//tei:sourceDesc//tei:publisher
            ))
            case "verso" return head((
                $header//tei:keywords/tei:term[@type="verso_prosa"]
            ))
            case "genre" return head((
                $header//tei:keywords/tei:term[@type="tipo_texto"]
            ))
            case "sacred" return head((
                $header//tei:keywords/tei:term[@type="sagrado_profano"]
            ))
            
            (:Facets for illusrations:)
            case "engraver" return head((
                $header//tei:author[@role="grabador"]
            ))
            
            case "masculino" return (
                idx:get-masculino($header)
            )
            case "femenino" return (
                idx:get-femenino($header)
            )
            case "grupos" return (
                idx:get-grupos($header)
            )
            case "nino" return (
                idx:get-nino($header)
            )
            case "accion" return (
                idx:get-accion($header)
            )
            case "muerte" return (
                idx:get-muerte($header)
            )
            case "accesorios" return (
                idx:get-accesorios($header)
            )
            case "construido" return (
                idx:get-construido($header)
            )
            case "natural" return (
                idx:get-natural($header)
            )
            case "transporte" return (
                idx:get-transporte($header)
            )
            case "religion" return (
                idx:get-religion($header)
            )
            case "animales" return (
                idx:get-animales($header)
            )
            case "escudo" return (
                idx:get-escudo($header)
            )
            case "decorativos" return (
                idx:get-decorativos($header)
            )
            default return
                ()
};

declare function idx:get-masculino($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#personaje_masculino"][1]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-femenino($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#personaje_femenino"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-grupos($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#grupos_personajes"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-nino($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#ninos"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/tei:catDesc
};

declare function idx:get-accion($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#accion"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-muerte($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#muerte"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/tei:catDesc
};

declare function idx:get-accesorios($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#accesorios"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-construido($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#construidos"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-natural($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#naturales"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-transporte($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#transporte"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-religion($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#religion"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-animales($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#animales"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-escudo($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#escudo"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/tei:catDesc
};

declare function idx:get-decorativos($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#ornamentos"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};
