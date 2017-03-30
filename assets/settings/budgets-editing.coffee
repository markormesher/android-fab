# note: all dates are set at midday to mitigate the effects of BST

daysInMonth = (m, y) -> switch (m % 12)
	when 1
		if ((y % 4 == 0 && y % 100) || y % 400 == 0)
			return 29
		else
			return 28
	when 8, 3, 5, 10
		return 30
	else
		return 31

now = new Date()

startDate = $('#start-date')
endDate = $('#end-date')

setDate = (field, date) ->
	field.val(date.toJSON().slice(0, 10))

$('#insert-this-month').click((e) ->
	e.preventDefault()
	year = now.getFullYear()
	month = now.getMonth()
	setDate(startDate, new Date(year, month, 1, 12, 0, 0, 0))
	setDate(endDate, new Date(year, month, daysInMonth(month, year), 12, 0, 0, 0))
)

$('#insert-next-month').click((e) ->
	e.preventDefault()
	month = now.getMonth()
	year = now.getFullYear()
	if (month == 11)
		month = 0
		++year
	else
		++month

	setDate(startDate, new Date(year, month, 1, 12, 0, 0, 0))
	setDate(endDate, new Date(year, month, daysInMonth(month, year), 12, 0, 0, 0))
)

$('#insert-this-year').click((e) ->
	e.preventDefault()
	year = now.getFullYear()
	setDate(startDate, new Date(year, 0, 1, 12, 0, 0, 0))
	setDate(endDate, new Date(year, 11, 31, 12, 0, 0, 0))
)

$('#insert-next-year').click((e) ->
	e.preventDefault()
	year = now.getFullYear() + 1
	setDate(startDate, new Date(year, 0, 1, 12, 0, 0, 0))
	setDate(endDate, new Date(year, 11, 31, 12, 0, 0, 0))
)

$('#insert-this-tax-year').click((e) ->
	e.preventDefault()
	year = now.getFullYear()
	if (now.getTime() >= new Date(year, 3, 6).getTime())
		# we're in the first calendar year of the tax year
		setDate(startDate, new Date(year, 3, 6, 12, 0, 0, 0))
		setDate(endDate, new Date(year + 1, 3, 4, 12, 0, 0, 0))
	else
		# we're in the second calendar year of the tax year
		setDate(startDate, new Date(year - 1, 3, 6, 12, 0, 0, 0))
		setDate(endDate, new Date(year, 3, 5, 12, 0, 0, 0))
)

$('#insert-next-tax-year').click((e) ->
	e.preventDefault()
	year = now.getFullYear()
	if (now.getTime() >= new Date(year, 3, 6).getTime())
		# we're in the first calendar year of the tax year
		setDate(startDate, new Date(year + 1, 3, 6, 12, 0, 0, 0))
		setDate(endDate, new Date(year + 2, 3, 4, 12, 0, 0, 0))
	else
		# we're in the second calendar year of the tax year
		setDate(startDate, new Date(year, 3, 6, 12, 0, 0, 0))
		setDate(endDate, new Date(year + 1, 3, 5, 12, 0, 0, 0))
)
