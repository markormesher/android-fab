express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
StatisticsManager = rfr('./managers/statistics')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res, next) ->
	res.render('reports/budget-performance/index', {
		_: {
			title: 'Reports: Budget Performance'
			activePage: 'reports-budget-performance'
		}
	})
)

router.post('/data', auth.checkAndRefuse, (req, res, next) ->
	start = new Date(req.body.start)
	end = new Date(req.body.end)

	StatisticsManager.getBudgetPerformance(req.user, start, end, (err, history) ->
		if (err) then return next(err)
		res.json(history)
	)
)

module.exports = router
