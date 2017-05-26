Array::unique = ->
	output = {}
	output[@[key]] = @[key] for key in [0...@length]
	value for key, value of output

startDate = moment().startOf('year')
endDate = moment().endOf('year')

contentPane = $('#content-pane')
contentPane.fadeTo(0, 0.4)

errorPane = $('#error-pane')
errorPane.hide()

reportRangeBtn = $('#report-range')

$(document).ready(() -> onDateSet(startDate, endDate))

onDateSet = (start, end) ->
	if (busy) then return
	startDate = start
	endDate = end
	setDateUi(start, end)
	updateData()

setDateUi = (start, end) -> $('#report-range span').html(start.format('D MMM, YYYY') + ' - ' + end.format('D MMM, YYYY'))

busy = false

updateData = () ->
	if (busy) then return
	busy = true

	contentPane.fadeTo(0, 0.4)
	errorPane.hide()

	# make a copy of the dates, to keep the UI consistent if requests finish out of order
	selectedStart = startDate
	selectedEnd = endDate

	$.post('/reports/budget-performance/data', {
		start: selectedStart.format('YYYY-MM-DD')
		end: selectedEnd.format('YYYY-MM-DD')
	}).done((data) ->
		populateChart(data)
		contentPane.fadeTo(0, 1.0)
	).fail(() ->
		toastr.error('Sorry, the data couldn\'t be loaded!')
		contentPane.fadeTo(0, 1.0)
		errorPane.show()
	).always(() ->
		setDateUi(selectedStart, selectedEnd)
		busy = false
	)

populateChart = (data) ->
	contentPane.empty()
	tableData = {
		'month': {}
		'year': {}
		'tax-year': {}
		'other': {}
	}
	periods = {
		'month': []
		'year': []
		'tax-year': []
	}
	periodSums = {}
	for name, budgets of data
		for budget in budgets
			type = window.formatters.getBudgetPeriodType(budget['start_date'], budget['end_date'])
			period = window.formatters.formatBudgetSpan(budget['start_date'], budget['end_date'])
			performance = Math.round((budget['spend'] / budget['amount']) * 100)

			if (!tableData[type][name])
				tableData[type][name] = {}
			tableData[type][name][period] = performance

			if (!periodSums[period])
				periodSums[period] = [0, 0]
			periodSums[period][0] += budget['spend']
			periodSums[period][1] += budget['amount']

			if (type != 'other')
				periods[type].push([budget['start_date'], budget['end_date']])

	groupTitles = {
		'month': 'Monthly Budgets'
		'year': 'Yearly Budgets'
		'tax-year': 'Tax Yearly Budgets'
	}

	for type in ['month', 'year', 'tax-year']
		periods[type] = periods[type]
			.sort((a, b) -> if (moment(a[0]).isBefore(moment(b[0]))) then -1 else 1)
			.map((p) -> window.formatters.formatBudgetSpan(p[0], p[1]))
			.unique()

		if (periods[type].length == 0)
			continue

		section = makeBudgetSection(groupTitles[type])

		periodRow = section.find('tr.period')
		for period in periods[type]
			periodRow.append('<th>' + period + '</th>')

		for name, values of tableData[type]
			row = $('<tr></tr>')
			row.append('<td>' + name + '</td>')
			for period in periods[type]
				if (values[period] != undefined)
					performance = values[period]
					row.append('<td class="text-right text-' + getPerformanceClass(performance) + '">' + performance + '%</td>')
				else
					row.append('<td>-</td>')
			section.find('tbody').append(row)

		overallRow = section.find('tfoot tr')
		for period in periods[type]
			if (periodSums[period][1] == 0)
				performance = 0
			else
				performance = Math.round((periodSums[period][0] / periodSums[period][1]) * 100)
			overallRow.append('<td class="text-right text-' + getPerformanceClass(performance) + '">' + performance + '%</td>')

		contentPane.append(section)

makeBudgetSection = (name) -> $("""
	<div class="col-xs-12 col-md-6">
		<div class="x_panel">
			<div class="x_title">
				<h2>#{name}</h2>
				<div class="clearfix"></div>
			</div>
			<div class="x_content">
				<table class="table table-condensed table-hover non-full-width">
					<thead>
						<tr class="period"><th></th></tr>
					</thead>
					<tbody/>
					<tfoot>
						<tr>
							<td>Overall</td>
						</tr>
					</tfoot>
				</table>
			</div>
		</div>
	</div>
""")

getPerformanceClass = (performance) ->
	if (performance <= 0)
		return 'muted'
	else if (performance <= 50)
		return 'info'
	else if (performance <= 100)
		return 'success'
	else
		return 'danger'

reportRangeBtn.daterangepicker(
	{
		startDate: startDate
		endDate: endDate
		ranges: {
			'This Month': [moment().startOf('month'), moment().endOf('month')]
			'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
			'This Year': [moment().startOf('year'), moment().endOf('year')]
			'Last Year': [moment().subtract(1, 'year').startOf('year'), moment().subtract(1, 'year').endOf('year')]
		}
	}
	onDateSet
)
