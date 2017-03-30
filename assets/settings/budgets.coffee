editor = {}
editId = 0
dataTable = null

actionsHtml = """
<div class="btn-group">
	<button class="btn btn-mini btn-default edit-btn" data-id="__ID__"><i class="fa fa-fw fa-pencil"></i></button>
</div>
"""

currentData = {}

activeOnlyCheckbox = $('#active-only')

$(document).ready(() ->
	initDataTable()
	#initEditor()

	activeOnlyCheckbox.change(() -> dataTable.ajax.reload())
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
				currentData = {}
				displayData = []
				for d in raw.data
					currentData[d['id']] = d
					displayData.push([
						d['name'] + (if (d['type'] == 'bill') then ' (Bill)' else '')
						window.formatters.formatBudgetSpan(d['start_date'], d['end_date'])
						window.formatters.formatCurrency(d['amount'])
						actionsHtml.replace(///__ID__///g, d['id'])
					])
				return displayData
		}

		drawCallback: () ->
	#initRowButtons()
	})
