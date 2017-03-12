express = require('express')
async = require('async')
rfr = require('rfr')
auth = rfr('./helpers/auth')
CategoryManager = rfr('./managers/categories')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res) ->
	res.render('settings/categories/index', {
		_: {
			title: 'Settings: Categories'
			activePage: 'settings-categories'
		},
	})
)

router.get('/data', auth.checkAndRefuse, (req, res, next) ->
	start = parseInt(req.query['start'])
	count = parseInt(req.query['length'])
	order = req.query['order'][0]['dir']
	search = req.query['search']['value']

	async.parallel(
		{
			'totalCount': (callback) -> CategoryManager.getCategoriesCount(res.locals.user, (err, result) -> callback(err, result))
			'filteredCount': (callback) -> CategoryManager.getFilteredCategoriesCount(res.locals.user, search, (err, result) -> callback(err, result))
			'data': (callback) -> CategoryManager.getFilteredCategories(res.locals.user, search, start, count, order, (err, result) -> callback(err, result))
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

router.post('/edit/:categoryId', auth.checkAndRefuse, (req, res) ->
	categoryId = req.params['categoryId']
	category = req.body

	CategoryManager.saveCategory(res.locals.user, categoryId, category, (err) ->
		if (err) then console.log(err)
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/delete/:categoryId', auth.checkAndRefuse, (req, res) ->
	categoryId = req.params['categoryId']

	CategoryManager.deleteCategory(res.locals.user, categoryId, (err) ->
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/set-summary-visibility/:categoryId', auth.checkAndRefuse, (req, res, next) ->
	categoryId = req.params['categoryId']
	value = req.body['value']

	CategoryManager.setSummaryVisibility(res.locals.user, categoryId, value, (err) ->
		if (err) then return next(err)
		res.end()
	)
)

module.exports = router
