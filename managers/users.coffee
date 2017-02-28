rfr = require('rfr')
mysql = rfr('./helpers/mysql')
auth = rfr('./helpers/auth')

manager = {

	getUserForAuth: (email, password, callback) ->
		mysql.getConnection((conn) -> conn.query(
			'SELECT * FROM user WHERE email = ? AND password = ? LIMIT 1;',
			[email, auth.sha256(password)],
			(err, results) ->
				if (err) then return callback(err)
				if (results && results.length == 1) then return callback(null, results[0])
				callback(null, null)
		))


	getUser: (email, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM user WHERE email = ? LIMIT 1;', email, (err, results) ->
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))
}

module.exports = manager
