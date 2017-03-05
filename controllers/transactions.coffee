express = require('express')
async = require('async')
rfr = require('rfr')
auth = rfr('./helpers/auth')
AccountManager = rfr('./managers/accounts')
CategoryManager = rfr('./managers/categories')
TransactionManager = rfr('./managers/transactions')
router = express.Router()

router.get('/', auth.checkAndRefuse, (req, res, next) ->
	async.parallel(
		{
			'accounts': (callback) -> AccountManager.getAccounts(res.locals.user, true, (err, result) -> callback(err, result))
			'categories': (callback) -> CategoryManager.getCategories(res.locals.user, true, (err, result) -> callback(err, result))
			'payees': (callback) -> TransactionManager.getUniquePayees(res.locals.user, (err, result) -> callback(err, result))
		},
		(err, results) ->
			if (err)
				return next(err)

			res.render('transactions/index', {
				_: {
					title: 'Transactions'
					activePage: 'transactions'
				}
				accounts: results.accounts
				categories: results.categories
				payees: results.payees
			})
	)
)

router.get('/data', auth.checkAndRefuse, (req, res, next) ->
	start = parseInt(req.query['start'])
	count = parseInt(req.query['length'])
	order = req.query['order'][0]['dir']
	search = req.query['search']['value']

	async.parallel(
		{
			'totalCount': (callback) -> TransactionManager.getTransactionsCount(res.locals.user, (err, result) -> callback(err, result))
			'filteredCount': (callback) -> TransactionManager.getFilteredTransactionsCount(res.locals.user, search, (err, result) -> callback(err, result))
			'data': (callback) -> TransactionManager.getFilteredTransactions(res.locals.user, search, start, count, order, (err, result) -> callback(err, result))
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

router.post('/edit/:transactionId', auth.checkAndRefuse, (req, res) ->
	transactionId = req.params['transactionId']
	transaction = req.body

	TransactionManager.saveTransaction(res.locals.user, transactionId, transaction, (err) ->
		if (err) then console.log(err)
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/delete/:transactionId', auth.checkAndRefuse, (req, res) ->
	transactionId = req.params['transactionId']

	TransactionManager.deleteTransaction(res.locals.user, transactionId, (err) ->
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

module.exports = router
