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
			'accounts': (callback) -> AccountManager.getAccounts(true, (err, result) -> callback(err, result))
			'categories': (callback) -> CategoryManager.getCategories(true, (err, result) -> callback(err, result))
			'payees': (callback) -> TransactionManager.getUniquePayees((err, result) -> callback(err, result))
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
			'totalCount': (callback) -> TransactionManager.getTransactionsCount((err, result) -> callback(err, result))
			'filteredCount': (callback) -> TransactionManager.getFilteredTransactionsCount(search, (err, result) -> callback(err, result))
			'data': (callback) -> TransactionManager.getFilteredTransactions(search, start, count, order, (err, result) -> callback(err, result))
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

	TransactionManager.saveTransaction(transactionId, transaction, (err) ->
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

router.post('/delete/:transactionId', auth.checkAndRefuse, (req, res) ->
	transactionId = req.params['transactionId']

	TransactionManager.deleteTransaction(transactionId, (err) ->
		res.status(if (err) then 400 else 200)
		res.end()
	)
)

module.exports = router
