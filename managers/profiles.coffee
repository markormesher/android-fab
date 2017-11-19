rfr = require('rfr')
mysql = rfr('./helpers/mysql')

manager = {

	getProfiles: (userId, callback) ->
		mysql.getConnection((conn) -> conn.query(
			'SELECT * FROM profile WHERE id IN (SELECT profile_id FROM user_profile WHERE user_id = ?) ORDER BY name ASC;', userId,
			(err, results) ->
				conn.release()
				if (err) then return callback(err)
				return callback(null, results)
		))

}

module.exports = manager
