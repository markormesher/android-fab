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

editorModal = {}
dataTable = null

currentData = {}
editId = 0

$(document).ready(() ->
	initDataTable()
	initEditorModal()
)

initDataTable = () ->
	dataTable = $('#accounts').DataTable({
		paging: false
		order: []
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

		drawCallback: onTableReload
	})

onTableReload = () ->
	$('.delete-btn').click(() -> deleteAccount($(this), $(this).data('id')))
	$('.edit-btn').click(() -> startEditAccount($(this).data('id')))
	rows = $('#accounts tbody tr')
	rows.first().find('.move-up-btn').prop('disabled', true)
	rows.last().find('.move-down-btn').prop('disabled', true)
	$('.move-up-btn').click(() -> reOrderAccount($(this), -1))
	$('.move-down-btn').click(() -> reOrderAccount($(this), 1))

initEditorModal = () ->
	editorModal['_modal'] = $('#editor-modal')
	editorModal['_form'] = $('#editor-form')
	editorModal['_createOnly'] = editorModal['_modal'].find('.create-only')
	editorModal['_editOnly'] = editorModal['_modal'].find('.edit-only')
	editorModal['name'] = editorModal['_modal'].find('#name')
	editorModal['description'] = editorModal['_modal'].find('#description')
	editorModal['type'] = editorModal['_modal'].find('#type')
	editorModal['save-btn'] = editorModal['_modal'].find('#save-btn')

	editorModal['_modal'].on('shown.bs.modal', () ->
		editorModal['name'].focus()
	)

	$('#add-btn').click(() -> startEditAccount(0))

	for field in [editorModal['name'], editorModal['description']]
		field.keydown((e) ->
			if ((e.ctrlKey || e.metaKey) && (e.keyCode == 13 || e.keyCode == 10))
				editorModal['_form'].submit()
		)

	editorModal['_form'].submit((e) ->
		if ($(this).valid())
			saveAccount()
		e.preventDefault()
	)

clearEditorModal = () ->
	editorModal['name'].val('')
	editorModal['description'].val('')
	editorModal['type'].prop('selectedIndex', 0)

populateEditorModal = (id) ->
	account = currentData[id]
	if (account)
		editorModal['name'].val(account['name'])
		editorModal['description'].val(account['description'])
		editorModal['type'].val(account['type'])

setEditorModalLock = (locked) ->
	editorModal['name'].prop('disabled', locked)
	editorModal['save-btn'].prop('disabled', locked)
	if (locked)
		editorModal['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editorModal['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

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
		setTimeout((() ->
			btn.addClass('btn-default').removeClass('btn-danger')
		), 2000)

startEditAccount = (id) ->
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

saveAccount = () ->
	setEditorModalLock(true)
	$.post("/settings/accounts/edit/#{editId}", {
		name: editorModal['name'].val()
		description: editorModal['description'].val()
		type: editorModal['type'].val()
	}).done(() ->
		dataTable.ajax.reload()
		toastr.success('Account saved!')
		editorModal['_modal'].modal('hide')
		clearEditorModal()
		setEditorModalLock(false)
	).fail(() ->
		toastr.error('Sorry, that account couldn\'t be saved!')
		setEditorModalLock(false)
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
