async = require('async')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')
formatters = rfr('./helpers/formatters')
constants = rfr('./constants.json')

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
				if (err) then return callback(err)
				if (results) then return callback(null, results)
				callback(null, [])
		))


	getAlerts: (callback) ->
		async.parallel(
			[
				(c) -> mysql.getConnection((conn) ->
					conn.query('SELECT SUM(amount) AS balance FROM transaction WHERE category_id = ?;', constants.balance_transfer_category_id, (err, results) ->
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
}

module.exports = manager
