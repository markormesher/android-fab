rfr = require('rfr')
BudgetManager = rfr('./managers/budgets')

oneDay = 24 * 60 * 60 * 1000
monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

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

		pType = BudgetManager.getBudgetPeriodType(start, end)

		switch (pType)
			when 'month' then return monthNames[start.getMonth()] + ', ' + start.getFullYear()
			when 'year' then return start.getFullYear()
			when 'tax-year' then return start.getFullYear() + '/' + end.getFullYear() + ' tax year'
			else return formatters.formatDate(start) + ' - ' + formatters.formatDate(end)
}

module.exports = formatters
