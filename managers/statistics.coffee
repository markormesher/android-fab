async = require('async')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')
formatters = rfr('./helpers/formatters')
constants = rfr('./constants.json')
BudgetManager = rfr('./managers/budgets')

manager = {

	getActiveAccountBalances: (callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT account.id AS account_id, account.name AS account_name, SUM(transaction.amount) AS balance
			FROM transaction LEFT JOIN account ON transaction.account_id = account.id
			WHERE account.active = 1
			GROUP BY transaction.account_id ORDER BY account.display_order ASC;
			"""
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				if (results) then return callback(null, results)
				callback(null, [])
		))


	getActiveBudgets: (callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT budget.*, COALESCE((
				SELECT SUM(transaction.amount)
				FROM transaction
				WHERE transaction.category_id IN (SELECT budget_category.category_id FROM budget_category WHERE budget_category.budget_id = budget.id)
				AND transaction.effective_date >= budget.start_date AND transaction.effective_date <= budget.end_date
			), 0) * -1 AS spend
			FROM budget
			WHERE budget.start_date <= DATE(NOW()) AND budget.end_date >= DATE(NOW())
			ORDER BY budget.start_date DESC, budget.name ASC;
			"""
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


	getAlerts: (settings, callback) ->
		async.parallel(
			[
				(c) -> mysql.getConnection((conn) ->
					conn.query('SELECT SUM(amount) AS balance FROM transaction WHERE category_id = ?;', settings['balance_transfer_category_id'], (err, results) ->
						conn.release()
						if (err) then return c(err)
						balance = results[0]['balance']
						if (balance != 0)
							c(null, ['Transfer balance is ' + formatters.formatCurrency(balance) + '.'])
						else
							c(null, [])
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


	getSummaryData: (settings, startDate, endDate, callback) ->
		async.parallel(
			{
				'categorySums': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT SUM(transaction.amount) AS balance, category.id AS categoryId, category.name AS categoryName, category.summary_visibility AS summaryVisibility
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE category.summary_visibility IS NOT NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?
					GROUP BY category.id;
					"""
					[startDate, endDate],
					(err, results) ->
						conn.release()
						if (err) then return c(err)
						c(null, results)
				))
				'totalFlow': (c) -> mysql.getConnection((conn) -> conn.query(
					'SELECT SUM(amount) AS balance FROM transaction WHERE effective_date >= ? AND effective_date <= ?;',
					[startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
				'otherIn': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT SUM(transaction.amount) AS balance
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE amount > 0 AND category.summary_visibility IS NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?;
					"""
					[startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
				'otherOut': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT SUM(transaction.amount) AS balance
					FROM transaction JOIN category ON transaction.category_id = category.id
					WHERE amount < 0 AND category.summary_visibility IS NULL AND transaction.effective_date >= ? AND transaction.effective_date <= ?;
					"""
					[startDate, endDate],
					(err, results) ->
						conn.release()
						if (err || results.length != 1) then return c(err)
						c(null, results[0]['balance'])
				))
				'movedToSavings': (c) -> mysql.getConnection((conn) -> conn.query(
					"""
					SELECT COALESCE(SUM(transaction.amount), 0) AS balance
					FROM transaction JOIN account ON transaction.account_id = account.id
					WHERE account.type = 'savings' AND transaction.category_id = ? AND transaction.effective_date >= ? AND transaction.effective_date <= ?;
					"""
					[settings['balance_transfer_category_id'], startDate, endDate],
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
				output.movedToSavings = results['movedToSavings']

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
}

module.exports = manager
