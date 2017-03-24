rfr = require('rfr')
mysql = rfr('./helpers/mysql')
hashing = rfr('./helpers/hashing')
constants = rfr('./constants.json')

manager = {

	getUserForAuth: (emailOrId, password, callback) ->
		mysql.getConnection((conn) -> conn.query(
			'SELECT * FROM user WHERE (email = ? OR id = ?) AND password = ? LIMIT 1;',
			[emailOrId, emailOrId, hashing.sha256(password)],
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				if (results && results.length == 1) then return callback(null, results[0])
				callback(null, null)
		))


	getUser: (emailOrId, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM user WHERE email = ? OR id = ? LIMIT 1;', [emailOrId, emailOrId], (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))


	saveUser: (id, user, callback) ->
		# this method does the actual update, optionally with a new password
		# it is called immediately if there is no password update, or after authentication if there is
		doUpdate = (id, user, newPassword, callback) ->
			updates = {}
			updates['first_name'] = user['first_name']
			updates['last_name'] = user['last_name']
			if (newPassword)
				updates['password'] = hashing.sha256(newPassword)

			mysql.getConnection((conn) -> conn.query('UPDATE user SET ? WHERE id = ? LIMIT 1;', [updates, id], (err) ->
				conn.release()
				if (err) then return callback(err)
				manager.getUser(id, (err, newUser) ->
						if (err) then return callback(err)
						callback(null, newUser)
				)
			))

		# if the current password is set, authenticate it before trying the update
		if (user['current_password'] || user['new_password'] || user['new_password_again'])
			if (user['new_password'] != user['new_password_again'] || user['new_password'].length < 8)
				return callback('invalid-password')

			manager.getUserForAuth(id, user['current_password'], (err, foundUser) ->
				if (err) then return callback(err)
				if (!foundUser)
					callback('bad-password')
				else
					doUpdate(id, user, user['new_password'], callback)
			)
		else
			doUpdate(id, user, null, callback)


	getUserSettings: (userId, callback) ->
		settings = constants['defaultSettings']
		mysql.getConnection((conn) -> conn.query('SELECT * FROM setting WHERE user_id = ?;', userId, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			for r in results
				settings[r['setting_key']] = r['setting_value']
			settings['__version'] = constants['settingsVersion']
			callback(null, settings)
		))
}

module.exports = manager
