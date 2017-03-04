uuid = require('uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

manager = {

	getAccount: (id, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM account WHERE id = ? LIMIT 1;', id, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))


	getAccounts: (activeOnly, callback) ->
		query = if (activeOnly)
			'SELECT * FROM account WHERE active = 1 ORDER BY display_order ASC;'
		else
			'SELECT * FROM account ORDER BY display_order ASC;'
		mysql.getConnection((conn) -> conn.query(query, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			return callback(null, [])
		))


	saveAccount: (id, account, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO account (id, name, description, type, display_order, active) VALUES (?, ?, ?, ?, (SELECT MAX(display_order) + 1 FROM (SELECT display_order FROM account) AS maxDisplayOrder), 1);',
				[id, account.name, account.description, account.type],
				(err) ->
					conn.release()
					callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE account SET name = ?, description = ?, type = ? WHERE id = ?;',
				[account.name, account.description, account.type, id],
				(err) ->
					conn.release()
					callback(err)
			))


	setAccountDisplayOrder: (id, order, callback) ->
		mysql.getConnection((conn) -> conn.query('UPDATE account SET display_order = ? WHERE id = ?;', [order, id], (err) ->
			conn.release()
			callback(err)
		))
}

module.exports = manager
