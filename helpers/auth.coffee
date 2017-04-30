crypto = require('crypto')
rfr = require('rfr')
constants = rfr('./constants')
hashing = rfr('./helpers/hashing')
UserManager = rfr('./managers/users')

exports = {

	userHasSetting: (user) -> user['settings'] && user['settings']['__version'] == constants['settingsVersion']

	checkOnly: (req, res, next) ->
		user = req.user
		res.locals.user = user || null
		if (user && !exports.userHasSetting(user))
			UserManager.getUserSettings(user.id, (err, settings) ->
				if (err) then return next(err)
				user['settings'] = settings
				req.login(user, (err) -> next(err))
			)
		else
			next()

	checkAndRefuse: (req, res, next) ->
		if (req.user)
			exports.checkOnly(req, res, next)
		else
			req.flash('error', 'You need to log in first.')
			res.redirect('/auth/login')
}

module.exports = exports
