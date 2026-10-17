import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"
import { atlas } from "../src/index"
import Path from "node:path"
import browserKeys from "@dashkite/atlas/presets/browser"

do ->

  print await test "Masonry Atlas", [
    test "injects import map into HTML for simple-app", ->
      fixtureDirectory = Path.resolve process.cwd(), "test/fixtures/simple-app"
      entryPath = Path.join fixtureDirectory, "src/index.js"
      
      plugin = atlas
        entries: [ entryPath ]
        map: 
          cwd: fixtureDirectory
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
      assert importMap.imports?, "Should have imports"
      
      # Check that non-Node layout (CDN) was used for dependencies
      assert importMap.imports["math-lib"]?, "Should contain math-lib mapping"
      assert importMap.imports["math-lib"].startsWith("https://"), "math-lib should be resolved to a CDN URL"
      
    test "injects import map into HTML for nested-app", ->
      fixtureDirectory = Path.resolve process.cwd(), "test/fixtures/nested-app"
      entryPath = Path.join fixtureDirectory, "src/index.js"
      
      plugin = atlas
        entries: [ entryPath ]
        map: 
          cwd: fixtureDirectory
          resolvers: browserKeys
          
      context = 
        input: """
        <!DOCTYPE html>
        <html><head></head><body></body></html>
        """
        
      outputHtml = await plugin context
      
      match = outputHtml.match(/<script type="importmap">([\s\S]*?)<\/script>/)
      assert match?, "Import map script tag should exist"
      
      importMap = JSON.parse match[1]
      assert importMap.imports?, "Should have imports"
      
      # Check that dependencies map correctly to CDN
      assert importMap.imports["pkg-a"]?, "Should contain pkg-a"
      assert importMap.imports["pkg-b"]?, "Should contain pkg-b"
      
      # Generalized assertions for all URLs in the generated map
      for key, value of importMap.imports
        url = new URL value
        assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"
          
      if importMap.scopes?
        for scope, mappings of importMap.scopes
          for key, value of mappings
            url = new URL value
            assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"

    test "injects import map into HTML for cerulean storage shell", ->
      # Point to the storage shell fixture in masonry-lambda
      fixtureDirectory = Path.resolve process.cwd(), "../masonry-lambda"
      entryPath = Path.join fixtureDirectory, "test/fixtures/shells/storage.js"
      
      plugin = atlas
        entries: [ entryPath ]
        map: 
          cwd: fixtureDirectory
          resolvers: browserKeys
          
      context = 
        input: """
        <!DOCTYPE html>
        <html><head></head><body></body></html>
        """
        
      outputHtml = await plugin context
      
      match = outputHtml.match(/<script type="importmap">([\s\S]*?)<\/script>/)
      assert match?, "Import map script tag should exist"
      
      importMap = JSON.parse match[1]
      assert importMap.imports?, "Should have imports"
      
      # Ensure panama is hoisted as a dependency
      hasPanama = false
      for key, value of importMap.imports
        if key.startsWith "@dashkite/panama"
          hasPanama = true
          
      assert hasPanama, "Should contain @dashkite/panama in imports"
      
      # Generalized assertions for all URLs in the generated map
      for key, value of importMap.imports
        url = new URL value
        assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"
          
      if importMap.scopes?
        for scope, mappings of importMap.scopes
          for key, value of mappings
            url = new URL value
            assert not url.pathname.includes("//"), "URL pathname should not contain double slashes: #{value}"
  ]
