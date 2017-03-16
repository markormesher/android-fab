editor = {}
editId = 0
dataTable = null

actionsHtml = """
<div class="btn-group">
	<button class="btn btn-mini btn-default delete-btn" data-id="__ID__"><i class="fa fa-fw fa-trash"></i></button>
	<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
</div>
"""

orderingHtml = """
<div class="btn-group">
	<button class="btn btn-mini btn-default move-up-btn" data-id="__ID__"><i class="fa fa-fw fa-angle-up"></i></button>
	<button class="btn btn-mini btn-default move-down-btn" data-id="__ID__"><i class="fa fa-fw fa-angle-down"></i></button>
</div>
"""
currentData = {}

$(document).ready(() ->
	initDataTable()
	initEditor()
)

initDataTable = () ->
	dataTable = $('#accounts').DataTable({
		paging: false
		order: [[2, 'asc']]
		columnDefs: [
			{ targets: '_all', orderable: false }
		]

		serverSide: true
		ajax: {
			url: '/settings/accounts/data'
			type: 'get'
			dataSrc: (raw) ->
				currentData = {}
				displayData = []
				for d in raw.data
					currentData[d['id']] = d
					displayData.push([
						d['name']
						actionsHtml.replace(///__ID__///g, d['id'])
						orderingHtml.replace(///__ID__///g, d['id'])
					])
				return displayData
		}

		drawCallback: () ->
			initRowButtons()
	})

initEditor = () ->
	editor['_modal'] = $('#editor-modal')
	editor['_form'] = $('#editor-form')
	editor['_createOnly'] = editor['_modal'].find('.create-only')
	editor['_editOnly'] = editor['_modal'].find('.edit-only')
	editor['name'] = editor['_modal'].find('#name')
	editor['description'] = editor['_modal'].find('#description')
	editor['type'] = editor['_modal'].find('#type')
	editor['save-btn'] = editor['_modal'].find('#save-btn')

	editor['_modal'].on('shown.bs.modal', () ->
		editor['name'].focus()
	)

	$('#add-btn').click(() -> editAccount(0))

	for field in [editor['name'], editor['description']]
		field.keydown((e) ->
			if ((e.ctrlKey || e.metaKey) && (e.keyCode == 13 || e.keyCode == 10))
				editor['_form'].submit()
		)

	editor['_form'].submit((e) ->
		if ($(this).valid())
			saveAccount()
		e.preventDefault()
	)

initRowButtons = () ->
	$('.delete-btn').click(() -> deleteAccount($(this), $(this).data('id')))
	$('.edit-btn').click(() -> editAccount($(this).data('id')))
	rows = $('#accounts tbody tr')
	rows.first().find('.move-up-btn').prop('disabled', true)
	rows.last().find('.move-down-btn').prop('disabled', true)
	$('.move-up-btn').click(() -> reOrderAccount($(this), -1))
	$('.move-down-btn').click(() -> reOrderAccount($(this), 1))

clearEditor = () ->
	editor['name'].val('')
	editor['description'].val('')
	editor['type'].prop('selectedIndex', 0)

populateEditor = (id) ->
	account = currentData[id]
	if (account)
		editor['name'].val(account['name'])
		editor['description'].val(account['description'])
		editor['type'].val(account['type'])

setEditorLock = (locked) ->
	editor['name'].prop('disabled', locked)
	editor['save-btn'].prop('disabled', locked)
	if (locked)
		editor['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editor['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

deleteAccount = (btn, id) ->
	if (btn.hasClass('btn-danger'))
		$.post(
			"/settings/accounts/delete/#{id}"
		).done(() ->
			dataTable.ajax.reload()
		).fail(() ->
			toastr.error('Sorry, that account couldn\'t be deleted!')
		)
	else
		btn.removeClass('btn-default').addClass('btn-danger')
		setTimeout((() ->connectionLimit
			btn.addClass('btn-default').removeClass('btn-danger')
		), 2000)

editAccount = (id) ->
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

saveAccount = () ->
	setEditorLock(true)
	$.post("/settings/accounts/edit/#{editId}", {
		name: editor['name'].val()
		description: editor['description'].val()
		type: editor['type'].val()
	}).done(() ->
		dataTable.ajax.reload()
		setEditorLock(false)
		clearEditor()
		editor['_modal'].modal('hide')
	).fail(() ->
		toastr.error('Sorry, that account couldn\'t be saved!')
		setEditorLock(false)
	)

reOrderAccount = (btn, direction) ->
	$('.move-up-btn').prop('disabled', true)
	$('.move-down-btn').prop('disabled', true)

	id = btn.data('id')
	$.post("/settings/accounts/reorder/#{id}", {
		direction: direction
	}).done(() ->
		dataTable.ajax.reload()
	).fail(() ->
		toastr.error('Sorry, that account couldn\'t be moved!')
		dataTable.ajax.reload()
	)
