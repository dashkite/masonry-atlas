import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"
import { atlas } from "../src/index"
import Path from "node:path"
import browserKeys from "@dashkite/atlas/presets/browser"

do ->

  print await test "Masonry Atlas", [
    test "injects import map into HTML", ->
      # We'll use the simple-app fixture from masonry-lambda to avoid duplicating fixtures
      fixtureDirectory = Path.resolve process.cwd(), "../masonry-lambda/test/fixtures/simple-app"
      entryPath = Path.join fixtureDirectory, "src/index.js"
      
      plugin = atlas
        entries: [ entryPath ]
        map: 
          cwd: fixtureDirectory
          root: fixtureDirectory
          # Use browser resolvers to test non-Node CDN layout
          resolvers: browserKeys
          
      context = 
        input: """
        <!DOCTYPE html>
        <html>
        <head>
          <title>Test</title>
        </head>
        <body></body>
        </html>
        """
        
      outputHtml = await plugin context
      
      # Assert the import map script was injected
      assert outputHtml.includes('<script type="importmap">')
      
      # Extract and parse the JSON to verify it's structurally an import map
      match = outputHtml.match(/<script type="importmap">([\s\S]*?)<\/script>/)
      assert match?, "Import map script tag should exist"
      
      importMap = JSON.parse match[1]
      console.log JSON.stringify(importMap, null, 2)
      assert importMap.imports?, "Should have imports"
      
      # Check that non-Node layout (CDN) was used for dependencies
      assert importMap.imports["math-lib"]?, "Should contain math-lib mapping"
      assert importMap.imports["math-lib"].startsWith("https://"), "math-lib should be resolved to a CDN URL"
  ]
