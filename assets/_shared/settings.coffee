settingsModal = null
settingsInputs = null
settingsSavingMessage = null
settingsSavedMessage = null
settingsMessageTimeout = null

$(document).ready(() ->
	initSettingsModals()
	populateSettings()
)

initSettingsModals = () ->
	settingsModal = $('#settings-modal')
	settingsInputs = $('.settings-input')
	settingsSavingMessage = $('.settings-saving')
	settingsSavedMessage = $('.settings-saved')

	$('.open-settings-modal-btn').click(() -> settingsModal.modal('show'))
	settingsInputs.change(() -> saveSetting($(this)))

populateSettings = () ->
	settingsInputs.each(() ->
		key = $(this).attr('name')
		$(this).val(window.user.settings[key])
	)

setSettingsLock = (locked) ->
	settingsInputs.prop('disabled', locked)
	clearTimeout(settingsMessageTimeout)
	if (locked)
		settingsSavingMessage.show()
		settingsSavedMessage.hide()
	else
		settingsSavingMessage.hide()
		settingsSavedMessage.show()
		settingsMessageTimeout = setTimeout((() -> settingsSavedMessage.fadeOut()), 2000)

saveSetting = (input) ->
	key = input.attr('name')
	value = input.val()
	data = {}
	data[key] = value

	setSettingsLock(true)
	$.post('/users/settings', data).done(() ->
		setSettingsLock(false)
		window.user.settings[key] = value
		$(document).trigger('settings:updated')
	).fail(() ->
		setSettingsLock(false)
		toastr.error('Sorry, those settings couldn\'t be saved!')
	)
