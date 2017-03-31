actionsHtml = """
<div class="btn-group">
	<a href="/settings/budgets/edit/__ID__" class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></a>
</div>
"""

nameHtml = """
<div class="checkbox">
	<label>
		<input type="checkbox" data-id="__ID__" class="clone-checkbox" />
		__NAME__
	</label>
</div>
"""

checkedBudgets = []
dataTable = null

cloneModal = {}
activeOnlyCheckbox = $('#active-only')
cloneBtn = $('.clone-btn')

$(document).ready(() ->
	initDataTable()
	initCloneModal()
	clearCloneModal()

	activeOnlyCheckbox.change(() -> dataTable.ajax.reload())
	cloneBtn.click(() -> startClone())
)

initDataTable = () ->
	dataTable = $('#budgets').DataTable({
		paging: true
		lengthMenu: [
			[25, 50, 100]
			[25, 50, 100]
		]
		order: [[1, 'desc']]
		columnDefs: [
			{ targets: [1], orderable: true }
			{ targets: [2], className: 'currency' }
			{ targets: '_all', orderable: false }
		]

		serverSide: true
		ajax: {
			url: '/settings/budgets/data'
			type: 'get'
			data: (d) ->
				d['activeOnly'] = activeOnlyCheckbox.is(':checked')
				return d
			dataSrc: (raw) ->
				displayData = []
				for d in raw.data
					name = d['name'] + (if (d['type'] == 'bill') then ' (Bill)' else '')
					displayData.push([
						nameHtml.replace(///__ID__///g, d['id']).replace(///__NAME__///g, name)
						window.formatters.formatBudgetSpan(d['start_date'], d['end_date'])
						window.formatters.formatCurrency(d['amount'])
						actionsHtml.replace(///__ID__///g, d['id'])
					])
				return displayData
		}

		drawCallback: () -> onTableReload()
	})

onTableReload = () ->
	$('.clone-checkbox').change(() -> onCheckedBudgetsChange())

initCloneModal = () ->
	cloneModal['_modal'] = $('#clone-modal')
	cloneModal['_form'] = $('#clone-form')
	cloneModal['qty'] = $('.clone-qty')
	cloneModal['start-date'] = cloneModal['_modal'].find('#start-date')
	cloneModal['end-date'] = cloneModal['_modal'].find('#end-date')
	cloneModal['save-btn'] = cloneModal['_modal'].find('#save-btn')

	cloneModal['_modal'].on('shown.bs.modal', () ->
		cloneModal['start-date'].focus()
	)

	cloneModal['_form'].submit((e) ->
		e.preventDefault()
		if ($(this).valid())
			doClone()
	)

clearCloneModal = () ->
	now = new Date()
	startDate = new Date(now.getFullYear(), now.getMonth(), 1)
	endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0)
	cloneModal['start-date'].val(new Date(startDate.getTime() + 12 * 60 * 60 * 1000).toJSON().slice(0, 10))
	cloneModal['end-date'].val(new Date(endDate.getTime() + 12 * 60 * 60 * 1000).toJSON().slice(0, 10))

setCloneModalLock = (locked) ->
	cloneModal['start-date'].prop('disabled', locked)
	cloneModal['end-date'].prop('disabled', locked)
	cloneModal['save-btn'].prop('disabled', locked)
	if (locked)
		cloneModal['save-btn'].find('i').removeClass('fa-copy').addClass('fa-circle-o-notch').addClass('fa-spin')
	else
		cloneModal['save-btn'].find('i').addClass('fa-copy').removeClass('fa-circle-o-notch').removeClass('fa-spin')

onCheckedBudgetsChange = () ->
	checkedBudgets = $('.clone-checkbox:checked')
	if (checkedBudgets.length > 0)
		cloneBtn.prop('disabled', false)
	else
		cloneBtn.prop('disabled', true)

startClone = () ->
	cloneModal['qty'].html(checkedBudgets.length)
	cloneModal['_modal'].modal('show')

doClone = () ->
	setCloneModalLock(true)
	$.post("/settings/budgets/clone", {
		startDate: cloneModal['start-date'].val()
		endDate: cloneModal['end-date'].val()
		budgetIds: ($(b).data('id') for b in checkedBudgets)
	}).done(() ->
		dataTable.ajax.reload()
		toastr.success('Budget(s) cloned!')
		cloneModal['_modal'].modal('hide')
		clearCloneModal()
		setCloneModalLock(false)
	).fail(() ->
		toastr.error('Sorry, the budget(s) couldn\'t be cloned!')
		setCloneModalLock(false)
	)
