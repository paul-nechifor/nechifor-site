{Build} = require 'web-build-tools'
{Intercessor} = require 'intercessor'
{sh, cmd} = Build
async = require 'async'
gulp = require 'gulp'
fs = require 'fs'

class App
  constructor: (@root, @opts) ->
    if typeof @opts is 'string'
      @name = @opts
    else if @opts instanceof Array
      @name = @opts[0]
      @customRoot = @opts[1]
    @path = @root + '/' + @name

  build: (cb) ->
    @intercessor = new Intercessor @path, 'build'
    @intercessor.customRoot = @customRoot if @customRoot
    @intercessor.standalone = false
    @intercessor.build cb

getApps = ->
  list = [
    'intercessor-example'
    'git-visualization'
    'sidrem'
    'circuits'
    ['nechifor-blog', 'blog']
    'nechifor-index'
  ]
  projectsRoot = '/home/p/pro'
  list.map (e) -> new App projectsRoot, e

prepareBuild = (cb) ->
  sh """
    rm -fr build
    mkdir -p build build/views build/s/css
    cp -r views/* build/views
    coffee --compile --bare --output build/app app/Site.coffee
  """, cb

makeStyle = (cb) ->
  inFile = __dirname + '/styles/index.styl'
  Build.stylus 'build/s/css/site.css', inFile, {}, cb

compileAll = (apps, cb) ->
  getAppInfo = (app, cb) ->
    app.build (err) ->
      return cb err if err
      cb null, app.intercessor.app
  async.map apps, getAppInfo, cb

writeAppJs = (appInfos, rootProject, cb) ->
  fs.writeFileSync 'build/app/app.js', """
    var Site = require('./Site');
    var apps = #{JSON.stringify appInfos};
    var site = new Site(apps, #{JSON.stringify rootProject});
    site.start(function () {});
  """
  cb()

gulp.task 'default', (cb) ->
  apps = getApps()
  rootProject = 'nechifor-index'
  prepareBuild ->
    makeStyle ->
      compileAll apps, (err, appInfos) ->
        throw err if err
        writeAppJs appInfos, rootProject, cb
