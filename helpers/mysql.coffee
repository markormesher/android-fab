mysql = require('mysql')
rfr = require('rfr')
secrets = rfr('./secrets.json')

module.exports = {

	getConnection: (onComplete) ->
		connection = mysql.createConnection(secrets.MYSQL_CONFIG)
		connection.connect((err) ->
			if (err)
				throw err
			onComplete(connection)
			connection.end()
		)

	getOpenConnection: (onComplete) ->
		connection = mysql.createConnection(secrets.MYSQL_CONFIG)
		connection.connect((err) ->
			if (err)
				throw err
			onComplete(connection)
		)

}
