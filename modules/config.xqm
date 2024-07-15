xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://www.tei-c.org/tei-simple/config";

import module namespace http="http://expath.org/ns/http-client";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare namespace templates="http://exist-db.org/xquery/html-templating";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~~
 : A list of regular expressions to check which external hosts are
 : allowed to access this TEI Publisher instance. The check is done
 : against the Origin header sent by the browser.
 :)
declare variable $config:origin-whitelist := (
    "(?:https?://localhost:.*|https?://127.0.0.1:.*)",
    "https?://jsdelivr.net",
    "https?://unpkg.com",
    "https?://cdpn.io",
    "https://cdn.tei-publisher.com",
    "https?://teipublisher.onrender.com"
);

(:~
 : Set to true to allow caching: if the browser sends an If-Modified-Since header,
 : TEI Publisher will respond with a 304 if the resource has not changed since last
 : access. However, this does *not* take into account changes to ODD or other auxiliary 
 : files, so don't use it during development.
 :)
declare variable $config:enable-proxy-caching :=
    let $prop := util:system-property("teipublisher.proxy-caching")
    return
        exists($prop) and lower-case($prop) = 'true'
;


(:~~
 : The version of the pb-components webcomponents library to be used by this app.
 : Should either point to a version published on npm,
 : or be set to 'local'. In the latter case, webcomponents
 : are assumed to be self-hosted in the app (which means you
 : have to npm install it yourself using the existing package.json).
 : If a version is given, the components will be loaded from a public CDN.
 : This is recommended unless you develop your own components.
 :)
declare variable $config:webcomponents :="2.24.0";

(:~
 : CDN URL to use for loading webcomponents. Could be changed if you created your
 : own library extending pb-components and published it to a CDN.
 :)
declare variable $config:webcomponents-cdn := "https://cdn.jsdelivr.net/npm/@teipublisher/pb-components";

(:~
 : Should documents be located by xml:id or filename?
 :)
declare variable $config:address-by-id := false();

(:~
 : Set default language for publisher app i18n
 :)
declare variable $config:default-language := "es";

(:
 : The default to use for determining the amount of content to be shown
 : on a single page. Possible values: 'div' for showing entire divs (see
 : the parameters below for further configuration), or 'page' to browse
 : a document by actual pages determined by TEI pb elements.
 :)
declare variable $config:default-view :="page";

(:
 : The default HTML template used for viewing document content. This can be
 : overwritten by the teipublisher processing instruction inside a TEI document.
 :)
declare variable $config:default-template :="page_pliegos.html";

(:
 : The element to search by default, either 'tei:div' or 'tei:text'.
 :)
declare variable $config:search-default :="tei:div";

(:
 : Defines which nested divs will be displayed as single units on one
 : page (using pagination by div). Divs which are nested
 : deeper than $pagination-depth will always appear in their parent div.
 : So if you have, for example, 4 levels of divs, but the divs on level 4 are
 : just small sub-subsections with one paragraph each, you may want to limit
 : $pagination-depth to 3 to not show the sub-subsections as separate pages.
 : Setting $pagination-depth to 1 would show entire top-level divs on one page.
 :)
declare variable $config:pagination-depth := 10;

(:
 : If a div starts with less than $pagination-fill elements before the
 : first nested div child, the pagination-by-div algorithm tries to fill
 : up the page by pulling following divs in. When set to 0, it will never
 : attempt to fill up the page.
 :)
declare variable $config:pagination-fill := 5;

(:
 : Display configuration for facets to be shown in the sidebar. The facets themselves
 : are configured in the index configuration, collection.xconf.
 :)
