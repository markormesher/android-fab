defaultStart = moment().startOf('month')
defaultEnd = moment().endOf('month')

loadingPane = $('.loading-pane')
errorPane = $('.error-pane')
contentPane = $('.content-pane')

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
					beginAtZero: true
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
	console.log(data)
	dataset = {
		label: 'Balance'
		borderColor: 'rgba(115, 135, 156, 1.0)'
		backgroundColor: 'rgba(115, 135, 156, 0.2)'
		data: []
	}
	for d in data
		dataset.data.push({
			x: moment(d['date'])
			y: d['balance']
		})
	chart.data.datasets = [dataset]
	chart.update()

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
