prevBudgetsContainer = $('#prev-budgets-list')
prevBudgetsLabel = prevBudgetsContainer.find('span')
prevBudgetsList = prevBudgetsContainer.find('table')
prevBudgetsListInner = prevBudgetsList.find('tbody')
prevBudgetsNoneMessage = prevBudgetsContainer.find('p')
prevBudgetsLoading = $('#prev-budgets-loading')
categoryInput = $('#category_id')

$(document).ready(() ->
	updatePrevBudgets()
	categoryInput.change(() -> updatePrevBudgets())
)

updatePrevBudgets = () ->
	categoryInput.prop('disabled', true)
	prevBudgetsContainer.hide()
	prevBudgetsListInner.empty()
	prevBudgetsLoading.show()

	categoryId = categoryInput.val()
	categoryName = categoryInput.find('option:selected').text()

	$.get('/settings/budgets/prev-budgets', {
		categoryId: categoryId
	}).done((data) ->
		prevBudgetsLabel.html(categoryName)
		if (data.length == 0)
			prevBudgetsList.hide()
			prevBudgetsNoneMessage.show()
		else
			for budget in data
				prevBudgetsListInner.append(formatBudgetListItem(budget))
			prevBudgetsNoneMessage.hide()
			prevBudgetsList.show()

		prevBudgetsContainer.show()
	).fail(() ->
		toastr.error('Sorry, previous budgets couldn\'t be loaded!')
	).always(() ->
		categoryInput.prop('disabled', false)
		prevBudgetsLoading.hide()
	)

formatBudgetListItem = (budget) ->
	performance = Math.round((budget['spend'] / budget['amount']) * 100)
	if (performance <= 0)
		performanceClass = 'muted'
	else if (performance <= 50)
		performanceClass = 'info'
	else if (performance <= 100)
		performanceClass = 'success'
	else
		performanceClass = 'danger'
	'<tr>' +
		'<td>' + window.formatters.formatBudgetSpan(budget['start_date'], budget['end_date']) + '</td>' +
		'<td>' + window.formatters.formatCurrency(budget['amount']) + '</td>' +
		'<td>' + window.formatters.formatCurrency(budget['spend']) + '</td>' +
		'<td class="text-' + performanceClass + '">' + performance + '%</td>' +
		'</tr>'
