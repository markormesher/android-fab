dateData = {
	'ytd': ['Year to Date', [moment().subtract(12, 'month'), moment()]]
	'this-month': ['This Month', [moment().startOf('month'), moment().endOf('month')]]
	'last-month': ['Last Month', [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]]
	'this-year': ['This Year', [moment().startOf('year'), moment().endOf('year')]]
	'last-year': ['Last Year', [moment().subtract(1, 'year').startOf('year'), moment().subtract(1, 'year').endOf('year')]]
}

window.initDatePicker = (btn, dates, callback) ->
	startDate = undefined
	endDate = undefined
	dateOptions = {}
	for date in dates
		if (dateData[date])
			dateOptions[dateData[date][0]] = dateData[date][1]
			if (!startDate || !endDate)
				startDate = dateData[date][1][0]
				endDate = dateData[date][1][1]
		else
			throw date + ' is not a valid date'

	btn.daterangepicker({
		startDate: startDate
		endDate: endDate
		ranges: dateOptions
	}, callback)

	callback(startDate, endDate)