declare variable $config:facets := [
    map {
        "dimension": "collection",
        "heading": "facets.collection",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Colleción Moreno" return <pb-i18n key="facets.moreno">Colección Moreno</pb-i18n>
                case "Colección Varios" return <pb-i18n key="facets.varios">Colección Varios</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "publisher",
        "heading": "facets.publisher",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "José María Moreno" return "José María Moreno (padre)"
                default return $label
        }
    },
    map {
        "dimension": "pubplace",
        "heading": "facets.pubplace",
        "max": (),
        "hierarchical": false()
    },
    map {
        "dimension": "date",
        "heading": "facets.date",
        "max": (),
        "hierarchical": true()
    },
    map {
        "dimension": "language",
        "heading": "facets.language",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Español" return <pb-i18n key="facets.es">Español</pb-i18n>
                case "la" return "Latin"
                case "Habla andaluza" return <pb-i18n key="facets.ha">Habla andaluza</pb-i18n>
                case "Catalán" return <pb-i18n key="facets.ca">Variedades de catalán</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "verso",
        "heading": "facets.verso",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Verso" return <pb-i18n key="facets.verso_1">Verso</pb-i18n>
                case "Prosa" return <pb-i18n key="facets.prosa">Prosa</pb-i18n>
                case "Verso y prosa" return <pb-i18n key="facets.verso_prosa">Verso y prosa</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "genre",
        "heading": "facets.genre",
        "max": (),
        "hierarchical": false()
    },
    map {
        "dimension": "sacred",
        "heading": "facets.sacred",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Sagrado" return <pb-i18n key="facets.sacred_1">Sagrado</pb-i18n>
                case "Profano" return <pb-i18n key="facets.secular">Profano</pb-i18n>
                default return $label
        }
    },
    
    map {
        "dimension": "engraver",
        "heading": "notice.metadata.author",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Ilegible" return <pb-i18n key="facets.illegible">Ilegible</pb-i18n>
                default return $label
        }
    },
    
    map {
        "dimension": "femenino",
        "heading": "facets.femenino",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Mujer" return <pb-i18n key="facets.woman">Mujer</pb-i18n>
                case "Monarca (Reina/Princesa)" return <pb-i18n key="facets.queen">Reine/Princesa</pb-i18n>
                case "Religiosa" return <pb-i18n key="facets.nun">Religiosa</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "masculino",
        "heading": "facets.masculino",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Hombre" return <pb-i18n key="facets.man">Hombre</pb-i18n>
                case "Monarca (Rey/Príncipe)" return <pb-i18n key="facets.king">Monarca (Rey/Príncipe)</pb-i18n>
                case "Religioso" return <pb-i18n key="facets.religious_m">Religioso</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "nino",
        "heading": "facets.ninos_heading",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Niños/Niñas" return <pb-i18n key="facets.child">Niños/Niñas</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "grupos",
        "heading": "facets.grupos",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Hombres" return <pb-i18n key="facets.men">Hombres</pb-i18n>
                case "Mujeres" return <pb-i18n key="facets.women">Mujeres</pb-i18n>
                case "Mujere(s) y Hombre(s)" return <pb-i18n key="facets.m_w">Mujer(es) y hombre(s)</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "muerte",
        "heading": "facets.muerte",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Muerte" return <pb-i18n key="facets.death">Muerte</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "accion",
        "heading": "facets.accion",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Hablando" return <pb-i18n key="facets.speaking">Hablando</pb-i18n>
                case "Discutiendo" return <pb-i18n key="facets.fight">Discutiendo</pb-i18n>
                case "Bailando" return <pb-i18n key="facets.dance">Bailando</pb-i18n>
                case "Cantando" return <pb-i18n key="facets.sing">Cantando</pb-i18n>
                case "Cabalgando" return <pb-i18n key="facets.ride">Cabalgando</pb-i18n>
                case "Luchando" return <pb-i18n key="facets.combat">Luchando</pb-i18n>
                case "Rezando" return <pb-i18n key="facets.pray">Rezando</pb-i18n>
                case "Fumando" return <pb-i18n key="facets.smoke">Fumando</pb-i18n>
                case "Bebiendo" return <pb-i18n key="facets.drink">Bebiendo</pb-i18n>
                case "Comiendo" return <pb-i18n key="facets.eat">Comiendo</pb-i18n>
                case "Trabajando en el campo" return <pb-i18n key="facets.harvest">Trabajando en el campo</pb-i18n>
                case "Abrazando" return <pb-i18n key="facets.hug">Abrazando</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "accesorios",
        "heading": "facets.accesorios",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Flores" return <pb-i18n key="facets.flower">Flor(es)</pb-i18n>
                case "Armas" return <pb-i18n key="facets.weapons">Arma(s)</pb-i18n>
                case "Libros" return <pb-i18n key="facets.book">Libro(s)</pb-i18n>
                case "Papeles" return <pb-i18n key="facets.paper">Papel(es)</pb-i18n>
                case "Abanico" return <pb-i18n key="facets.fan">Abanico</pb-i18n>
                case "Instrumentos musicales" return <pb-i18n key="facets.music">Instrumento(s) musical(es)</pb-i18n>
                case "Otros accesorios" return <pb-i18n key="facets.other">Otros accesorios</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "construido",
        "heading": "facets.construido",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Ciudad o pueblo" return <pb-i18n key="facets.city">Ciudad o pueblo</pb-i18n>
                case "Lugar de culto" return <pb-i18n key="facets.church">Lugar de culto</pb-i18n>
                case "Casa" return <pb-i18n key="facets.house">Casa</pb-i18n>
                case "Torre" return <pb-i18n key="facets.tower">Torre</pb-i18n>
                case "Castillo" return <pb-i18n key="facets.castle">Castillo</pb-i18n>
                case "Plaza" return <pb-i18n key="facets.place">Plaza</pb-i18n>
                case "Mercado" return <pb-i18n key="facets.market">Mercado</pb-i18n>
                case "Calle" return <pb-i18n key="facets.street">Calle</pb-i18n>
                case "Molino" return <pb-i18n key="facets.mill">Molino</pb-i18n>
                case "Lugar de sepultura" return <pb-i18n key="facets.cementery">Lugar de sepultura</pb-i18n>
                case "Ruinas" return <pb-i18n key="facets.ruins">Ruinas</pb-i18n>
                case "Puerta" return <pb-i18n key="facets.door">Puerta</pb-i18n>
                case "Patíbulo" return <pb-i18n key="facets.scaffold">Patíbulo</pb-i18n>
                case "Campo de batalla" return <pb-i18n key="facets.battle">Campo de batalla</pb-i18n>
                case "Cárcel" return <pb-i18n key="facets.prison">Cárcel</pb-i18n>
                case "Interior de un edificio" return <pb-i18n key="facets.interior">Interior de un edificio</pb-i18n>
                case "Pozo" return <pb-i18n key="facets.well">Pozo</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "transporte",
        "heading": "facets.transporte",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Navío/Barco" return <pb-i18n key="facets.ship">Navío/Barco</pb-i18n>
                case "Vehículo" return <pb-i18n key="facets.vehicle">Vehículo</pb-i18n>
                case "Otros accesorios" return <pb-i18n key="facets.other">Otros accesorios</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "natural",
        "heading": "facets.natural",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Paisaje" return <pb-i18n key="facets.landscape">Paisaje</pb-i18n>
                case "Cuerpo(s) astronómico(s)" return <pb-i18n key="facets.astros">Cuerpo(s) astronómico(s)</pb-i18n>
                case "Bosque" return <pb-i18n key="facets.forest">Bosque</pb-i18n>
                case "Cueva" return <pb-i18n key="facets.cave">Cueva</pb-i18n>
                case "Jardín" return <pb-i18n key="facets.garden">Jardín</pb-i18n>
                case "Área de agua" return <pb-i18n key="facets.water">Área de agua</pb-i18n>
                case "Fuego" return <pb-i18n key="facets.fire">Fuego</pb-i18n>
                case "Árbol" return <pb-i18n key="facets.tree">Árbol</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "religion",
        "heading": "facets.religion",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Simbolismo cristiano" return <pb-i18n key="facets.symbol">Simbolismo cristiano</pb-i18n>
                case "Trinidad" return <pb-i18n key="facets.trinity">Trinidad</pb-i18n>
                case "Dios" return <pb-i18n key="facets.gods">Dios</pb-i18n>
                case "Demonio(s)" return <pb-i18n key="facets.demon">Demonio(s)</pb-i18n>
                case "Ángel(es)" return <pb-i18n key="facets.angel">Ángel(es)</pb-i18n>
                case "Narración bíblica" return <pb-i18n key="facets.story">Narración bíblica</pb-i18n>
                case "Virgen María" return <pb-i18n key="facets.mary">Virgen María</pb-i18n>
                case "Jesucristo" return <pb-i18n key="facets.jesus">Jesús</pb-i18n>
                case "San José" return <pb-i18n key="facets.joseph">San José</pb-i18n>
                case "Sacramentos" return <pb-i18n key="facets.sacrement">Sacramentos</pb-i18n>
                case "Paraíso" return <pb-i18n key="facets.heaven">Paraíso</pb-i18n>
                case "Infierno" return <pb-i18n key="facets.hell">Infierno</pb-i18n>
                case "Santo/Santa" return <pb-i18n key="facets.saint">Santo/Santa</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "animales",
        "heading": "facets.animales",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Animales domésticos" return <pb-i18n key="facets.domestic">Animales domésticos</pb-i18n>
                case "Animales salvajes" return <pb-i18n key="facets.wild">Animales salvajes</pb-i18n>
                case "Animales imaginarios" return <pb-i18n key="facets.fantastic">Animales imaginarios</pb-i18n>
                case "Animales antropomórficos" return <pb-i18n key="facets.anthropos">Animales antropomórficos</pb-i18n>
                case "Otros animales" return <pb-i18n key="facets.other_animals">Otros animales</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "escudo",
        "heading": "facets.escudo",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Escudo de armas" return <pb-i18n key="facets.coat_arms">Escudo de armas</pb-i18n>
                default return $label
        }
    },
    map {
        "dimension": "decorativos",
        "heading": "facets.decorativos",
        "max": (),
        "hierarchical": false(),
        "output": function($label) {
            switch($label)
                case "Otros ornamentos" return <pb-i18n key="facets.ornament">Otros ornamentos</pb-i18n>
                case "Friso" return <pb-i18n key="facets.frieze">Friso</pb-i18n>
                default return $label
        }
    }
];

