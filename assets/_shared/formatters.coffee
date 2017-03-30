oneDay = 24 * 60 * 60 * 1000
monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

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

	formatBudgetSpan: (start, end) ->
		if (!(typeof start == typeof new Date()))
			start = new Date(start)
		if (!(typeof end == typeof new Date()))
			end = new Date(end)

		pType = window.formatters.getBudgetPeriodType(start, end)

		switch (pType)
			when 'month' then return monthNames[start.getMonth()] + ', ' + start.getFullYear()
			when 'year' then return start.getFullYear()
			when 'tax-year' then return start.getFullYear() + '/' + end.getFullYear() + ' tax year'
			else return formatters.formatDate(start) + ' - ' + formatters.formatDate(end)
}
