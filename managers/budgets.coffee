uuid = require('uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

oneDay = 24 * 60 * 60 * 1000

manager = {

	getBudget: (user, id, callback) ->
		mysql.getConnection((conn) ->
			conn.query('SELECT * FROM budget WHERE id = ? AND owner = ? AND active = true LIMIT 1;', [id, user.id], (err, results) ->
				if (err)
					conn.release()
					return callback(err)

				if (results && results.length == 1)
					budget = results[0]
					conn.query('SELECT category_id FROM budget_category WHERE budget_id = ?;', budget.id, (err, results) ->
						conn.release()
						if (err) then return callback(err)
						budget['categories'] = (c['category_id'] for c in results)
						callback(null, budget)
					)
				else
					conn.release()
					callback(null, null)
			))


	getBudgets: (user, activeOnly, callback) ->
		if (activeOnly)
			query = 'SELECT * FROM budget WHERE owner = ? AND active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) ORDER BY start_date DESC, name ASC;'
		else
			query = 'SELECT * FROM budget WHERE owner = ? AND active = true ORDER BY start_date DESC, name ASC;'

		mysql.getConnection((conn) -> conn.query(query, user.id, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			callback(null, [])
		))


	getBudgetCount: (user, activeOnly, callback) ->
		if (activeOnly)
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW());'
		else
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true;'
		mysql.getConnection((conn) -> conn.query(query, user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredBudgetCount: (user, activeOnly, search, callback) ->
		if (activeOnly)
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) AND LOWER(name) LIKE ?;'
		else
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true AND LOWER(name) LIKE ?;'
		mysql.getConnection((conn) -> conn.query(query, [user.id, "%#{search.toLowerCase()}%"], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredBudgets: (user, activeOnly, search, start, count, order, callback) ->
		if (activeOnly)
			query = 'SELECT * FROM budget WHERE owner = ? AND active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) AND LOWER(name) LIKE ? ORDER BY start_date ' + order + ', name ASC LIMIT ? OFFSET ?;'
		else
			query = 'SELECT * FROM budget WHERE owner = ? AND active = true AND LOWER(name) LIKE ? ORDER BY start_date ' + order + ', name ASC LIMIT ? OFFSET ?;'
		mysql.getConnection((conn) -> conn.query(query, [user.id, "%#{search.toLowerCase()}%", count, start], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result)
			callback(null, null)
		))


	saveBudget: (user, id, budget, preConn, callback) ->
		insert = false
		if (!id || id == 0 || id == '0')
			insert = true
			id = uuid.v1()
		budget['id'] = id

		budget['owner'] = user.id
		budget['active'] = true

		budgetCategoryInserts = []
		if (typeof budget['categories'] == 'string')
			budget.categories = [budget.categories]
		for c in budget['categories']
			budgetCategoryInserts.push([id, c])

		delete budget['categories']

		doTransaction = (exec) ->
			if (!preConn)
				mysql.getConnection((conn) -> conn.beginTransaction((err) -> exec(conn, true, err)))
			else
				exec(preConn, false, null)

		if (insert)
			doTransaction((conn, canCommit, err) ->
				if (err)
					conn.rollback(() -> callback(err))
					return conn.release()
				conn.query('INSERT INTO budget SET ?;', [budget], (err) ->
					if (err)
						conn.rollback(() -> callback(err))
						return conn.release()
					conn.query('INSERT INTO budget_category VALUES ?;', [budgetCategoryInserts], (err) ->
						if (err)
							conn.rollback(() -> callback(err))
							return conn.release()
						if (canCommit)
							conn.commit((err) ->
								if (err)
									conn.rollback(() -> callback(err))
									return conn.release()
								conn.release()
								callback(null)
							)
						else
							callback(null)
					)
				)
			)
		else
			doTransaction((conn, canCommit, err) ->
				if (err)
					conn.rollback(() -> callback(err))
					return conn.release()
				conn.query('UPDATE budget SET ? WHERE id = ? AND owner = ?;', [budget, id, user.id], (err) ->
					if (err)
						conn.rollback(() -> callback(err))
						return conn.release()
					conn.query('DELETE FROM budget_category WHERE budget_id = ?;', [id], (err) ->
						if (err)
							conn.rollback(() -> callback(err))
							return conn.release()
						conn.query('INSERT INTO budget_category VALUES ?;', [budgetCategoryInserts], (err) ->
							if (err)
								conn.rollback(() -> callback(err))
								return conn.release()
							if (canCommit)
								conn.commit((err) ->
									if (err)
										conn.rollback(() -> callback(err))
										return conn.release()
									conn.release()
									callback(null)
								)
							else
								callback(null)
						)
					)
				)
			)


	cloneBudgets: (user, originalIds, startDate, endDate, callback) ->
		mysql.getConnection((conn) -> conn.query('SELECT * FROM budget WHERE owner = ? AND id IN (?);', [user.id, originalIds], (err, originalBudgets) ->
			conn.release()
			if (err) then return callback(err)
			if (originalBudgets.length != originalIds.length) then return callback('Invalid ID')

			mysql.getConnection((conn) -> conn.beginTransaction((err) ->
				if (err)
					conn.rollback(() -> callback(err))
					return conn.release()

				innerClone = (i) ->
					if (i == originalBudgets.length)
						conn.commit((err) ->
							if (err)
								conn.rollback(() -> callback(err))
								return conn.release()
							callback(null)
						)
					else
						conn.query('SELECT category_id FROM budget_category WHERE budget_id = ?', originalBudgets[i]['id'], (err, result) ->
							if (err)
								conn.rollback(() -> callback(err))
								return conn.release()
							categoryIds = (r['category_id'] for r in result)
							newBudget = {
									name: originalBudgets[i]['name']
									amount: originalBudgets[i]['amount']
									type: originalBudgets[i]['type']
									start_date: startDate
									end_date: endDate
									categories: categoryIds
							}
							manager.saveBudget(user, 0, newBudget, conn, (err) ->
								if (err)
									conn.rollback(() -> callback(err))
									return conn.release()
								innerClone(i + 1)
							)
						)

				innerClone(0)
			))
		))


	deleteBudget: (user, id, callback) ->
		mysql.getConnection((conn) -> conn.query('UPDATE budget SET active = false WHERE id = ? AND owner = ?;', [id, user.id], (err) ->
			conn.release()
			callback(err)
		))


	getBudgetPeriodType: (start, end) ->
		if (!(typeof start == typeof new Date()))
			start = new Date(start)
		if (!(typeof end == typeof new Date()))
			end = new Date(end)

		if (start.getDate() == 1 && start.getMonth() == end.getMonth() && new Date(end.getTime() + oneDay).getMonth() != end.getMonth())
			return 'month'
		else if (start.getDate() == 1 && start.getMonth() == 0 && end.getDate() == 31 && end.getMonth() == 11 && start.getYear() == end.getYear())
			return 'year'
		else if (start.getDate() == 6 && start.getMonth() == 3 && end.getDate() == 5 && end.getMonth() == 3 && start.getYear() == end.getYear() - 1)
			return 'tax-year'
		else
			return 'other'

}

module.exports = manager