(:
 : The function to be called to determine the next content chunk to display.
 : It takes two parameters:
 :
 : * $elem as element(): the current element displayed
 : * $view as xs:string: the view, either 'div', 'page' or 'body'
 :)
declare variable $config:next-page := nav:get-next#3;

(:
 : The function to be called to determine the previous content chunk to display.
 : It takes two parameters:
 :
 : * $elem as element(): the current element displayed
 : * $view as xs:string: the view, either 'div', 'page' or 'body'
 :)
declare variable $config:previous-page := nav:get-previous#3;

(:
 : The CSS class to declare on the main text content div.
 :)
declare variable $config:css-content-class := "content";

(:
 : The domain to use for logged in users. Applications within the same
 : domain will share their users, so a user logged into application A
 : will be able to access application B.
 :)
declare variable $config:login-domain := "org.exist.tei-simple";

(:~
 : Configuration XML for Apache FOP used to render PDF. Important here
 : are the font directories.
 :)
declare variable $config:fop-config :=
    let $fontsDir := config:get-fonts-dir()
    return
        <fop version="1.0">
            <!-- Strict user configuration -->
            <strict-configuration>true</strict-configuration>

            <!-- Strict FO validation -->
            <strict-validation>false</strict-validation>

            <!-- Base URL for resolving relative URLs -->
            <base>./</base>

            <renderers>
                <renderer mime="application/pdf">
                    <fonts>
                    {
                        if ($fontsDir) then (
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="normal" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-Bold.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="normal" weight="700"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-Italic.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="italic" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-BoldItalic.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="italic" weight="700"/>
                            </font>
                        ) else
                            ()
                    }
                    </fonts>
                </renderer>
            </renderers>
        </fop>
