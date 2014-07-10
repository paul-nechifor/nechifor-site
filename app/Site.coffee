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

    @importAppLogics()

    express.logger.token 'date', -> new Date().toISOString()
    e.use express.logger ':date :remote-addr :method :url :status :response-time'

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
    @registerPreRouters()
    e.use e.router
    @registerRoutes()

  importAppLogics: ->
    for app in @apps
      if app.useAppLogic
        app.appLogic = require path.resolve "#{__dirname}/#{app.id}/index"
    return

  bindLocals: ->
    for app in @apps
      @bindLocalsFor app
    return

  bindLocalsFor: (app) ->
    @express.use app.rootHref, (req, res, next) ->
      res.locals.app = app
      next()
      return

  registerPreRouters: ->
    for app in @apps
      continue unless app.useAppLogic
      c = app.appLogic.changers
      if c and c.preRouter
        c.preRouter @express, app
    return

  registerRoutes: ->
    for app in @apps
      @registerRoutesFor app
    return

  registerRoutesFor: (app) ->
    if app.useHtml
      @express.use app.rootHref, express.static __dirname + '/../html/' + app.id
    if app.staticApp
      @express.use app.rootHref, express.static __dirname + '/../sa/' + app.id

    return unless app.useAppLogic

    for route in app.routes
      [verb, routePath, funcName] = route
      loc = app.rootHref + if routePath is '/' then '' else routePath
      @express[verb] loc, app.appLogic.routes[funcName]
    return

  createServer: (cb) ->
    @server = http.createServer @express
    @server.listen @port, =>
      console.log 'server listening on', @port
      cb()
