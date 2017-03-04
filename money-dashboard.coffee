path = require('path')
express = require('express')
bodyParser = require('body-parser')
coffeeMiddleware = require('coffee-middleware')
sassMiddleware = require('node-sass-middleware')
cookieParser = require('cookie-parser')
session = require('cookie-session')
flash = require('express-flash')
passport = require('passport')

rfr = require('rfr')
auth = rfr('./helpers/auth')
secrets = rfr('./secrets.json')
pJson = rfr('./package.json')
constants = rfr('./constants.json')

app = express()

# form body content
app.use(bodyParser.urlencoded({ extended: false }));

# coffee script and sass conversion
app.use(coffeeMiddleware({
	src: __dirname + '/assets'
	compress: true
}))
app.use(sassMiddleware({
	src: __dirname + '/assets/'
	dest: __dirname + '/public'
	outputStyle: 'compressed'
}))

# cookies and sessions
app.use(cookieParser(secrets.COOKIE_KEY))
app.use(session({
	name: 'session'
	secret: secrets.SESSION_KEY
}))
app.use((req, res, next) ->
	# update the session every minute to re-set expiration timer
	req.session.nowInMinutes = Date.now() / (60 * 1000)
	next()
)

# flash, with customisation for data
app.use(flash())
app.use((req, res, next) ->
	if (req.session.flash)
		req.session.flash.data = {}
		for key, value of req.session.flash
			if (key.substring(0, 5) == 'data-')
				req.session.flash.data[key.substring(5)] = value[0]
	next()
)

# auth
rfr('./helpers/passport-config')(passport)
app.use(passport.initialize())
app.use(passport.session())
app.use(auth.checkOnly)

# helpers
app.locals.formatters = rfr('./helpers/formatters')
app.locals.constants = constants

# routes
routes = {
	'': rfr('./controllers/dashboard')
	'auth': rfr('./controllers/auth')
	'transactions': rfr('./controllers/transactions')
	'settings/accounts': rfr('./controllers/settings/accounts')
	'settings/budgets': rfr('./controllers/settings/budgets')
	'settings/categories': rfr('./controllers/settings/categories')
};

for stem, file of routes
	app.use('/' + stem, file)

app.use('/favicon.ico', (req, res) -> res.end())

# views
app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'pug')
app.use(express.static(path.join(__dirname, 'public')))

# error handlers
app.use((req, res, next) ->
	err = new Error('Not Found')
	err.status = 404
	next(err)
)

app.use((error, req, res) ->
	res.status(error.status || 500)
	res.render('core/error', {
		_: {
			title: error.status + ': ' + error.message
		}
		message: error.message
		status: error.status || 500
		error: if app.get('env') == 'development' then error
	})
)

# go!
app.listen(constants.port)
console.log("#{pJson.name} is listening on port #{constants.port}")