;

(:~
 : The command to run when generating PDF via LaTeX. Should be a sequence of
 : arguments.
 :)
declare variable $config:tex-command := function ($file) {
    ("pdflatex", "-interaction=nonstopmode", $file)
};

(:
 : Temporary directory to write .tex output to. The LaTeX process will receive this
 : as working director.
 :)
declare variable $config:tex-temp-dir :=
    util:system-property("java.io.tmpdir");

(:~
 : Configuration for epub files.
 :)
declare variable $config:epub-config := function ($doc as document-node(), $langParameter as xs:string?) {
    let $root := $doc/*
    let $properties := tpu:parse-pi($doc, ())
    return
        map {
            "metadata": map {
                "title": nav:get-metadata($properties, $root, "title"),
                "creator": string-join(nav:get-metadata($properties, $root, "author"), ", "),
                "urn": util:uuid(),
                "language": nav:get-metadata($properties, $root, "language")
            },
            "odd": $properties?odd,
            "output-root": $config:odd-root,
            "fonts": [
                $config:app-root || "/resources/fonts/Junicode.ttf",
                $config:app-root || "/resources/fonts/Junicode-Bold.ttf",
                $config:app-root || "/resources/fonts/Junicode-BoldItalic.ttf",
                $config:app-root || "/resources/fonts/Junicode-Italic.ttf"
            ]
        }
};

(:~
 : Root path where images to be included in the epub can be found.
 : Leave as empty sequence if images can be located within the data
 : collection using relative path.
 :)
declare variable $config:epub-images-path := ();

(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

(:
 : The context path to use for links within the application, e.g. menus.
 : The default should work when running on top of a standard eXist installation,
 : but may need to be changed if the app is behind a proxy.
 :)
declare variable $config:context-path :=
    let $prop := util:system-property("teipublisher.context-path")
    return
        if (exists($prop)) then
            if ($prop = "auto") then
                request:get-context-path() || substring-after($config:app-root, "/db") 
            else
                $prop
        else if (exists(request:get-header("X-Forwarded-Host")))
            then ""
        else
            request:get-context-path() || substring-after($config:app-root, "/db")
;

(:~
 : The root of the collection hierarchy containing data.
 :)
declare variable $config:data-root :=$config:app-root || "/data";

(:~
 : The root of the collection hierarchy whose files should be displayed
 : on the entry page. Can be different from $config:data-root.
 :)
declare variable $config:data-default := $config:data-root;

(:~
 : A sequence of root elements which should be excluded from the list of
 : documents displayed in the browsing view.
 :)
declare variable $config:taxonomy := $config:data-root || "/taxonomy.xml";

(:~
 : A sequence of root elements which should be excluded from the list of
 : documents displayed in the browsing view.
 :)
declare variable $config:data-exclude := (
    doc($config:taxonomy)//tei:text,
    collection($config:data-root || "/doc")//tei:text
);

(:~
 : The main ODD to be used by default
 :)
declare variable $config:default-odd :="projet_cordel.odd";

(:~
 : Complete list of ODD files used by the app. If you add another ODD to this list,
 : make sure to run modules/generate-pm-config.xql to update the main configuration
 : module for transformations (modules/pm-config.xql).
 :)
declare variable $config:odd-available := xmldb:get-child-resources($config:odd-root)[ends-with(., ".odd")];

(:~
 : List of ODD files which are used internally only, i.e. not for displaying information
 : to the user.
 :)
declare variable $config:odd-internal := "docx.odd";

declare variable $config:odd-root := $config:app-root || "/resources/odd";

declare variable $config:output := "transform";

declare variable $config:output-root := $config:app-root || "/" || $config:output;

declare variable $config:default-odd-for-docx := $config:default-odd;

declare variable $config:default-docx-pi := ``[odd="`{$config:default-odd-for-docx}`"]``;

declare variable $config:module-config := doc($config:odd-root || "/configuration.xml")/*;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:session-prefix := $config:expath-descriptor/@abbrev/string();

declare variable $config:default-fields := ();

declare variable $config:dts-collections := map {
    "id": "default",
    "title": $config:expath-descriptor/expath:title/string(),
    "memberCollections": (
            map {
                "id": "documents",
                "title": "Document Collection",
                "path": $config:data-default,
                "members": function() {
                    nav:get-root((), map {
                        "leading-wildcard": "yes",
                        "filter-rewrite": "yes"
                    })
                },
                "metadata": function($doc as document-node()) {
                    let $properties := tpu:parse-pi($doc, ())
                    return
                        map:merge((
                            map:entry("title", nav:get-metadata($properties, $doc/*, "title")/string()),
                            map {
                                "dts:dublincore": map {
                                    "dc:creator": string-join(nav:get-metadata($properties, $doc/*, "author"), "; "),
                                    "dc:license": nav:get-metadata($properties, $doc/*, "license")
                                }
                            }
                        ))
                }
            },
            map {
                "id": "odd",
                "title": "ODD Collection",
                "path": $config:odd-root,
                "members": function() {
                    collection($config:odd-root)/tei:TEI
                },
                "metadata": function($doc as document-node()) {
                    map {
                        "title": string-join($doc//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)], "; ")
                    }
                }
            }
    )
};

declare variable $config:dts-page-size := 10;

declare variable $config:dts-import-collection := $config:data-default || "/playground";

(:~
 : Returns a default display configuration as a map for the given collection and
 : document path. If an empty value is returned, the default configuration (as configured
 : by global variables in this module) will be
 : used. If a map is returned, it will be merged with the default configuration, so
 : you can selectively overwrite particular settings.
 :
 : Change this to support different configurations for different collections or document types.
 : By default this returns a configuration based on the default settings defined
 : by other variables in this module.
 : 
 : @param $collection relative collection path (i.e. with $config:data-root stripped off)
 : @param $docUri relative document path (including $collection)
 :)
declare function config:collection-config($collection as xs:string?, $docUri as xs:string?) {
    (: Return empty sequence to use default config :)
    (:():)

    (: 
     : Replace line above with the following code to switch between different view configurations per collection.
     : $collection corresponds to the relative collection path (i.e. after $config:data-root). 
     :)
    
    switch ($collection)
        case "Illustraciones" return
            map {
                "odd": "projet_cordel.odd",
                "view": "body",
                "depth": $config:pagination-depth,
                "fill": $config:pagination-fill,
                "template": "illustration.html"
            }
        case "Documentation" return
            map {
                "odd": "projet_cordel.odd",
                "view": "body",
                "depth": 1,
                "fill": $config:pagination-fill,
                "template": "static.html"
            }
        (: For annotations we need to overwrite document-specific settings :)
        case "annotate" return
            map {
                "template": "annotate.html",
                "overwrite": true(),
                "depth": 1,
                "fill": 0
            }
        default return
            ()
    
};

(:~
 : Helper function to retrieve the default config for the given document path.
 : Delegates to config:collection-config().
 :)
declare function config:default-config($docUri as xs:string?) {
    let $defaultConfig := map {
        "odd": $config:default-odd,
        "view": $config:default-view,
        "depth": $config:pagination-depth,
        "fill": $config:pagination-fill,
        "template": $config:default-template
    }
    let $collection := 
        if (exists($docUri)) then
            replace($docUri, "^(.*)/[^/]+$", "$1") => substring-after($config:data-root || "/")
        else
            ()
    let $collectionConfig :=
        if (exists($docUri)) then
            config:collection-config($collection, substring-after($docUri, $config:data-root || "/"))
        else
            config:collection-config((), ())
    return
        if (exists($collectionConfig)) then
            map:merge(($defaultConfig, $collectionConfig))
        else
            $defaultConfig
};

declare function config:document-type($div as element()) {
    switch (namespace-uri($div))
        case "http://www.tei-c.org/ns/1.0" return
            "tei"
        case "http://docbook.org/ns/docbook" return
            "docbook"
        default return
            "jats"
};

declare function config:get-document($idOrName as xs:string) {
    if ($config:address-by-id) then
        root(collection($config:data-root)/id($idOrName))
    else if (starts-with($idOrName, '/')) then
        doc(xmldb:encode-uri($idOrName))
    else
        doc(xmldb:encode-uri($config:data-root || "/" || $idOrName))
};

(:~
 : Return an ID which may be used to look up a document. Change this if the xml:id
 : which uniquely identifies a document is *not* attached to the root element.
 :)
declare function config:get-id($node as node()) {
    root($node)/*/@xml:id
};

