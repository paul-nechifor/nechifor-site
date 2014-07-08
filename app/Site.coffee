express = require 'express'
http = require 'http'
path = require 'path'

module.exports = class Site
  constructor: (@apps, @rootProject) ->
    @express = null
    @server = null
    @port = 3000

  start: (cb) ->
    @express = express()
    @configure()
    @createServer cb

  stop: ->

  configure: ->
    e = @express

    e.set 'port', @port
    e.set 'views', __dirname + '/../views'
    e.set 'view engine', 'jade'

    e.use express.favicon()
    e.use express.urlencoded()
    e.use express.json()
    e.use express.methodOverride()
    e.use '/s', express.static __dirname + '/../s'
    @bindLocals()
    e.use (req, res, next) =>
      if req.url is '/'
        req.url += @rootProject
      next()
    e.use e.router
    @registerRoutes()

  bindLocals: ->
    for app in @apps
      @bindLocalsFor app
    return

  bindLocalsFor: (app) ->
    @express.use app.rootHref, (req, res, next) ->
      res.locals.app = app
      next()
      return

  registerRoutes: ->
    for app in @apps
      @registerRoutesFor app
    return

  registerRoutesFor: (app) ->
    if app.useHtml
      @express.use app.rootHref, express.static __dirname + '/../html/' + app.id

    return unless app.useAppLogic
    appLogic = require path.resolve "#{__dirname}/#{app.id}/index"

    for route in app.routes
      [verb, routePath, funcName] = route
      loc = app.rootHref + if routePath is '/' then '' else routePath
      @express[verb] loc, appLogic.routes[funcName]
    return

  createServer: (cb) ->
    @server = http.createServer @express
    @server.listen @port, =>
      console.log 'server listening on', @port
      cb()
