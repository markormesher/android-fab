actionsHtml = """
<div class="text-center">
	<div class="btn-group">
		<button class="btn btn-mini btn-default delete-btn" data-id="__ID__"><i class="fa fa-fw fa-trash"></i></button>
		<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
	</div>
</div>
"""

formatDatePair = (trDate, efDate) ->
	if (trDate == efDate)
		if (window.user.settings['transactions_settings_date_display_mode'] == 'effective')
			return window.formatters.formatDate(efDate)
		else
			return window.formatters.formatDate(trDate)

	else
		if (window.user.settings['transactions_settings_date_display_mode'] == 'effective')
			return "#{window.formatters.formatDate(efDate)} <i class=\"fa fa-fw fa-info-circle text-muted\" title=\"Transaction date: #{window.formatters.formatDate(trDate)}\"></i>"
		else
			return "#{window.formatters.formatDate(trDate)} <i class=\"fa fa-fw fa-info-circle text-muted\" title=\"Effective date: #{window.formatters.formatDate(efDate)}\"></i>"


currentData = {}
editId = 0

editorModal = {}
settingsModal = {}
dataTable = null

$(document).ready(() ->
	initDataTable()
	initEditorModal()
	initSettingsModal()
)

initDataTable = () ->
	dataTable = $('#transactions').DataTable({
		paging: true
		lengthMenu: [
			[25, 50, 100]
			[25, 50, 100]
		]
		order: [[0, 'desc']]
		columnDefs: [
			{ targets: [0], orderable: true }
			{ targets: [3], className: 'currency text-right' }
			{ targets: '_all', orderable: false }
		]

		serverSide: true
		ajax: {
			url: '/transactions/data'
			type: 'get'
			dataSrc: (raw) ->
				currentData = {}
				displayData = []
				for d in raw.data
					currentData[d['id']] = d
					displayData.push([
						formatDatePair(d['transaction_date'], d['effective_date'])
						d['account_name']
						d['payee'] + (if (d.memo != null && d.memo != '') then " <i class=\"fa fa-fw fa-info-circle text-muted\" title=\"#{d.memo}\"></i>" else '')
						window.formatters.formatCurrency(d['amount'])
						d['category_name']
						actionsHtml.replace(///__ID__///g, d['id'])
					])
				return displayData
		}

		drawCallback: onTableReload
	})

onTableReload = () ->
	$('.delete-btn').click(() -> deleteTransaction($(this), $(this).data('id')))
	$('.edit-btn').click(() -> startEditTransaction($(this).data('id')))

initEditorModal = () ->
	editorModal['_modal'] = $('#editor-modal')
	editorModal['_form'] = $('#editor-form')
	editorModal['_createOnly'] = editorModal['_modal'].find('.create-only')
	editorModal['_editOnly'] = editorModal['_modal'].find('.edit-only')
	editorModal['transaction-date'] = editorModal['_modal'].find('#transaction-date')
	editorModal['effective-date'] = editorModal['_modal'].find('#effective-date')
	editorModal['account'] = editorModal['_modal'].find('#account')
	editorModal['payee'] = editorModal['_modal'].find('#payee')
	editorModal['category'] = editorModal['_modal'].find('#category')
	editorModal['amount'] = editorModal['_modal'].find('#amount')
	editorModal['memo'] = editorModal['_modal'].find('#memo')
	editorModal['add-another'] = editorModal['_modal'].find('#add-another')
	editorModal['save-btn'] = editorModal['_modal'].find('#save-btn')

	editorModal['_modal'].on('shown.bs.modal', () ->
		editorModal['transaction-date'].focus()
	)

	editorModal['payee'].autocomplete({
		source: payees
	})

	$('#add-btn').click(() -> startEditTransaction(0))
	$('#copy-date').click((e) ->
		e.preventDefault()
		editorModal['effective-date'].val(editorModal['transaction-date'].val())
	)

	for key, field of editorModal
		if (field.prop('type') != undefined || field.prop('tagName') == 'TEXTAREA')
			field.keydown((e) ->
				if ((e.ctrlKey || e.metaKey) && (e.keyCode == 13 || e.keyCode == 10))
					editorModal['_form'].submit()
			)

	editorModal['_form'].submit((e) ->
		if ($(this).valid())
			saveTransaction()
		e.preventDefault()
	)

clearEditorModal = (clearDates) ->
	if (clearDates)
		editorModal['transaction-date'].val((new Date()).toJSON().slice(0, 10))
		editorModal['effective-date'].val((new Date()).toJSON().slice(0, 10))
	editorModal['account'].prop('selectedIndex', 0)
	editorModal['payee'].val('')
	editorModal['category'].prop('selectedIndex', 0)
	editorModal['amount'].val('')
	editorModal['memo'].val('')

populateEditorModal = (id) ->
	transaction = currentData[id]
	if (transaction)
		editorModal['transaction-date'].val((new Date(transaction['transaction_date'])).toJSON().slice(0, 10))
		editorModal['effective-date'].val((new Date(transaction['effective_date'])).toJSON().slice(0, 10))
		editorModal['account'].val(transaction['account_id'])
		editorModal['payee'].val(transaction['payee'])
		editorModal['category'].val(transaction['category_id'])
		editorModal['amount'].val(transaction['amount'].toFixed(2))
		editorModal['memo'].val(transaction['memo'])

setEditorModalLock = (locked) ->
	editorModal['transaction-date'].prop('disabled', locked)
	editorModal['effective-date'].prop('disabled', locked)
	editorModal['account'].prop('disabled', locked)
	editorModal['payee'].prop('disabled', locked)
	editorModal['category'].prop('disabled', locked)
	editorModal['amount'].prop('disabled', locked)
	editorModal['memo'].prop('disabled', locked)
	editorModal['save-btn'].prop('disabled', locked)
	if (locked)
		editorModal['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editorModal['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

deleteTransaction = (btn, id) ->
	if (btn.hasClass('btn-danger'))
		btn.find('i').removeClass('fa-trash').addClass('fa-circle-o-notch').addClass('fa-spin')
		$.post(
			"/transactions/delete/#{id}"
		).done(() ->
			dataTable.ajax.reload()
		).fail(() ->
			toastr.error('Sorry, that transaction couldn\'t be deleted!')
		)
	else
		btn.removeClass('btn-default').addClass('btn-danger')
		setTimeout((() ->
			btn.addClass('btn-default').removeClass('btn-danger')
		), 2000)

startEditTransaction = (id) ->
	editId = id
	clearEditorModal(true)
	if (id == 0)
		editorModal['_createOnly'].show()
		editorModal['_editOnly'].hide()
	else
		editorModal['_createOnly'].hide()
		editorModal['_editOnly'].show()
		populateEditorModal(id)

	editorModal['_modal'].modal('show')

saveTransaction = () ->
	setEditorModalLock(true)
	$.post("/transactions/edit/#{editId}", {
		transaction_date: editorModal['transaction-date'].val()
		effective_date: editorModal['effective-date'].val()
		account: editorModal['account'].val()
		payee: editorModal['payee'].val()
		category: editorModal['category'].val()
		amount: editorModal['amount'].val()
		memo: editorModal['memo'].val().trim() || null
	}).done(() ->
		dataTable.ajax.reload()
		toastr.success('Transaction saved!')
		setEditorModalLock(false)
		if (!editorModal['add-another'].is(':checked') || editId != 0)
			clearEditorModal(true)
			editorModal['_modal'].modal('hide')
		else
			clearEditorModal(false)
			editorModal['transaction-date'].focus()
	).fail(() ->
		toastr.error('Sorry, that transaction couldn\'t be saved!')
		setEditorModalLock(false)
	)

initSettingsModal = () ->
	settingsModal['_modal'] = $('#settings-modal')
	settingsModal['_form'] = $('#settings-form')
	settingsModal['date-display-mode'] = settingsModal['_modal'].find('#date-display-mode')
	settingsModal['show-future-transactions'] = settingsModal['_modal'].find('#show-future-transactions')
	settingsModal['save-btn'] = editorModal['_modal'].find('#save-settings-btn')

	settingsModal['_form'].submit((e) ->
		if ($(this).valid())
			saveSettings()
		e.preventDefault()
	)

	$('#settings-btn').click(() -> openSettings())

populateSettingsModal = () ->
	settingsModal['date-display-mode'].val(window.user.settings['transactions_settings_date_display_mode'])
	settingsModal['show-future-transactions'].val(window.user.settings['transactions_settings_show_future_transactions'])

setSettingsModalLock = (locked) ->
	settingsModal['date-display-mode'].prop('disabled', locked)
	settingsModal['show-future-transactions'].prop('disabled', locked)
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
		'transactions_settings_date_display_mode': settingsModal['date-display-mode'].val()
		'transactions_settings_show_future_transactions': settingsModal['show-future-transactions'].val()
	}).done(() ->
		setSettingsModalLock(false)
		window.user.settings['transactions_settings_date_display_mode'] = settingsModal['date-display-mode'].val()
		window.user.settings['transactions_settings_show_future_transactions'] = settingsModal['show-future-transactions'].val()
		dataTable.ajax.reload()
		settingsModal['_modal'].modal('hide')
	).fail(() ->
		setSettingsModalLock(false)
		toastr.error('Sorry, those settings couldn\'t be saved!')
	)
