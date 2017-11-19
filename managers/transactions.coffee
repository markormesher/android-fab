rfr = require('rfr')

uuid = require('uuid')
mysql = rfr('./helpers/mysql')
auth = rfr('./helpers/auth')

manager = {

	getTransactionsCount: (user, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT COUNT(*) AS result FROM transaction WHERE owner = ?;', user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredTransactionsCount: (user, query, callback) ->
		querySql = """
			SELECT COUNT(*) AS result FROM
			(transaction LEFT JOIN account ON transaction.account_id = account.id)
			LEFT JOIN category ON transaction.category_id = category.id
			WHERE transaction.owner = ? AND LOWER(CONCAT(transaction.payee, COALESCE(transaction.memo, ''), account.name, category.name)) LIKE ?
			"""

		if (user.settings['transactions_settings_show_future_transactions'] != 'yes')
			querySql += ' AND transaction.effective_date <= NOW()'

		querySql += ';'

		mysql.getConnection((conn) -> conn.query(querySql, [user.id, "%#{query.toLowerCase()}%"], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredTransactions: (user, query, start, count, order, callback) ->
		querySql = """
			SELECT transaction.*, account_id, account.name AS account_name, account.deleted AS account_deleted, category_id, category.name AS category_name FROM
			(transaction LEFT JOIN account ON transaction.account_id = account.id)
			LEFT JOIN category ON transaction.category_id = category.id
			WHERE transaction.owner = ? AND LOWER(CONCAT(transaction.payee, COALESCE(transaction.memo, ''), account.name, category.name)) LIKE ?
			"""

		if (user.settings['transactions_settings_show_future_transactions'] != 'yes')
			querySql += ' AND transaction.effective_date <= NOW()'

		querySql += ' ORDER BY effective_date ' + order + ', record_date DESC LIMIT ? OFFSET ?;'

		mysql.getConnection((conn) -> conn.query(querySql, [user.id, "%#{query.toLowerCase()}%", count, start], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result)
			callback(null, null)
		))


	getUniquePayees: (user, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT DISTINCT(payee) FROM transaction WHERE owner = ? ORDER BY payee ASC;', user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, (r['payee'] for r in result))
			callback(null, [])
		))


	saveTransaction: (user, id, transaction, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO transaction (id, owner, transaction_date, effective_date, record_date, account_id, category_id, amount, payee, memo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
				[
					id, user.id, transaction.transaction_date, transaction.effective_date,
					(new Date()).toISOString().slice(0, 19).replace('T', ' '),
					transaction.account, transaction.category, transaction.amount,
					transaction.payee, transaction.memo || null
				],
				(err) ->
					conn.release()
					callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE transaction SET transaction_date = ?, effective_date = ?, account_id = ?, category_id = ?, amount = ?, payee = ?, memo = ? WHERE id = ? AND owner = ?;',
				[
					transaction.transaction_date, transaction.effective_date, transaction.account,
					transaction.category, transaction.amount, transaction.payee,
					transaction.memo || null, id, user.id
				],
				(err) ->
					conn.release()
					callback(err)
			))


	deleteTransaction: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('DELETE FROM transaction WHERE id = ? AND owner = ?;', [id, user.id], (err) ->
			conn.release()
			callback(err)
		))

}

module.exports = manager
