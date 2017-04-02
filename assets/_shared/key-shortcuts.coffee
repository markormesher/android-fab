lastKey = ''

$('body').keypress((event) ->
	target = $(event.target)
	if (target.is('input') || target.is('textarea')) then return

	key = event.key

	switch lastKey + key
		when 'gd' then window.location.href = '/'
		when 'gt' then window.location.href = '/transactions'

		when 'rb' then window.location.href = '/reports/balance-history'

		when 'sa' then window.location.href = '/settings/accounts'
		when 'sb' then window.location.href = '/settings/budgets'
		when 'sc' then window.location.href = '/settings/categories'

		when 'ap' then window.location.href = '/users/profile'
		when 'al' then window.location.href = '/auth/logout'

		else switch key
			when 'c' then $('.create-btn').click()
			when '?' then $('#key-shortcut-modal').modal('show')

	lastKey = key
)
