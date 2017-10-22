package uk.co.markormesher.android_fab.app

import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.widget.Toast
import kotlinx.android.synthetic.main.demo_activity.*
import uk.co.markormesher.android_fab.FloatingActionButton

class DemoActivity: AppCompatActivity() {

	private val BUTTON_POSITIONS = arrayOf(
			Pair("Bottom, end", FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_END)),
			Pair("Bottom, start", FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_START)),
			Pair("Top, start", FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_START)),
			Pair("Top, end", FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_END))
	)

	private val BUTTON_BG_COLOURS = arrayOf(
			Pair("Blue", 0xff0099ff.toInt()),
			Pair("Purple", 0xff9900ff.toInt()),
			Pair("Teal", 0xff00ff99.toInt()),
			Pair("Pink", 0xffff0099.toInt()),
			Pair("Orange", 0xffff9900.toInt())
	)

	private val BUTTON_ICONS = arrayOf(
			Pair("Add", R.drawable.ic_add),
			Pair("Cloud", R.drawable.ic_cloud),
			Pair("Done", R.drawable.ic_done),
			Pair("Swap H", R.drawable.ic_swap_horiz),
			Pair("Swap V", R.drawable.ic_swap_vert)
	)

	private val SPEED_DIAL_SIZES = arrayOf(
			Pair("None", 0),
			Pair("1 item", 1),
			Pair("2 items", 2),
			Pair("3 items", 3),
			Pair("4 items", 4)
	)

	private var buttonPosition = 0
	private var buttonBackgroundColour = 0
	private var buttonIcon = 0
	private var speedDialSize = 0

	private var activeToast: Toast? = null
	private var clickCounter = 0

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		restoreSavedInstanceState(savedInstanceState)
		setContentView(R.layout.demo_activity)

		table_layout.setColumnStretchable(1, true)
		fab.setOnClickListener { toast(getString(R.string.toast_click, ++clickCounter)) }

		initControls()

		updateButtonPosition()
		updateButtonBackgroundColour()
		updateButtonIcon()
		updateSpeedDialSize()
	}

	override fun onSaveInstanceState(outState: Bundle) {
		super.onSaveInstanceState(outState)
		outState.putInt("buttonPosition", buttonPosition)
		outState.putInt("buttonBackgroundColour", buttonBackgroundColour)
		outState.putInt("buttonIcon", buttonIcon)
		outState.putInt("speedDialSize", speedDialSize)
	}

	private fun restoreSavedInstanceState(savedInstanceState: Bundle?) {
		if (savedInstanceState != null) {
			buttonPosition = savedInstanceState.getInt("buttonPosition")
			buttonBackgroundColour = savedInstanceState.getInt("buttonBackgroundColour")
			buttonIcon = savedInstanceState.getInt("buttonIcon")
			speedDialSize = savedInstanceState.getInt("speedDialSize")
		}
	}

	private fun initControls() {
		set_button_position_next.setOnClickListener {
			buttonPosition = (buttonPosition + 1).rem(BUTTON_POSITIONS.size)
			updateButtonPosition()
		}
		set_button_position_prev.setOnClickListener {
			buttonPosition = (buttonPosition + BUTTON_POSITIONS.size - 1).rem(BUTTON_POSITIONS.size)
			updateButtonPosition()
		}

		set_button_background_colour_next.setOnClickListener {
			buttonBackgroundColour = (buttonBackgroundColour + 1).rem(BUTTON_BG_COLOURS.size)
			updateButtonBackgroundColour()
		}
		set_button_background_colour_prev.setOnClickListener {
			buttonBackgroundColour = (buttonBackgroundColour + BUTTON_BG_COLOURS.size - 1).rem(BUTTON_BG_COLOURS.size)
			updateButtonBackgroundColour()
		}

		set_button_icon_next.setOnClickListener {
			buttonIcon = (buttonIcon + 1).rem(BUTTON_ICONS.size)
			updateButtonIcon()
		}
		set_button_icon_prev.setOnClickListener {
			buttonIcon = (buttonIcon + BUTTON_ICONS.size - 1).rem(BUTTON_ICONS.size)
			updateButtonIcon()
		}

		set_speed_dial_size_next.setOnClickListener {
			speedDialSize = (speedDialSize + 1).rem(SPEED_DIAL_SIZES.size)
			updateSpeedDialSize()
		}
		set_speed_dial_size_prev.setOnClickListener {
			speedDialSize = (speedDialSize + SPEED_DIAL_SIZES.size - 1).rem(SPEED_DIAL_SIZES.size)
			updateSpeedDialSize()
		}
	}

	private fun toast(str: String) {
		activeToast?.cancel()
		activeToast = Toast.makeText(this, str, Toast.LENGTH_SHORT)
		activeToast?.show()
	}

	private fun updateButtonPosition() {
		button_position.text = BUTTON_POSITIONS[buttonPosition].first
		fab.setButtonPosition(BUTTON_POSITIONS[buttonPosition].second)
	}

	private fun updateButtonBackgroundColour() {
		button_background_colour.text = BUTTON_BG_COLOURS[buttonBackgroundColour].first
		fab.setButtonBackgroundColour(BUTTON_BG_COLOURS[buttonBackgroundColour].second)
	}

	private fun updateButtonIcon() {
		button_icon.text = BUTTON_ICONS[buttonIcon].first
		fab.setButtonIconResource(BUTTON_ICONS[buttonIcon].second)
	}

	private fun updateSpeedDialSize() {
		speed_dial_size.text = SPEED_DIAL_SIZES[speedDialSize].first
		// TODO: update and set adapter
	}
}
