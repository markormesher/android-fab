express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
AccountManager = rfr('./managers/accounts')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res, next) ->
	AccountManager.getAccounts(true, (err, accounts) ->
		if (err)
			return next(err)

		res.render('settings/accounts/index', {
			_: {
				title: 'Settings: Accounts'
				activePage: 'settings-accounts'
			},
			accounts: accounts
		})
	)
)

router.get('/create', auth.checkAndRefuse, (req, res) ->
	res.render('settings/accounts/edit', {
		_: {
			title: 'Settings: Create Account'
			activePage: 'settings-accounts'
		}
	})
)

router.get('/edit/:accountId', auth.checkAndRefuse, (req, res) ->
	accountId = req.params['accountId']

	AccountManager.getAccount(accountId, (err, account) ->
		if (err or !account)
			req.flash('error', 'Sorry, that account couldn\'t be loaded!')
			res.writeHead(302, { Location: '/settings/accounts' })
			res.end()
			return

		res.render('settings/accounts/edit', {
			_: {
				title: 'Settings: Edit Account'
				activePage: 'settings-accounts'
			},
			account: account
		})
	)
)

router.post('/edit/:accountId', auth.checkAndRefuse, (req, res) ->
	accountId = req.params['accountId']
	account = req.body

	AccountManager.saveAccount(accountId, account, (err) ->
		if (err)
			req.flash('error', 'Sorry, that account couldn\'t be saved!')

		res.writeHead(302, { Location: '/settings/accounts' })
		res.end()
	)
)

router.post('/reorder', auth.checkAndRefuse, (req, res) ->
	orders = req.body
	keys = []
	for k, v of orders
		keys.push(k)

	setOrder = (i) ->
		key = keys[i]
		AccountManager.setAccountDisplayOrder(key, orders[key], (err) ->
			if (err)
				next(err)
			else
				if (i < keys.length - 1)
					setOrder(i + 1)
				else
					res.end()
		)

	if (keys.length > 0)
		setOrder(0)
	else
		res.end()
)

module.exports = router
