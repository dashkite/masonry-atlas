import * as cheerio from "cheerio"

import * as Atlas from "@dashkite/atlas"

atlas = ({ entries, map }) ->
  ( context ) -> 
    $ = cheerio.load context.input
    map = await Atlas.generate entries, map
    json = JSON.stringify map, null, 2
    map = ( $ "<script type = 'importmap'>" ).text json
    if ( target = $ "script[type='importmap']" ).length > 0
      target.replaceWith map
    else
      ( $ "head" ).prepend map
    $.html()

export default atlas
export { atlas }