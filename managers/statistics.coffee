async = require('async')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')
formatters = rfr('./helpers/formatters')
BudgetManager = rfr('./managers/budgets')

manager = {

	getActiveAccountBalances: (user, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT account.id AS account_id, account.name AS account_name, account.type AS account_type, SUM(transaction.amount) AS balance
			FROM transaction LEFT JOIN account ON transaction.account_id = account.id
			WHERE account.active = 1 AND account.owner = ?
			GROUP BY transaction.account_id ORDER BY account.display_order ASC;
			"""
			user.id,
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				if (results) then return callback(null, results)
				callback(null, [])
		))


	getCurrentBudgets: (user, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT budget.*, category.name AS category, COALESCE((
				SELECT SUM(transaction.amount)
				FROM transaction
				WHERE transaction.category_id = budget.category_id
				AND transaction.effective_date >= budget.start_date AND transaction.effective_date <= budget.end_date
			), 0) * -1 AS spend
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND budget.start_date <= DATE(NOW()) AND budget.end_date >= DATE(NOW())
			ORDER BY budget.start_date DESC, category.name ASC;
			"""
			user.id,
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				output = {
					budgets: {}
					bills: {}
				}
				for r in results
					periodType = BudgetManager.getBudgetPeriodType(r.start_date, r.end_date)
					if (!output[r.type + 's'][periodType])
						output[r.type + 's'][periodType] = []
					output[r.type + 's'][periodType].push(r)
				callback(null, output)
		))


	getAlerts: (user, callback) ->
		async.parallel(
			[
				(c) -> mysql.getConnection((conn) ->
					conn.query(
						"""
						SELECT category.name AS category_name, COALESCE(SUM(transaction.amount), 0) AS balance
						FROM transaction JOIN category ON transaction.category_id = category.id
						WHERE transaction.owner = ? AND category.type = 'memo'
						GROUP BY category.name;
						"""
						[user.id],
						(err, results) ->
							conn.release()
							if (err) then return c(err)
							alerts = []
							for r in results
								if (r['balance'] != 0)
									alerts.push(r['category_name'] + ' balance is ' + formatters.formatCurrency(r['balance']) + '.')
							c(null, alerts)
					)
				)
			],
			(err, results) ->
				alerts = []
				for result in results
					for alert in result
						alerts.push(alert)
				callback(err, alerts)
		)


	getSummaryData: (user, startDate, endDate, callback) ->
		async.parallel(
			{
				'categorySums': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT SUM(transaction.amount) AS balance, category.id AS categoryId, category.name AS categoryName, category.summary_visibility AS summaryVisibility
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE transaction.owner = ? AND category.summary_visibility IS NOT NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?
					GROUP BY category.id;
					"""
					[user.id, startDate, endDate],
					(err, results) ->
						conn.release()
						if (err) then return c(err)
						c(null, results)
				))
				'totalFlow': (c) -> mysql.getConnection((conn) -> conn.query(
					'SELECT COALESCE(SUM(amount), 0) AS balance FROM transaction WHERE transaction.owner = ? AND effective_date >= ? AND effective_date <= ?;',
					[user.id, startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
				'otherIn': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT COALESCE(SUM(transaction.amount), 0) AS balance
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE transaction.owner = ? AND amount > 0 AND category.summary_visibility IS NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?;
					"""
					[user.id, startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
				'otherOut': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT COALESCE(SUM(transaction.amount), 0) AS balance
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE transaction.owner = ? AND amount < 0 AND category.summary_visibility IS NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?;
					"""
					[user.id, startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
			},
			(err, results) ->
				if (err) then return callback(err)

				output = {}

				# totals
				output.totalFlow = results['totalFlow']
				output.otherIn = results['otherIn']
				output.otherOut = results['otherOut']

				# category balances
				output.income = []
				output.expense = []

				for result in results['categorySums']
					if (result['summaryVisibility'] == 'in' || (result['summaryVisibility'] == 'both' && result['balance'] > 0))
						output.income.push(result)
					if (result['summaryVisibility'] == 'out' || (result['summaryVisibility'] == 'both' && result['balance'] < 0))
						output.expense.push(result)

				output.income.sort((a, b) -> return b['balance'] - a['balance'])
				output.expense.sort((a, b) -> return a['balance'] - b['balance'])

				callback(null, output)
		)


	getBalanceHistory: (user, start, end, accounts, callback) ->
		if (user.settings['report_bal_history_settings_date_display_mode'] == 'effective')
			dateField = 'effective_date'
		else
			dateField = 'transaction_date'

		async.waterfall(
			[
				# initial date and balance
				(c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT
						COALESCE(SUM(amount), 0) AS balance,
						GREATEST(?, (SELECT MIN(#{dateField}) FROM transaction WHERE owner = ?)) AS initial_date
					FROM transaction
					WHERE #{dateField} <= GREATEST(?, (SELECT MIN(#{dateField}) FROM transaction WHERE owner = ?)) AND owner = ? AND account_id IN (?);
					"""
					[start, user.id, start, user.id, user.id, accounts]
					(err, results) ->
						conn.release()
						if (err) then return c(err)
						c(null, results[0])
				))

				# historical balance
				(initial, c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT #{dateField}, COALESCE(SUM(amount), 0) AS balance
					FROM transaction
					WHERE #{dateField} > ? AND #{dateField} <= ? AND owner = ? AND account_id IN (?)
					GROUP BY #{dateField} ORDER BY #{dateField} ASC;
					"""
					[initial['initial_date'], end, user.id, accounts]
					(err, results) ->
						conn.release()
						if (err) then return c(err)
						c(null, {
							initial: initial,
							history: results
						})
				))
			]
			(err, results) ->
				if (err) then return callback(err)

				# start date might be overwritten if it is before the earliest transaction
				start = results['initial']['initial_date']

				initialBalance = results['initial']['balance']
				high = initialBalance
				highDate = start
				low = initialBalance
				lowDate = start

				lastBalance = initialBalance
				output = { history: [] }
				output['history'].push({ date: start, balance: initialBalance })

				for row in results['history']
					lastBalance += row['balance']
					output['history'].push({ date: new Date(row[dateField]), balance: lastBalance })

					if (lastBalance > high)
						high = lastBalance
						highDate = new Date(row[dateField])

					if (lastBalance < low)
						low = lastBalance
						lowDate = new Date(row[dateField])

				output['start'] = initialBalance
				output['end'] = lastBalance
				output['high'] = high
				output['highDate'] = highDate
				output['low'] = low
				output['lowDate'] = lowDate

				callback(null, output)
		)


	getBudgetPerformance: (user, start, end, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT budget.*, category.name AS category, COALESCE((
				SELECT SUM(transaction.amount)
				FROM transaction
				WHERE transaction.category_id = budget.category_id
				AND transaction.effective_date >= budget.start_date AND transaction.effective_date <= budget.end_date
			), 0) * -1 AS spend
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND (NOT budget.end_date < ? AND NOT budget.start_date > ?)
			GROUP BY budget.id
			ORDER BY category.name ASC, budget.start_date ASC;
			""",
			[user['id'], start, end]
			(err, results) ->
				conn.release()
				if (err) then return c(err)

				data = {}
				for row in results
					if (!data[row['category']])
						data[row['category']] = []
					data[row['category']].push(row)
				callback(null, data)
		))
}

module.exports = manager
