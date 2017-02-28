oneDay = 24 * 60 * 60 * 1000
monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

formatters = {

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

	formatBudgetSpan: (start, end) ->
		if (!(typeof start == typeof new Date()))
			start = new Date(start)
		if (!(typeof end == typeof new Date()))
			end = new Date(end)

		if (start.getDate() == 1 && start.getMonth() == end.getMonth() && new Date(end.getTime() + oneDay).getMonth() != end.getMonth())
			# single month
			return monthNames[start.getMonth()] + ', ' + start.getFullYear()
		else if (start.getDate() == 1 && start.getMonth() == 0 && end.getDate() == 31 && end.getMonth() == 11 && start.getYear() == end.getYear())
			# calendar year
			return start.getFullYear()
		else if (start.getDate() == 6 && start.getMonth() == 3 && end.getDate() == 5 && end.getMonth() == 3 && start.getYear() == end.getYear() - 1)
			# tax year
			return start.getFullYear() + '/' + end.getFullYear() + ' tax year'
		else
			# ¯\_(ツ)_/¯
			return formatters.formatDate(start) + ' - ' + formatters.formatDate(end)

}

module.exports = formatters
