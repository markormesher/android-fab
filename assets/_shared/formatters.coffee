window.formatters = {

	formatCurrency: (amount) ->
		return amount.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,')

	formatDate: (input) ->
		if (!(typeof input == typeof new Date()))
			input = new Date(input)

		date = input.getDate()
		dateZero = if (date < 10) then '0' else ''
		month = input.getMonth() + 1
		monthZero = if (month < 10) then '0' else ''
		year = input.getFullYear()

		return "#{dateZero}#{date}/#{monthZero}#{month}/#{year}"
}
