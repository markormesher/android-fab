express = require('express')
rfr = require('rfr')
auth = rfr('./helpers/auth')
BudgetManager = rfr('./managers/budgets')
CategoryManager = rfr('./managers/categories')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res, next) ->
	activeOnly = !req.query.activeOnly || req.query.activeOnly == 'yes'
	BudgetManager.getBudgets(res.locals.user, activeOnly, (err, budgets) ->
		if (err)
			return next(err)

		res.render('settings/budgets/index', {
			_: {
				title: 'Settings: Budgets'
				activePage: 'settings-budgets'
			},
			budgets: budgets
			activeOnly: activeOnly
		})
	)
)

router.get('/create', auth.checkAndRefuse, (req, res, next) ->
	CategoryManager.getCategories(res.locals.user, true, (err, categories) ->
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

		CategoryManager.getCategories(res.locals.user, true, (err, categories) ->
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

	BudgetManager.saveBudget(res.locals.user, budgetId, budget, (err) ->
		if (err)
			req.flash('error', 'Sorry, that budget couldn\'t be saved!')

		res.writeHead(302, { Location: '/settings/budgets' })
		res.end()
	)
)

module.exports = router
