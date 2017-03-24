LocalPassportStrategy = require('passport-local').Strategy
rfr = require('rfr')
hashing = rfr('./helpers/hashing')
UserManager = rfr('./managers/users')

module.exports = (passport) ->

	passport.serializeUser((user, callback) ->
		delete user['password']
		user['emailHash'] = hashing.md5(user['email'].trim().toLowerCase())
		callback(null, JSON.stringify(user))
	)

	passport.deserializeUser((user, callback) -> callback(null, JSON.parse(user)))

	passport.use(new LocalPassportStrategy(
		{ passReqToCallback: true },
		(req, username, password, callback) ->
			UserManager.getUserForAuth(username, password, (err, user) ->
				if (err) then return callback(err)
				if (!user)
					req.flash('error', 'Invalid email/password combination!')
					req.flash('data-username', username)
					callback(null, false)
				else
					callback(null, user)
			)
	))
