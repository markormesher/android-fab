express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
AccountManager = rfr('./managers/accounts')
StatisticsManager = rfr('./managers/statistics')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res, next) ->
	AccountManager.getAccounts(req.user, true, (err, accounts) ->
		if (err) then return next(err)
		res.render('reports/balance-history/index', {
			_: {
				title: 'Reports: Balance History'
				activePage: 'reports-balance-history'
			}
			accounts: accounts
		})
	)
)

router.post('/data', auth.checkAndRefuse, (req, res, next) ->
	start = new Date(req.body.start)
	end = new Date(req.body.end)
	accounts = req.body['accounts[]']

	StatisticsManager.getBalanceHistory(req.user, start, end, accounts, (err, history) ->
		if (err) then return next(err)
		res.json(history)
	)
)

module.exports = router
