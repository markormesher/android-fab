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
			req.flash('success', "Switched to #{user.activeProfile.name}.")
			res.redirect('/')
		)
	else
		req.flash('error', 'Sorry, that profile couldn\'t be selected.')
		res.redirect('/')
)

module.exports = router
