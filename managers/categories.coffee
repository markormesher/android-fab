uuid = require('node-uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

manager = {

	getCategory: (id, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM category WHERE id = ? LIMIT 1;', id, (err, results) ->
			if (err) then return callback(err)
			if (results && results.length == 1) then return callback(null, results[0])
			callback(null, null)
		))


	getCategories: (activeOnly, callback) ->
		query = if (activeOnly)
			'SELECT * FROM category WHERE active = 1 ORDER BY name ASC;'
		else
			'SELECT * FROM category ORDER BY name ASC;'
		mysql.getConnection((conn) -> conn.query(query, (err, results) ->
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			return callback(null, [])
		))


	saveCategory: (id, category, callback) ->
		if (!id || id == 0 || id == '0')
			id = uuid.v1()
			mysql.getConnection((conn) -> conn.query(
				'INSERT INTO category (id, name, active, system) VALUES (?, ?, 1, 0);',
				[id, category.name],
				(err) -> callback(err)
			))
		else
			mysql.getConnection((conn) -> conn.query(
				'UPDATE category SET name = ? WHERE id = ?;',
				[category.name, id],
				(err) -> callback(err)
			))
}

module.exports = manager
