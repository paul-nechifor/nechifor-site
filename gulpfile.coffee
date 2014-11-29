async = require 'async'
fs = require 'fs'
gitRequire = require 'git-require'
gulp = require 'gulp'
{Build} = require 'web-build-tools'
{Intercessor} = require 'intercessor'
{sh, cmd} = Build

process.env.GIT_REQUIRE_DIR or= __dirname + '/projects'

analyticsCode = do ->
  try
    fs.readFileSync('private/analyticsCode', 'utf8').trim()
  catch e
    null

class App
  constructor: (@path, @customRoot) ->

  build: (cb) ->
    @preparePackage (err) =>
      return cb err if err
      @buildIntercessor cb

  preparePackage: (cb) ->
    sh """
      cd '#{@path}'
      npm install
      npm run intercessor-make
    """, cb

  buildIntercessor: (cb) ->
    @intercessor = new Intercessor @path, 'build'
    @intercessor.customRoot = @customRoot if @customRoot
    @intercessor.standalone = false
    @intercessor.analyticsCode = analyticsCode
    @intercessor.build cb

# TODO Instead of this list, set tags on nechifor-info to ge this.
appList = [
  'check-your-privilege'
  'chess-puzzles'
  'circuits'
  'git-visualization'
  'horoscop'
  'identitate-falsa'
  'intercessor-example'
  'jpeg-enricher'
  'papers'
  'sibf'
  'sidrem'
  'webgl-demos'
  ['nechifor-blog', 'blog']
  ['pseudoromanian', 'pseudoromana']
  'nechifor-index'
]

getApps = (cb) ->
  gitRequire.repos __dirname, getProjectsConfig(), (err, repos) ->
    return cb err if err
    cb null, appList.map (elem) ->
      if typeof elem is 'string'
        name = elem
      else
        [name, customRoot] = elem
      new App repos[name].dir, customRoot

prepareBuild = (cb) ->
  sh """
    rm -fr build
    mkdir -p build build/views build/s/css
    cp -r views/* build/views
    coffee -cbo build/app app/Site.coffee
  """, cb

makeStyle = (cb) ->
  inFile = __dirname + '/styles/index.styl'
  Build.stylus 'build/s/css/site.css', inFile, {}, cb

compileAll = (apps, cb) ->
  getAppInfo = (app, cb) ->
    console.log 'Building', app.path
    app.build (err) ->
      return cb err if err
      cb null, app.intercessor.app
  async.mapSeries apps, getAppInfo, cb

writeAppJs = (appInfos, rootProject, cb) ->
  fs.writeFileSync 'build/app/app.js', """
    var Site = require('./Site');
    var apps = #{JSON.stringify appInfos};
    var site = new Site(apps, #{JSON.stringify rootProject});
    site.start(function () {});
  """
  cb()

loadInfo = (cb) ->
  repos = 'nechifor-info': 'git@github.com:paul-nechifor/nechifor-info'
  config = dir: null, repos: repos
  gitRequire.install __dirname, config, cb

getProjectsConfig = ->
  repos = {}
  for p in appList
    name = if typeof(p) is 'string' then p else p[0]
    repos[name] = 'git@github.com:paul-nechifor/' + name
  repos
  dir: 'projects', repos: repos

gulp.task 'projects', (cb) ->
  loadInfo (err) ->
    return cb err if err
    gitRequire.install __dirname, getProjectsConfig(), (err, repos) ->
      return cb err if err
      cb()

gulp.task 'default', (cb) ->
  getApps (err, apps) ->
    return cb err if err
    prepareBuild ->
      makeStyle ->
        compileAll apps, (err, appInfos) ->
          return cb err if err
          writeAppJs appInfos, 'nechifor-index', cb
