defaultStart = moment().startOf('month')
defaultEnd = moment().endOf('month')

loadingPane = $('.loading-pane')
errorPane = $('.error-pane')
contentPane = $('.content-pane')

startBalanceField = $('.start-balance')
endBalanceField = $('.end-balance')
minBalanceField = $('.min-balance')
minBalanceDateField = $('.min-date')
maxBalanceField = $('.max-balance')
maxBalanceDateField = $('.max-date')
realChangeField = $('.real-change')
percentChangeField = $('.percent-change')
percentChangeIcon = $('.percent-change-icon')
colouredChangeFields = realChangeField.add(percentChangeField).add(percentChangeIcon)

loadingPane.show()
errorPane.hide()

chart = new Chart($('#history-chart'), {
	type: 'line'
	data: { datasets: [] }
	options: {
		tooltips: {
			callbacks: {
				title: (item, data) -> new moment(item[0].xLabel).format('DD MMM')
				label: (item, data) -> '  Balance: ' + window.formatters.formatCurrency(item.yLabel)
			}
		}
		scales: {
			yAxes: [{
				type: 'linear'
				position: 'left'
				ticks: {
					#beginAtZero: true
					callback: (value, index, values) -> window.formatters.formatCurrency(value)
				}
			}]
			xAxes: [{
				type: 'linear'
				position: 'bottom'
				ticks: {
					callback: (value, index, values) -> moment(value).format('DD MMM')
				}
			}]
		}
		legend: {
			display: false
		}
	}
})

busy = false

onDateSet = (start, end) ->
	if (busy) then return
	busy = true

	setDateUi(start, end)

	loadingPane.show()
	errorPane.hide()
	contentPane.hide()

	$.get(
		'/reports/balance-history/data?start=' + start.format('YYYY-MM-DD') + '&end=' + end.format('YYYY-MM-DD')
	).done((data) ->
		populateChart(data)
		loadingPane.hide()
		contentPane.show()
	).fail(() ->
		toastr.error('Sorry, the graph couldn\'t be loaded!')
		loadingPane.hide()
		errorPane.show()
	).always(() ->
		setDateUi(start, end)
		busy = false
	)

setDateUi = (start, end) -> $('#report-range span').html(start.format('D MMM, YYYY') + ' - ' + end.format('D MMM, YYYY'))

populateChart = (data) ->
	dataset = {
		label: 'Balance'
		borderColor: 'rgba(115, 135, 156, 1.0)'
		backgroundColor: 'rgba(115, 135, 156, 0.2)'
		data: []
	}
	for d in data['history']
		dataset.data.push({
			x: moment(d['date'])
			y: d['balance']
		})
	chart.data.datasets = [dataset]
	chart.update()

	startBalanceField.html(window.formatters.formatCurrency(data['start']))
	endBalanceField.html(window.formatters.formatCurrency(data['end']))
	minBalanceField.html(window.formatters.formatCurrency(data['low']))
	minBalanceDateField.html(window.formatters.formatDate(data['lowDate']))
	maxBalanceField.html(window.formatters.formatCurrency(data['high']))
	maxBalanceDateField.html(window.formatters.formatDate(data['highDate']))

	change = data['end'] - data['start']
	percentChange = (change / data['start']) * 100

	colouredChangeFields.removeClass('text-danger').removeClass('text-success')
	percentChangeIcon.removeClass('fa-caret-up').removeClass('fa-caret-down').removeClass('fa-circle')

	if (change == 0)
		realChangeField.html(window.formatters.formatCurrency(0))
		percentChangeField.html(0.toFixed(2) + '%')
		percentChangeIcon.addClass('fa-circle')
	else if (change > 0)
		realChangeField.html('+ ' + window.formatters.formatCurrency(Math.abs(change)))
		percentChangeField.html(Math.abs(percentChange).toFixed(2) + '%')
		colouredChangeFields.addClass('text-success')
		percentChangeIcon.addClass('fa-caret-up')
	else if (change < 0)
		realChangeField.html('- ' + window.formatters.formatCurrency(Math.abs(change)))
		percentChangeField.html(Math.abs(percentChange).toFixed(2) + '%')
		colouredChangeFields.addClass('text-danger')
		percentChangeIcon.addClass('fa-caret-down')

$('#report-range').daterangepicker(
	{
		startDate: defaultStart
		endDate: defaultEnd
		ranges: {
			'This Month': [moment().startOf('month'), moment().endOf('month')]
			'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
			'This Year': [moment().startOf('year'), moment().endOf('year')]
			'Last Year': [moment().subtract(1, 'year').startOf('year'), moment().subtract(1, 'year').endOf('year')]
		}
	}
	onDateSet
)

onDateSet(defaultStart, defaultEnd)
