import * as cheerio from "cheerio"

import * as Atlas from "@dashkite/atlas"

atlas = ({ entries, map }) ->
  ( context ) -> 
    $ = cheerio.load context.input
    _map = await Atlas.generate entries, map
    json = JSON.stringify _map, null, 2
    script = ( $ "<script type = 'importmap'>" ).text json
    if ( target = $ "script[type='importmap']" ).length > 0
      target.replaceWith script
    else
      ( $ "head" ).prepend script
    $.html()

export default atlas
export { atlas }