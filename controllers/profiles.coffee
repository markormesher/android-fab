express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
router = express.Router()

router.get('/select/:profileId', auth.checkAndRefuse, (req, res, next) ->
	profileId = req.params['profileId']
	user = res.locals.user
	newProfile = user.profiles.filter((x) -> x.id == profileId)
	if (newProfile.length == 1)
		delete user.activeProfile
		user.activeProfile = newProfile[0]
		req.login(user, (err) ->
			if (err) then return next(err)
			res.redirect(req.get('Referrer') || '/')
		)
	else
		req.flash('error', 'Sorry, that profile couldn\'t be selected.')
		res.redirect(req.get('Referrer') || '/')
)

module.exports = router
