uuid = require('uuid')
rfr = require('rfr')
mysql = rfr('./helpers/mysql')

oneDay = 24 * 60 * 60 * 1000

manager = {

	getBudget: (user, id, callback) ->
		mysql.getConnection((conn) ->
			conn.query(
				"""
				SELECT budget.*, category.name AS category
				FROM budget JOIN category ON category.id = budget.category_id
				WHERE budget.id = ? AND budget.owner = ? AND budget.active = true LIMIT 1;
				""", [id, user.id], (err, results) ->
					if (err)
						conn.release()
						return callback(err)

					if (results && results.length == 1)
						callback(null, results[0])
					else
						conn.release()
						callback(null, null)
			))


	getBudgets: (user, currentOnly, callback) ->
		if (currentOnly)
			query = """
			SELECT budget.*, category.name AS category
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW())
			ORDER BY start_date DESC, category ASC;
			"""
		else
			query = """
			SELECT budget.*, category.name AS category
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true
			ORDER BY start_date DESC, category ASC;
			"""

		mysql.getConnection((conn) -> conn.query(query, user.id, (err, results) ->
			conn.release()
			if (err) then return callback(err)
			if (results) then return callback(null, results)
			callback(null, [])
		))


	getBudgetHistoryByCategory: (user, categoryId, callback) ->
		mysql.getConnection((conn) -> conn.query(
			"""
			SELECT *, COALESCE((
				SELECT SUM(transaction.amount)
				FROM transaction
				WHERE transaction.category_id = budget.category_id
				AND transaction.effective_date >= budget.start_date AND transaction.effective_date <= budget.end_date
			), 0) * -1 AS spend
			FROM budget
			WHERE owner = ? AND active = true AND category_id = ?
			GROUP BY budget.id
			ORDER BY budget.start_date ASC;
			""",
			[user.id, categoryId]
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				if (results) then return callback(null, results)
				callback(null, [])
		))


	getBudgetCount: (user, currentOnly, callback) ->
		if (currentOnly)
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW());'
		else
			query = 'SELECT COUNT(*) AS result FROM budget WHERE owner = ? AND active = true;'
		mysql.getConnection((conn) -> conn.query(query, user.id, (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredBudgetCount: (user, currentOnly, search, callback) ->
		if (currentOnly)
			query = """
			SELECT COUNT(*) AS result
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) AND LOWER(category.name) LIKE ?;
			"""
		else
			query = """
			SELECT COUNT(*) AS result
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND LOWER(category.name) LIKE ?;
			"""
		mysql.getConnection((conn) -> conn.query(query, [user.id, "%#{search.toLowerCase()}%"], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result[0]['result'])
			callback(null, null)
		))


	getFilteredBudgets: (user, currentOnly, search, start, count, order, callback) ->
		if (currentOnly)
			query = """
			SELECT budget.*, category.name AS category
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND start_date <= DATE(NOW()) AND end_date >= DATE(NOW()) AND LOWER(category.name) LIKE ?
			ORDER BY start_date """ + order + """, category ASC LIMIT ? OFFSET ?;
			"""
		else
			query = """
			SELECT budget.*, category.name AS category
			FROM budget JOIN category ON category.id = budget.category_id
			WHERE budget.owner = ? AND budget.active = true AND LOWER(category.name) LIKE ?
			ORDER BY start_date """ + order + """, category ASC LIMIT ? OFFSET ?;
			"""
		mysql.getConnection((conn) -> conn.query(query, [user.id, "%#{search.toLowerCase()}%", count, start], (err, result) ->
			conn.release()
			if (err) then return callback(err)
			if (result) then return callback(null, result)
			callback(null, null)
		))


	saveBudget: (user, id, budget, conn, callback) ->
		# NOTE: a pre-existing connection MAY be passed in,
		# because this function MAY be called as part of a transaction

		insert = false
		if (!id || id == 0 || id == '0')
			insert = true
			id = uuid.v1()

		budget['id'] = id
		budget['owner'] = user.id
		budget['active'] = true

		if (insert)
			query = 'INSERT INTO budget SET ?;'
			data = [budget]
		else
			query = 'UPDATE budget SET ? WHERE id = ? AND owner = ?;'
			data = [budget, id, user.id]

		if (conn)
			conn.query(query, data, (err) -> callback(err))
		else
			mysql.getConnection((conn) -> conn.query(query, data, (err) ->
				conn.release()
				callback(err)
			))


	cloneBudgets: (user, originalIds, startDate, endDate, callback) ->
		if (!Array.isArray(originalIds))
			originalIds = [originalIds]

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
						newBudget = {
							category_id: originalBudgets[i]['category_id']
							amount: originalBudgets[i]['amount']
							type: originalBudgets[i]['type']
							start_date: startDate
							end_date: endDate
						}
						manager.saveBudget(user, 0, newBudget, conn, (err) ->
							if (err)
								conn.rollback(() -> callback(err))
								return conn.release()
							innerClone(i + 1)
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
