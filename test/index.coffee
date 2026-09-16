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
          root: fixtureDirectory
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
          root: fixtureDirectory
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
      assert importMap.imports["pkg-a"].startsWith("https://"), "pkg-a should be CDN URL"
      assert importMap.imports["pkg-b"].startsWith("https://"), "pkg-b should be CDN URL"
      
      # Check scopes
      assert importMap.scopes?, "Should have scopes"
      assert importMap.scopes["https://unpkg.com/pkg-a@1.0.0/"]["shared-dep"]?, "Should map shared-dep in pkg-a scope"
      assert importMap.scopes["https://unpkg.com/pkg-b@1.0.0/"]["shared-dep"]?, "Should map shared-dep in pkg-b scope"
  ]
