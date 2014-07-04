require('coffee-script').register()
{Build} = require 'web-build-tools'
{Intercessor} = require 'intercessor'
{sh, cmd} = Build
fs = require 'fs'

projectPaths =
  [
    'intercessor-example'
    'nechifor-index'
  ].map (n) -> '/home/p/pro/' + n

apps = []

b = new Build task, {}, (->),
  makeBuild: (cb) ->
    sh """
      rm -fr build
      mkdir -p build build/views build/s/css
      cp -r views/* build/views
    """, cb

  makeStyle: (cb) ->
    inFile = __dirname + '/styles/index.styl'
    Build.stylus 'build/s/css/site.css', inFile, {}, cb

  compile: (cb) ->
    i = 0
    next = ->
      return cb() if i >= projectPaths.length
      intercessor = new Intercessor projectPaths[i], 'build'
      intercessor.standalone = false
      intercessor.build (err) ->
        return cb err if err
        apps.push intercessor.app
        i++
        next()
    next()

  compileCs: (cb) ->
    sh """
      coffee --compile --bare --output build/app app/Site.coffee
    """, cb

  writeAppJs: (cb) ->
    fs.writeFileSync 'build/app/app.js', """
      var Site = require('./Site');
      var apps = #{JSON.stringify apps};
      var site = new Site(apps);
      site.start(function () {});
    """
    cb()

  build: (cb) ->
    b.run ['makeBuild', 'makeStyle', 'compile', 'compileCs', 'writeAppJs']
    cb()

b.makePublic
  build: 'Build it all.'
