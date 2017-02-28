express = require('express')
passport = require('passport')
router = express.Router()

router.get('/', (req, res) -> res.redirect('/auth/login'))

router.get('/login', (req, res) ->
	res.render('auth/login', {
		_: {
			title: 'Login'
			activePage: 'auth'
		}
	})
)

router.post('/login', passport.authenticate('local', {
	successRedirect: '/'
	failureRedirect: '/auth/login'
}))

router.get('/logout', (req, res) ->
	req.logout()
	req.flash('info', 'You have been logged out.')
	res.redirect('/auth/login')
)

module.exports = router