(:~
 : Returns a path relative to $config:data-root used to locate a document in the database.
 :)
declare function config:get-relpath($node as node()) {
    let $root := if (ends-with($config:data-root, "/")) then
        $config:data-root
    else
        $config:data-root || "/"
    return
        substring-after(document-uri(root($node)), $root)
};

declare function config:get-identifier($node as node()) {
    config:get-relpath($node)
};


(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};

(: Try to dynamically determine data directory by calling JMX. :)
declare function config:get-data-dir() as xs:string? {
    try {
        let $request := <http:request method="GET" href="http://localhost:{request:get-server-port()}/{request:get-context-path()}/status?c=disk"/>
        let $response := http:send-request($request)
        return
            if ($response[1]/@status = "200") then
                let $dir := $response[2]//jmx:DataDirectory/string()
                return
                    if (matches($dir, "^\w:")) then
                        (: windows path? :)
                        "/" || translate($dir, "\", "/")
                    else
                        $dir
            else
                ()
    } catch * {
        ()
    }
};

declare function config:get-repo-dir() {
    let $dataDir := config:get-data-dir()
    let $pkgRoot := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version
    return
        if ($dataDir) then
            $dataDir || "/expathrepo/" || $pkgRoot
        else
            ()
};


declare function config:get-fonts-dir() as xs:string? {
    let $repoDir := config:get-repo-dir()
    return
        if ($repoDir) then
            $repoDir || "/resources/fonts"
        else
            ()
};
