require('coffee-script').register()
{Build} = require 'web-build-tools'
{Intercessor} = require 'intercessor'
{sh, cmd} = Build
fs = require 'fs'

projectsRoot = '/home/p/pro'
projects = [
  'intercessor-example'
  'git-visualization'
  'sidrem'
  'circuits'
  'nechifor-index'
]
rootProject = 'nechifor-index'

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
      return cb() if i >= projects.length
      projectPath = projectsRoot + '/' + projects[i]
      intercessor = new Intercessor projectPath, 'build'
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
      var site = new Site(apps, #{JSON.stringify rootProject});
      site.start(function () {});
    """
    cb()

  build: (cb) ->
    b.run ['makeBuild', 'makeStyle', 'compile', 'compileCs', 'writeAppJs']
    cb()

b.makePublic
  build: 'Build it all.'
