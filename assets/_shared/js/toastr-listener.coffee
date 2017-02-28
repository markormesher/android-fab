$(document).ready(() ->
	for type, messages of toastrMessages
		for msg in messages
			switch type
				when 'error' then toastr.error(msg)
				when 'info' then toastr.info(msg)
				when 'success' then toastr.success(msg)
				when 'warning' then toastr.warning(msg)
)
