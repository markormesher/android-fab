express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
UserManager = rfr('./managers/users')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res) -> res.redirect('/users/profile'))

router.get('/profile', auth.checkAndRefuse, (req, res) ->
	res.render('users/profile', {
		_: {
			title: 'Your Profile'
			activePage: 'none'
		}
	})
)

router.post('/profile', auth.checkAndRefuse, (req, res, next) ->
	userId = res.locals.user.id
	user = req.body

	UserManager.saveUser(userId, user, (err, updatedUser) ->
		if (err)
			if (err == 'invalid-password')
				req.flash('error', 'Your new password is not valid.')
				res.redirect('/users/profile')
			else if (err == 'bad-password')
				req.flash('error', 'You current password was not correct.')
				res.redirect('/users/profile')
			else
				return next(err)
		else
			req.flash('success', 'Your details have been updated.')
			req.login(updatedUser, (err) ->
				if (err) then return next(err)
				res.redirect('/users/profile')
			)
	)
)

module.exports = router
