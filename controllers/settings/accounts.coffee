express = require('express')
async = require('async')
rfr = require('rfr')
auth = rfr('./helpers/auth')
AccountManager = rfr('./managers/accounts')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res) ->
	res.render('settings/accounts/index', {
		_: {
			title: 'Settings: Accounts'
			activePage: 'settings-accounts'
		}
	})
)

router.get('/data', auth.checkAndRefuse, (req, res, next) ->
	search = req.query['search']['value']

	async.parallel(
		{
			'totalCount': (callback) -> AccountManager.getAccountsCount(res.locals.user, (err, result) -> callback(err, result))
			'filteredCount': (callback) -> AccountManager.getFilteredAccountsCount(res.locals.user, search, (err, result) -> callback(err, result))
			'data': (callback) -> AccountManager.getFilteredAccounts(res.locals.user, search, (err, result) -> callback(err, result))
		},
		(err, results) ->
			if (err)
				return next(err)

			res.json({
				recordsTotal: results.totalCount
				recordsFiltered: results.filteredCount
				data: results.data
			})
	)
)

router.post('/edit/:accountId', auth.checkAndRefuse, (req, res) ->
	accountId = req.params['accountId']
	account = req.body

	AccountManager.saveAccount(res.locals.user, accountId, account, (err) ->
		if (err) then console.log(err)
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/delete/:accountId', auth.checkAndRefuse, (req, res) ->
	accountId = req.params['accountId']

	AccountManager.deleteAccount(res.locals.user, accountId, (err) ->
		if (err) then console.log(err)
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/reorder/:accountId', auth.checkAndRefuse, (req, res) ->
	accountId = req.params['accountId']
	direction = req.body['direction']

	AccountManager.reorderAccount(res.locals.user, accountId, direction, (err) ->
		if (err) then console.log(err)
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

module.exports = router
