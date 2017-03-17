editor = {}
editId = 0
dataTable = null

actionsHtml = """
<div class="btn-group">
	<button class="btn btn-mini btn-default delete-btn" data-id="__ID__"><i class="fa fa-fw fa-trash"></i></button>
	<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
</div>
"""

currentData = {}

$(document).ready(() ->
	initDataTable()
	initEditor()
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
						d['name']
						'<input type="checkbox" value="in" data-id="' + d['id'] + '" ' + (if (isInType) then 'checked="checked"' else '') + '/>'
						'<input type="checkbox" value="out" data-id="' + d['id'] + '" ' + (if (isOutType) then 'checked="checked"' else '') + '/>'
						actionsHtml.replace(///__ID__///g, d['id'])
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
	editor['save-btn'] = editor['_modal'].find('#save-btn')

	editor['_modal'].on('shown.bs.modal', () ->
		editor['name'].focus()
	)

	$('#add-btn').click(() -> editCategory(0))

	editor['name'].keydown((e) ->
		if ((e.ctrlKey || e.metaKey) && (e.keyCode == 13 || e.keyCode == 10))
			editor['_form'].submit()
	)

	editor['_form'].submit((e) ->
		if ($(this).valid())
			saveCategory()
		e.preventDefault()
	)

initRowButtons = () ->
	$('.delete-btn').click(() -> deleteCategory($(this), $(this).data('id')))
	$('.edit-btn').click(() -> editCategory($(this).data('id')))
	$('td input[type=checkbox]').click((e) -> e.stopPropagation())
	$('td').click(() ->
		$(this).find('input[type=checkbox]').click()
	)
	$('td input[type=checkbox]').change(() -> toggleCategoryVisibility($(this)))

clearEditor = () -> editor['name'].val('')

populateEditor = (id) ->
	category = currentData[id]
	if (category)
		editor['name'].val(category['name'])

setEditorLock = (locked) ->
	editor['name'].prop('disabled', locked)
	editor['save-btn'].prop('disabled', locked)
	if (locked)
		editor['save-btn'].find('i').removeClass('fa-save').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		editor['save-btn'].find('i').addClass('fa-save').removeClass('fa-circle-o-notch').removeClass('fa-spin')

deleteCategory = (btn, id) ->
	if (btn.hasClass('btn-danger'))
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

editCategory = (id) ->
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

saveCategory = () ->
	setEditorLock(true)
	$.post("/settings/categories/edit/#{editId}", {
		name: editor['name'].val()
	}).done(() ->
		dataTable.ajax.reload()
		setEditorLock(false)
		clearEditor()
		editor['_modal'].modal('hide')
	).fail(() ->
		toastr.error('Sorry, that category couldn\'t be saved!')
		setEditorLock(false)
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

	$.post("/settings/categories/set-summary-visibility/#{id}", { value: value })
