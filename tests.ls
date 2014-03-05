require! chai.expect
require! mock: \mock-fs

require! './multiglob'


# Drop-in function to mark tests as not yet implemented.
NotImplemented = !->
  new Error "Test not implemented"
    ..stack = null
    throw ..

# Work around LiveScript's use of `it`.  Use it to wrap functions
# defining test cases.
as = (.bind global['it'])


describe "multiglob" !->
  beforeEach !->
    mock do
      '.gitignore': ''
      'lib':
        'glob.coffee': ''
        'glob.js': ''
        'match.ls': ''
        'match.js': ''
        'otherlib.js': ''
        'testdata.json.ls': ''
        'testdata.json': ''
      'bin':
        'script': ''
      'package.json': ''
      'index.ls': ''
      'node_modules':
        'lib1':
          'LICENSE': ''
          'README.md': ''
          'index.js': ''
          'package.json': ''
  afterEach !->
    mock.restore!

  # Test features.
  describe "can" as !->
    this "match a single pattern" !->
      results = multiglob.sync '**/*.json'
      expect results .not.to.be.empty

      results .= sort!
      expect results .to.deep.equal <[
        lib/testdata.json
        node_modules/lib1/package.json
        package.json
      ]>
    this "match a single negated pattern" !->
      results = multiglob.sync {mark: true} '!**/*.js'
      expect results .not.to.be.empty

      results .= sort!
      expect results .to.deep.equal <[
        bin/
        bin/script
        index.ls
        lib/
        lib/glob.coffee
        lib/match.ls
        lib/testdata.json
        lib/testdata.json.ls
        node_modules/
        node_modules/lib1/
        node_modules/lib1/LICENSE
        node_modules/lib1/README.md
        node_modules/lib1/package.json
        package.json
      ]>
    this "match multiple patterns inclusively (addition)" !->
      results = multiglob.sync '**/*.js' '*.ls'
      expect results .not.to.be.empty

      results .= sort!
      expect results .to.deep.equal <[
        index.ls
        lib/glob.js
        lib/match.js
        lib/otherlib.js
        node_modules/lib1/index.js
      ]>
    this "select previous results matching a pattern" !->
      results = multiglob.sync '**/index.*' '&node_modules/**'
      expect results .not.to.be.empty

      expect results .to.deep.equal <[
        node_modules/lib1/index.js
      ]>
    this "exclude previous results matching a pattern" !->
      results = multiglob.sync '**/index.*' '!node_modules/**'
      expect results .not.to.be.empty

      expect results .to.deep.equal <[
        index.ls
      ]>

  # Test properties.
  describe "does" as !->
    this "return an empty array when there are no matches overall" !->
      # No files should match both patterns.
      results = multiglob.sync '**/*.js' '&**/*.ls'
      expect results .to.exist.and.to.be.empty

      # The files matched by the first pattern must be excluded
      # by its own negation.
      results = multiglob.sync '**/*.js' '!**/*.js'
      expect results .to.exist.and.to.be.empty

    this "return a single instance of each match" !->
      results = multiglob.sync 'lib/*' '**/.*ls' '**/*.js'
      expect results .not.to.be.empty

      # The matches for files in `lib/` and JavaScript and LiveScript
      # files should overlap, yet only the match from `lib` should
      # have been kept.
      for file in results
        expect results.indexOf file .to.equal results.lastIndexOf file
    this "preserve match order for multiple matches" !->
      results = multiglob.sync '**/*.js' 'index.ls' 'lib/glob.*'
      expect results .not.to.be.empty

      # We expect `lib/glob.js` to come before `lib/glob.coffee`
      # and not to be its predecessor.  The `index.ls` is there
      # to make sure `glob.js` can be the last match of the first
      # pattern.
      jsIndex = results.indexOf 'lib/glob.js'
      coffeeIndex = results.indexOf 'lib/glob.coffee'
      expect jsIndex .to.be.below coffeeIndex
      expect jsIndex .not.to.be.closeTo coffeeIndex, 1

describe "multiglob.async" as !->
  beforeEach !->
    mock {}
  afterEach !->
    mock.restore!

  this "sends errors to the callback function" (done) !->
    multiglob '' (err, results) !->
      expect results .to.not.exist
      expect err .to.exist
      done!
  this "sends results to the callback function" (done) !->
    multiglob '**' (err, results) !->
      expect results .to.exist
      expect err .to.not.exist
      done!
