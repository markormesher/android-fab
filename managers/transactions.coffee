rfr = require('rfr')
uuid = require('uuid')
mysql = rfr('./helpers/mysql')
auth = rfr('./helpers/auth')

manager = {

	getTransactionsCount: (callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT COUNT(*) AS result FROM transaction;', (err, result) ->
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredTransactionsCount: (query, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT COUNT(*) AS result FROM
			(transaction LEFT JOIN account ON transaction.account_id = account.id)
			LEFT JOIN category ON transaction.category_id = category.id
			WHERE LOWER(CONCAT(transaction.payee, COALESCE(transaction.memo, ''), account.name, category.name)) LIKE ?;
			""",
			"%#{query.toLowerCase()}%",
			(err, result) ->
				if (err) then return callback(err)
				if (result) then return callback(null, result[0]['result'])
				callback(null, null)
		))


	getFilteredTransactions: (query, start, count, order, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT transaction.*, account_id, account.name AS account_name, category_id, category.name AS category_name FROM
			(transaction LEFT JOIN account ON transaction.account_id = account.id)
			LEFT JOIN category ON transaction.category_id = category.id
			WHERE LOWER(CONCAT(transaction.payee, COALESCE(transaction.memo, ''), account.name, category.name)) LIKE ?
			""" + 'ORDER BY effective_date ' + order + ', record_date DESC LIMIT ? OFFSET ?;',
			["%#{query.toLowerCase()}%", count, start],
			(err, result) ->
				if (err) then return callback(err)
				if (result) then return callback(null, result)
				callback(null, null)
		))


	getUniquePayees: (callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT DISTINCT(payee) FROM transaction ORDER BY payee ASC;', (err, result) ->
			if (err) then return callback(err)
			if (result) then return callback(null, (r['payee'] for r in result))
			callback(null, [])
		))


	saveTransaction: (id, transaction, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO transaction (id, transaction_date, effective_date, record_date, account_id, category_id, amount, payee, memo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
				[id, transaction.transaction_date, transaction.effective_date, (new Date()).toISOString().slice(0, 19).replace('T', ' '), transaction.account, transaction.category, transaction.amount, transaction.payee, transaction.memo || null],
				(err) -> callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE transaction SET transaction_date = ?, effective_date = ?, account_id = ?, category_id = ?, amount = ?, payee = ?, memo = ? WHERE id = ?;',
				[transaction.transaction_date, transaction.effective_date, transaction.account, transaction.category, transaction.amount, transaction.payee, transaction.memo || null, id],
				(err) -> callback(err)
			))


	deleteTransaction: (id, callback) ->
		mysql.getConnection((conn) -> conn.query('DELETE FROM transaction WHERE id = ?;', id, (err) -> callback(err)))

}

module.exports = manager
