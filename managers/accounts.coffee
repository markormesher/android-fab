uuid = require('uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

manager = {

	getAccount: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM account WHERE id = ? AND owner = ? LIMIT 1;', [id, user.id], (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))


	getAccounts: (user, activeOnly, callback) ->
		query = if (activeOnly)
			'SELECT * FROM account WHERE active = 1 AND owner = ? ORDER BY display_order ASC;'
		else
			'SELECT * FROM account WHERE owner = ? ORDER BY display_order ASC;'
		mysql.getConnection((conn) -> conn.query(query, user.id, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			return callback(null, [])
		))


	saveAccount: (user, id, account, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO account (id, owner, name, description, type, display_order, active) VALUES (?, ?, ?, ?, ?, (SELECT COALESCE(MAX(display_order) + 1, 0) FROM (SELECT display_order FROM account WHERE owner = ?) AS maxDisplayOrder), 1);',
				[id, user.id, account.name, account.description, account.type, user.id],
				(err) ->
					conn.release()
					callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE account SET name = ?, description = ?, type = ? WHERE id = ? AND owner = ?;',
				[account.name, account.description, account.type, id, user.id],
				(err) ->
					conn.release()
					callback(err)
			))


	setAccountDisplayOrder: (user, id, order, callback) ->
		mysql.getConnection((conn) -> conn.query('UPDATE account SET display_order = ? WHERE id = ? AND owner = ?;', [order, id, user.id], (err) ->
			conn.release()
			callback(err)
		))
}

module.exports = manager
