saveOrdering = () ->
	orders = {}
	accounts = $('#accounts .list-group-item')
	for a, i in accounts
		orders[$(a).attr('data-id')] = i
	$.post('/settings/accounts/reorder', orders)


updateEnabledButtons = () ->
	accounts = $('#accounts .list-group-item')
	for a, i in accounts
		$(a).find('.move-up').fadeTo(0, if (i == 0) then 0.4 else 1.0)
		$(a).find('.move-down').fadeTo(0, if (i == accounts.length - 1) then 0.4 else 1.0)


move = (element, dir) ->
	accounts = $('#accounts .list-group-item')
	index = element.index()

	if (index == 0 && dir == -1)
		return
	if (index == accounts.length - 1 && dir == 1)
		return

	if (dir == -1)
		element.prev().before(element)
	else
		element.before(element.next())

	updateEnabledButtons()
	saveOrdering()


$('.move-up').click(() -> move($(this).closest('.list-group-item'), -1))


$('.move-down').click(() -> move($(this).closest('.list-group-item'), 1))


$(document).ready(() ->
	updateEnabledButtons()
)
