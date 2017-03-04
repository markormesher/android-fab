LocalPassportStrategy = require('passport-local').Strategy
rfr = require('rfr')
auth = rfr('./helpers/auth')
UserManager = rfr('./managers/users')

module.exports = (passport) ->

	passport.serializeUser((user, callback) ->
		delete user['password']
		user['emailHash'] = auth.md5(user['email'].trim().toLowerCase())
		callback(null, JSON.stringify(user))
	)

	passport.deserializeUser((user, callback) -> callback(null, JSON.parse(user)))

	passport.use(new LocalPassportStrategy(
		{ passReqToCallback: true },
		(req, username, password, callback) ->
			UserManager.getUserForAuth(username, password, (err, result) ->
				if (err) then return callback(err)
				if (!result)
					req.flash('error', 'Invalid email/password combination!')
					req.flash('data-username', username)
					return callback(null, false)
				return callback(null, result)
			)
	))
