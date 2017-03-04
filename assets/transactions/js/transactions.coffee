editor = {}
editId = 0
dataTable = null

actionsHtml = """
<div class="text-center">
	<div class="btn-group">
		<button class="btn btn-mini btn-default delete-btn" data-id="__ID__"><i class="fa fa-fw fa-trash"></i></button>
		<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
	</div>
</div>
"""

currentData = {}

$(document).ready(() ->
	initDataTable()
	initEditor()
)

initDataTable = () ->
	dataTable = $('#transactions').DataTable({
		paging: true
		lengthMenu: [
			[25, 50, 100, -1]
			[25, 50, 100, 'All']
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

		drawCallback: () ->
			initRowButtons()
	})

formatDatePair = (trDate, efDate) ->
	if (trDate == efDate)
		return window.formatters.formatDate(trDate)
	else
		return "#{window.formatters.formatDate(trDate)} <i class=\"fa fa-fw fa-info-circle text-muted\" title=\"Effective date: #{window.formatters.formatDate(efDate)}\"></i>"

initEditor = () ->
	editor['_modal'] = $('#editor-modal')
	editor['_form'] = $('#editor-form')
	editor['_createOnly'] = editor['_modal'].find('.create-only')
	editor['_editOnly'] = editor['_modal'].find('.edit-only')
	editor['transaction-date'] = editor['_modal'].find('#transaction-date')
	editor['effective-date'] = editor['_modal'].find('#effective-date')
	editor['account'] = editor['_modal'].find('#account')
	editor['payee'] = editor['_modal'].find('#payee')
	editor['category'] = editor['_modal'].find('#category')
	editor['amount'] = editor['_modal'].find('#amount')
	editor['memo'] = editor['_modal'].find('#memo')
	editor['add-another'] = editor['_modal'].find('#add-another')
	editor['save-btn'] = editor['_modal'].find('#save-btn')

	editor['_modal'].on('shown.bs.modal', () ->
		editor['transaction-date'].focus()
	)

	editor['payee'].autocomplete({
		source: payees
	})

	$('#add-btn').click(() -> editTransaction(0))
	$('#copy-date').click((e) ->
		e.preventDefault()
		editor['effective-date'].val(editor['transaction-date'].val())
	)

	editor['_form'].submit((e) ->
		if ($(this).valid())
			saveTransaction()
		e.preventDefault()
	)

initRowButtons = () ->
	$('.delete-btn').click(() -> deleteTransaction($(this), $(this).data('id')))
	$('.edit-btn').click(() -> editTransaction($(this).data('id')))

clearEditor = (clearDates) ->
	if (clearDates)
		editor['transaction-date'].val((new Date()).toJSON().slice(0, 10))
		editor['effective-date'].val((new Date()).toJSON().slice(0, 10))
	editor['account'].prop('selectedIndex', 0)
	editor['payee'].val('')
	editor['category'].prop('selectedIndex', 0)
	editor['amount'].val('')
	editor['memo'].val('')

populateEditor = (id) ->
	transaction = currentData[id]
	if (transaction)
		editor['transaction-date'].val((new Date(transaction['transaction_date'])).toJSON().slice(0, 10))
		editor['effective-date'].val((new Date(transaction['effective_date'])).toJSON().slice(0, 10))
		editor['account'].val(transaction['account_id'])
		editor['payee'].val(transaction['payee'])
		editor['category'].val(transaction['category_id'])
		editor['amount'].val(transaction['amount'].toFixed(2))
		editor['memo'].val(transaction['memo'])

setEditorLock = (locked) ->
	editor['transaction-date'].prop('disabled', locked)
	editor['effective-date'].prop('disabled', locked)
	editor['account'].prop('disabled', locked)
	editor['payee'].prop('disabled', locked)
	editor['category'].prop('disabled', locked)
	editor['amount'].prop('disabled', locked)
	editor['memo'].prop('disabled', locked)
	editor['save-btn'].prop('disabled', locked)
	if (locked)
		editor['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editor['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

deleteTransaction = (btn, id) ->
	if (btn.hasClass('btn-danger'))
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

editTransaction = (id) ->
	editId = id
	clearEditor(true)
	if (id == 0)
		editor['_createOnly'].show()
		editor['_editOnly'].hide()
	else
		editor['_createOnly'].hide()
		editor['_editOnly'].show()
		populateEditor(id)

	editor['_modal'].modal('show')

saveTransaction = () ->
	setEditorLock(true)
	$.post("/transactions/edit/#{editId}", {
		transaction_date: editor['transaction-date'].val()
		effective_date: editor['effective-date'].val()
		account: editor['account'].val()
		payee: editor['payee'].val()
		category: editor['category'].val()
		amount: editor['amount'].val()
		memo: editor['memo'].val().trim() || null
	}).done(() ->
		dataTable.ajax.reload()
		setEditorLock(false)
		if (!editor['add-another'].is(':checked') || editId != 0)
			clearEditor(true)
			editor['_modal'].modal('hide')
		else
			clearEditor(false)
			editor['transaction-date'].focus()
	).fail(() ->
		toastr.error('Sorry, that transaction couldn\'t be saved!')
		setEditorLock(false)
	)
