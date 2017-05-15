startDate = moment().startOf('month')
endDate = moment().endOf('month')

activeAccounts = []

errorPane = $('.error-pane')
contentPane = $('.content-pane')

contentPane.fadeTo(0, 0.4)
errorPane.hide()

reportRangeBtn = $('#report-range')
selectAccountsBtn = $('#select-accouts')
activeAccountsField = selectAccountsBtn.find('span')

accountsModal = $('#accounts-modal')
accountsModalCheckboxes = accountsModal.find('input[type = checkbox]')
accountsModalUpdateBtn = accountsModal.find('#update-btn')

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
					callback: (value) -> window.formatters.formatCurrency(value)
					beginAtZero: window.user.settings['report_bal_history_settings_start_at_zero'] == 'yes'
				}
			}]
			xAxes: [{
				type: 'linear'
				position: 'bottom'
				ticks: { callback: (value) -> moment(value).format('DD MMM') }
			}]
		}
		legend: {
			display: false
		}
	}
})

settingsModal = {}

$(document).ready(() ->
	updateActiveAccounts()
	onDateSet(startDate, endDate)
	initSettingsModal()
	populateSettingsModal()
)

onDateSet = (start, end) ->
	if (busy) then return
	startDate = start
	endDate = end
	setDateUi(start, end)
	updateChart()

setDateUi = (start, end) -> $('#report-range span').html(start.format('D MMM, YYYY') + ' - ' + end.format('D MMM, YYYY'))

updateActiveAccounts = () ->
	activeAccounts = []
	accountsModalCheckboxes.each(() -> if ($(this).is(':checked')) then activeAccounts.push($(this).val()))
	activeAccountsField.html(activeAccounts.length + ' of ' + accountsModalCheckboxes.length)

busy = false

updateChart = () ->
	if (busy) then return
	busy = true

	contentPane.fadeTo(0, 0.4)
	errorPane.hide()

	# make a copy of the dates, to keep the UI consistent if requests finish out of order
	selectedStart = startDate
	selectedEnd = endDate

	$.post('/reports/balance-history/data', {
		start: selectedStart.format('YYYY-MM-DD')
		end: selectedEnd.format('YYYY-MM-DD')
		accounts: activeAccounts
	}).done((data) ->
		populateChart(data)
		contentPane.fadeTo(0, 1.0)
	).fail(() ->
		toastr.error('Sorry, the graph couldn\'t be loaded!')
		contentPane.fadeTo(0, 1.0)
		errorPane.show()
	).always(() ->
		setDateUi(selectedStart, selectedEnd)
		busy = false
	)

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

selectAccountsBtn.click(() ->
	accountsModal.modal('show')
)

accountsModalUpdateBtn.click(() ->
	accountsModal.modal('hide')
	updateActiveAccounts()
	updateChart()
)

initSettingsModal = () ->
	settingsModal['_modal'] = $('#settings-modal')
	settingsModal['_form'] = $('#settings-form')
	settingsModal['date-display-mode'] = settingsModal['_modal'].find('#date-display-mode')
	settingsModal['start-at-zero'] = settingsModal['_modal'].find('#start-at-zero')
	settingsModal['save-btn'] = settingsModal['_modal'].find('#save-settings-btn')

	settingsModal['_form'].submit((e) ->
		e.preventDefault()
		if ($(this).valid())
			saveSettings()
	)

	$('#settings-btn').click(() -> openSettings())

populateSettingsModal = () ->
	settingsModal['date-display-mode'].val(window.user.settings['report_bal_history_settings_date_display_mode'])
	settingsModal['start-at-zero'].val(window.user.settings['report_bal_history_settings_start_at_zero'])

setSettingsModalLock = (locked) ->
	settingsModal['date-display-mode'].prop('disabled', locked)
	settingsModal['start-at-zero'].prop('disabled', locked)
	settingsModal['save-btn'].prop('disabled', locked)
	if (locked)
		settingsModal['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		settingsModal['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

openSettings = () ->
	populateSettingsModal()
	settingsModal['_modal'].modal('show')

saveSettings = () ->
	setSettingsModalLock(true)
	$.post('/users/settings', {
		'report_bal_history_settings_date_display_mode': settingsModal['date-display-mode'].val()
		'report_bal_history_settings_start_at_zero': settingsModal['start-at-zero'].val()
	}).done(() ->
		setSettingsModalLock(false)
		window.user.settings['report_bal_history_settings_date_display_mode'] = settingsModal['date-display-mode'].val()
		window.user.settings['report_bal_history_settings_start_at_zero'] = settingsModal['start-at-zero'].val()
		chart.options.scales.yAxes[0].ticks.beginAtZero = window.user.settings['report_bal_history_settings_start_at_zero'] == 'yes'
		updateChart()
		settingsModal['_modal'].modal('hide')
	).fail(() ->
		setSettingsModalLock(false)
		toastr.error('Sorry, those settings couldn\'t be saved!')
	)
