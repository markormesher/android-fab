express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
StatisticsManager = rfr('./managers/statistics')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res) ->
	res.render('reports/balance-history/index', {
		_: {
			title: 'Reports: Balance History'
			activePage: 'reports-balance-history'
		}
	})
)

router.get('/data', auth.checkAndRefuse, (req, res, next) ->
	start = new Date(req.query.start)
	end = new Date(req.query.end)
	StatisticsManager.getBalanceHistory(res.locals.user, start, end, (err, history) ->
		if (err)
			return next(err)
		res.json(history)
	)
)

module.exports = router
