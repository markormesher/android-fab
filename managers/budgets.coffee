uuid = require('node-uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

manager = {

	getBudget: (id, callback) ->
		mysql.getOpenConnection((conn) ->
			conn.query('SELECT * FROM budget WHERE id = ? LIMIT 1;', id, (err, results) ->
				if (err) then return callback(err)
				if (results && results.length == 1)
					budget = results[0]
					conn.query('SELECT category_id FROM budget_category WHERE budget_id = ?;', budget.id, (err, results) ->
						if (err) then return callback(err)
						budget['categories'] = (c['category_id'] for c in results)
						callback(null, budget)
					)
				else
					callback(null, null)
		))


	getBudgets: (activeOnly, callback) ->
		if (activeOnly)
			query = 'SELECT * FROM budget WHERE start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) ORDER BY start_date DESC, name ASC;'
		else
			query = 'SELECT * FROM budget ORDER BY start_date DESC, name ASC;'

		mysql.getConnection((conn) -> conn.query(query, (err, results) ->
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			callback(null, [])
		))


	saveBudget: (id, budget, callback) ->
		insert = false
		if (!id || id == 0 || id == '0')
			insert = true
			id = uuid.v1()
		budget['id'] = id

		budgetCategoryInserts = []
		if (typeof budget['categories'] == 'string')
			budget.categories = [budget.categories]
		for c in budget['categories']
			budgetCategoryInserts.push([id, c])

		delete budget['categories']

		if (insert)
			mysql.getOpenConnection((conn) ->
				conn.beginTransaction((err) ->
					if (err) then return conn.rollback(() -> callback(err))
					conn.query('INSERT INTO budget SET ?;', [budget], (err) ->
						if (err) then return conn.rollback(() -> callback(err))
						conn.query('INSERT INTO budget_category VALUES ?;', [budgetCategoryInserts], (err) ->
							if (err) then return conn.rollback(() -> callback(err))
							conn.commit((err) ->
								if (err) then return conn.rollback(() -> callback(err))
								callback(null)
							)
						)
					)
				)
			)
		else
			mysql.getOpenConnection((conn) ->
				conn.beginTransaction((err) ->
					if (err) then return conn.rollback(() -> callback(err))
					conn.query('UPDATE budget SET ? WHERE id = ?;', [budget, id], (err) ->
						if (err) then return conn.rollback(() -> callback(err))
						conn.query('DELETE FROM budget_category WHERE budget_id = ?;', [id], (err) ->
							if (err) then return conn.rollback(() -> callback(err))
							conn.query('INSERT INTO budget_category VALUES ?;', [budgetCategoryInserts], (err) ->
								if (err) then return conn.rollback(() -> callback(err))
								conn.commit((err) ->
									if (err) then return conn.rollback(() -> callback(err))
									callback(null)
								)
							)
						)
					)
				)
			)

}

module.exports = manager
