express = require('express')
async = require('async')
rfr = require('rfr')
auth = rfr('./helpers/auth')
BudgetManager = rfr('./managers/budgets')
CategoryManager = rfr('./managers/categories')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res) ->
	res.render('settings/budgets/index', {
		_: {
			title: 'Settings: Budgets'
			activePage: 'settings-budgets'
		}
	})
)

router.get('/data', auth.checkAndRefuse, (req, res, next) ->
	start = parseInt(req.query['start'])
	count = parseInt(req.query['length'])
	order = req.query['order'][0]['dir']
	search = req.query['search']['value']
	activeOnly = req.query['activeOnly'] == 'true'

	async.parallel(
		{
			'totalCount': (callback) -> BudgetManager.getBudgetCount(res.locals.user, activeOnly, (err, result) -> callback(err, result))
			'filteredCount': (callback) -> BudgetManager.getFilteredBudgetCount(res.locals.user, activeOnly, search, (err, result) -> callback(err, result))
			'data': (callback) -> BudgetManager.getFilteredBudgets(res.locals.user, activeOnly, search, start, count, order, (err, result) -> callback(err, result))
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

router.get('/create', auth.checkAndRefuse, (req, res, next) ->
	CategoryManager.getCategories(res.locals.user, (err, categories) ->
		if (err)
			return next(err)

		res.render('settings/budgets/edit', {
			_: {
				title: 'Settings: Create Budget'
				activePage: 'settings-budgets'
			}
			categories: categories
		})
	)
)

router.get('/edit/:budgetId', auth.checkAndRefuse, (req, res) ->
	budgetId = req.params['budgetId']

	BudgetManager.getBudget(res.locals.user, budgetId, (err, budget) ->
		if (err or !budget)
			req.flash('error', 'Sorry, that budget couldn\'t be loaded!')
			res.writeHead(302, { Location: '/settings/budgets' })
			res.end()
			return

		CategoryManager.getCategories(res.locals.user, (err, categories) ->
			if (err)
				return next(err)

			res.render('settings/budgets/edit', {
				_: {
					title: 'Settings: Edit Budget'
					activePage: 'settings-budgets'
				},
				budget: budget
				categories: categories
			})
		)
	)
)

router.post('/edit/:budgetId', auth.checkAndRefuse, (req, res) ->
	budgetId = req.params['budgetId']
	budget = req.body

	BudgetManager.saveBudget(res.locals.user, budgetId, budget, null, (err) ->
		if (err)
			req.flash('error', 'Sorry, that budget couldn\'t be saved!')

		res.writeHead(302, { Location: '/settings/budgets' })
		res.end()
	)
)

router.post('/clone', auth.checkAndRefuse, (req, res) ->
	startDate  = req.body['startDate']
	endDate  = req.body['endDate']
	budgetIds  = req.body['budgetIds[]']

	BudgetManager.cloneBudgets(res.locals.user, budgetIds, startDate, endDate, (err) ->
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

module.exports = router
