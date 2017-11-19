async = require('async')
rfr = require('rfr')
constants = rfr('./constants')
UserManager = rfr('./managers/users')
ProfileManager = rfr('./managers/profiles')

exports = {

	userHasSettings: (user) -> user['settings'] && user['settings']['__version'] == constants['settingsVersion']
	userHasProfiles: (user) -> user['profiles'] && user['activeProfile'] && false

	shouldReloadUser: (user) -> !exports.userHasSettings(user) || !exports.userHasProfiles(user)

	checkOnly: (req, res, next) ->
		user = req.user
		res.locals.user = user || null
		currentActiveProfile = if (user) then user['activeProfile'] || null else null
		if (user && exports.shouldReloadUser(user))
			async.parallel(
				{
					'profiles': (c) -> ProfileManager.getProfiles(user.id, c)
					'settings': (c) -> UserManager.getUserSettings(user.id, c)
				},
				(err, results) ->
					if (err) then return next(err)
					user['profiles'] = results['profiles']
					user['settings'] = results['settings']

					if (!currentActiveProfile || !user['profiles'].some((x) -> x.id == currentActiveProfile.id))
						user['activeProfile'] = user['profiles'][0]

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
