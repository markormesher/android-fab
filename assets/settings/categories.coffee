actionsHtml = """
<div class="btn-group">
	<button class="btn btn-mini btn-default delete-btn" data-id="__ID__"><i class="fa fa-fw fa-trash"></i></button>
	<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
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
	dataTable = $('#categories').DataTable({
		paging: true
		lengthMenu: [
			[25, 50, 100]
			[25, 50, 100]
		]
		order: [[0, 'asc']]
		columnDefs: [
			{ targets: [0], orderable: true }
			{ targets: '_all', orderable: false }
		]

		serverSide: true
		ajax: {
			url: '/settings/categories/data'
			type: 'get'
			dataSrc: (raw) ->
				currentData = {}
				displayData = []
				for d in raw.data
					currentData[d['id']] = d
					isInType = d['summary_visibility'] == 'in' || d['summary_visibility'] == 'both'
					isOutType = d['summary_visibility'] == 'out' || d['summary_visibility'] == 'both'
					displayData.push([
						d['name'] + (if (d['type'] == 'memo') then ' <i class="fa fa-fw fa-exchange text-muted" title="Memo account"></i>' else '')
						'<input type="checkbox" value="in" data-id="' + d['id'] + '" ' + (if (isInType) then 'checked="checked"' else '') + '/>'
						'<input type="checkbox" value="out" data-id="' + d['id'] + '" ' + (if (isOutType) then 'checked="checked"' else '') + '/>'
						actionsHtml.replace(///__ID__///g, d['id'])
					])
				return displayData
		}

		drawCallback: onTableReload
	})

onTableReload = () ->
	$('.delete-btn').click(() -> deleteCategory($(this), $(this).data('id')))
	$('.edit-btn').click(() -> startEditCategory($(this).data('id')))
	$('td input[type=checkbox]').click((e) -> e.stopPropagation())
	$('td').click(() ->
		$(this).find('input[type=checkbox]').click()
	)
	$('td input[type=checkbox]').change(() -> toggleCategoryVisibility($(this)))

initEditorModal = () ->
	editorModal['_modal'] = $('#editor-modal')
	editorModal['_form'] = $('#editor-form')
	editorModal['_createOnly'] = editorModal['_modal'].find('.create-only')
	editorModal['_editOnly'] = editorModal['_modal'].find('.edit-only')
	editorModal['name'] = editorModal['_modal'].find('#name')
	editorModal['type'] = editorModal['_modal'].find('#type')
	editorModal['save-btn'] = editorModal['_modal'].find('#save-btn')

	editorModal['_modal'].on('shown.bs.modal', () ->
		editorModal['name'].focus()
	)

	$('#add-btn').click(() -> startEditCategory(0))

	editorModal['name'].keydown((e) ->
		if ((e.ctrlKey || e.metaKey) && (e.keyCode == 13 || e.keyCode == 10))
			editorModal['_form'].submit()
	)

	editorModal['_form'].submit((e) ->
		if ($(this).valid())
			saveCategory()
		e.preventDefault()
	)

clearEditorModal = () ->
	editorModal['name'].val('')

populateEditorModal = (id) ->
	category = currentData[id]
	if (category)
		editorModal['name'].val(category['name'])
		editorModal['type'].val(category['type'])

setEditorModalLock = (locked) ->
	editorModal['name'].prop('disabled', locked)
	editorModal['type'].prop('disabled', locked)
	editorModal['save-btn'].prop('disabled', locked)
	if (locked)
		editorModal['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editorModal['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

deleteCategory = (btn, id) ->
	if (btn.hasClass('btn-danger'))
		btn.find('i').removeClass('fa-trash').addClass('fa-circle-o-notch').addClass('fa-spin')
		$.post(
			"/settings/categories/delete/#{id}"
		).done(() ->
			dataTable.ajax.reload()
		).fail(() ->
			toastr.error('Sorry, that category couldn\'t be deleted!')
		)
	else
		btn.removeClass('btn-default').addClass('btn-danger')
		setTimeout((() ->
			btn.addClass('btn-default').removeClass('btn-danger')
		), 2000)

startEditCategory = (id) ->
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

saveCategory = () ->
	setEditorModalLock(true)
	$.post("/settings/categories/edit/#{editId}", {
		name: editorModal['name'].val()
		type: editorModal['type'].val()
	}).done(() ->
		dataTable.ajax.reload()
		toastr.success('Category saved!')
		editorModal['_modal'].modal('hide')
		clearEditorModal()
		setEditorModalLock(false)
	).fail(() ->
		toastr.error('Sorry, that category couldn\'t be saved!')
		setEditorModalLock(false)
	)

toggleCategoryVisibility = (checkbox) ->
	id = checkbox.data('id')
	row = checkbox.closest('tr')
	inChecked = row.find('input[value="in"]').is(':checked')
	outChecked = row.find('input[value="out"]').is(':checked')
	value = if (inChecked && outChecked)
		'both'
	else if (inChecked)
		'in'
	else if (outChecked)
		'out'
	else
		null

	$.post("/settings/categories/set-summary-visibility/#{id}", { value: value }).fail(() -> toastr.error('Sorry, that couldn\'t be saved!'))
