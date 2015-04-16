express = require('express')
path = require('path')
favicon = require('serve-favicon')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
routes = require('./routes/index')
sass = require('node-sass')
sassMiddleware = require('node-sass-middleware');

app = express()
# view engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'
# uncomment after placing your favicon in /public
app.use(favicon(__dirname + '/public/images/coffee-favicon.png'));
app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()


srcPath = __dirname + '/sass'
destPath = __dirname + '/public'
app.use(sassMiddleware({
       src: srcPath,
       dest: destPath,
       debug: true,
   }));



app.use express.static(path.join(__dirname, 'public'))
app.use '/', routes.index
app.use '/post/new', routes.newPost
# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error('Not Found')
  err.status = 404
  next err
  return
# error handlers
# development error handler
# will print stacktrace
if app.get('env') == 'development'
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render 'error',
      message: err.message
      error: err
    return
# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render 'error',
    message: err.message
    error: {}
  return
module.exports = app
