uuid = require('uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')
constants = rfr('./constants.json')

manager = {

	getCategory: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM category WHERE id = ? AND owner = ? LIMIT 1;', [id, user.id], (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))


	getCategories: (user, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM category WHERE owner = ? AND active = true ORDER BY name ASC;', user.id, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			return callback(null, [])
		))


	getCategoriesCount: (user, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT COUNT(*) AS result FROM category WHERE owner = ? AND active = true AND system = false;', user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredCategoriesCount: (user, query, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT COUNT(*) AS result
			FROM category
			WHERE owner = ? AND LOWER(name) LIKE ? AND active = true AND system = false;
			""",
			[user.id, "%#{query.toLowerCase()}%"],
			(err, result) ->
				conn.release()
				if (err) then return callback(err)
				if (result) then return callback(null, result[0]['result'])
				callback(null, null)
		))


	getFilteredCategories: (user, query, start, count, order, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT *
			FROM category
			WHERE owner = ? AND LOWER(name) LIKE ? AND active = true AND system = false
			""" + ' ORDER BY name ' + order + ' LIMIT ? OFFSET ?;',
			[user.id, "%#{query.toLowerCase()}%", count, start],
			(err, result) ->
				conn.release()
				if (err) then return callback(err)
				if (result) then return callback(null, result)
				callback(null, null)
		))


	saveCategory: (user, id, category, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO category (id, owner, name, active, system) VALUES (?, ?, ?, 1, 0);',
				[id, user.id, category.name],
				(err) ->
					conn.release()
					callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE category SET name = ? WHERE id = ? AND owner = ?;',
				[category.name, id, user.id],
				(err) ->
					conn.release()
					callback(err)
			))


	setSummaryVisibility: (user, id, value, callback) ->
		if (['in', 'out', 'both'].indexOf(value) < 0) then value = null
		mysql.getConnection((conn) -> conn.query('UPDATE category SET summary_visibility = ? WHERE id = ? AND owner = ? AND system = false', [value, id, user.id],
			(err) ->
				conn.release()
				callback(err)
		))


	deleteCategory: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('UPDATE category SET active = false WHERE id = ? AND owner = ? AND system = false;', [id, user.id], (err) ->
			conn.release()
			callback(err)
		))
}

module.exports = manager
