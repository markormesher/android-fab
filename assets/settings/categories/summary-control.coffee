$(document).ready(() ->

	$('td input[type=checkbox]').click((e) -> e.stopPropagation())
	$('td').click(() ->
		$(this).find('input[type=checkbox]').click()
	)

	$('td input[type=checkbox]').change(() ->
		id = $(this).attr('name')
		inChecked = $('tr#' + id).find('input[value="in"]').is(':checked')
		outChecked = $('tr#' + id).find('input[value="out"]').is(':checked')
		value = if (inChecked && outChecked)
			'both'
		else if (inChecked)
			'in'
		else if (outChecked)
			'out'
		else
			null

		$.post("/settings/categories/set-summary-visibility/#{id}", { value: value })
	)
)
