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


	getAccountsCount: (user, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT COUNT(*) AS result FROM account WHERE owner = ? AND active = true;', user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredAccountsCount: (user, query, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT COUNT(*) AS result
			FROM account
			WHERE owner = ? AND LOWER(CONCAT(name, description)) LIKE ? AND active = true;
			""",
			[user.id, "%#{query.toLowerCase()}%"],
			(err, result) ->
				conn.release()
				if (err) then return callback(err)
				if (result) then return callback(null, result[0]['result'])
				callback(null, null)
		))


	getFilteredAccounts: (user, query, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT *
			FROM account
			WHERE owner = ? AND LOWER(CONCAT(name, description)) LIKE ? AND active = true
			ORDER BY display_order ASC;
			""",
			[user.id, "%#{query.toLowerCase()}%"],
			(err, result) ->
				conn.release()
				if (err) then return callback(err)
				if (result) then return callback(null, result)
				callback(null, null)
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


	# TODO
	reorderAccount: (user, id, direction, callback) ->
		callback(null)
#		mysql.getConnection((conn) ->
#			conn.beginTransaction((err) ->
#				if (err)
#					conn.rollback(() -> callback(err))
#					return conn.release()
#				conn.query('SELECT display_order FROM account WHERE id = ? AND owner = ?;', [id, user.id], (err, result) ->
#					if (err)
#						conn.rollback(() -> callback(err))
#						return conn.release()
#
#					conn.query('UPDATE account SET display_order = display_order + (? * -1) WHERE display_order = (SELECT display_order FROM ((SELECT * FROM account WHERE id = ?) AS temp_table)) AND owner = ? AND id != ?;', [direction, id, id, user.id], (err) ->
#						if (err)
#							conn.rollback(() -> callback(err))
#							return conn.release()
#						conn.commit((err) ->
#							if (err)
#								conn.rollback(() -> callback(err))
#								return conn.release()
#							conn.release()
#							callback(null)
#						)
#					)
#				)
#			)
#		)


	deleteAccount: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('UPDATE account SET active = false WHERE id = ? AND owner = ?;', [id, user.id], (err) ->
			conn.release()
			callback(err)
		))
}

module.exports = manager
