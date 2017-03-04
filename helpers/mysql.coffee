mysql = require('mysql')
rfr = require('rfr')
secrets = rfr('./secrets.json')

poolConfig = secrets.MYSQL_CONFIG
poolConfig['connectionLimit'] = 10
pool = mysql.createPool(poolConfig)

module.exports = {

	getConnection: (onReady) ->
		pool.getConnection((err, conn) ->
			if (err) then throw err
			onReady(conn)
		)

}
