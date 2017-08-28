package uk.co.markormesher.android_fab.app

import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.widget.Toast
import kotlinx.android.synthetic.main.demo_activity.*
import uk.co.markormesher.android_fab.FloatingActionButton

class DemoActivity: AppCompatActivity() {

	private val TOP_START = FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_START)
	private val TOP_END = FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_END)
	private val BOTTOM_START = FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_START)
	private val BOTTOM_END = FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_END)

	private val BUTTON_BG_COLOURS = intArrayOf(
			0xff0099ff.toInt(),
			0xffff9900.toInt(),
			0xffff0099.toInt(),
			0xff9900ff.toInt()
	)

	private val ICONS = intArrayOf(
			R.drawable.ic_add,
			R.drawable.ic_cloud,
			R.drawable.ic_done,
			R.drawable.ic_swap_horiz,
			R.drawable.ic_swap_vert
	)

	private var buttonPosition = BOTTOM_END
	private var buttonBackgroundColour = 0
	private var buttonIcon = 0

	private var activeToast: Toast? = null
	private var clickCounter = 0

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.demo_activity)

		if (savedInstanceState != null) {
			buttonPosition = savedInstanceState.getInt("buttonPosition")
			buttonBackgroundColour = savedInstanceState.getInt("buttonBackgroundColour")
			buttonIcon = savedInstanceState.getInt("buttonIcon")
		}

		initControls()

		setButtonPosition(buttonPosition)
		setButtonBackgroundColour(buttonBackgroundColour)
		setButtonIcon(buttonIcon)

		fab.setOnClickListener { toast(getString(R.string.toast_click, ++clickCounter)) }
	}

	override fun onSaveInstanceState(outState: Bundle) {
		super.onSaveInstanceState(outState)
		outState.putInt("buttonPosition", buttonPosition)
		outState.putInt("buttonBackgroundColour", buttonBackgroundColour)
		outState.putInt("buttonIcon", buttonIcon)
	}

	private fun initControls() {
		setButtonPositionTopStart.setOnClickListener { setButtonPosition(TOP_START) }
		setButtonPositionTopEnd.setOnClickListener { setButtonPosition(TOP_END) }
		setButtonPositionBottomStart.setOnClickListener { setButtonPosition(BOTTOM_START) }
		setButtonPositionBottomEnd.setOnClickListener { setButtonPosition(BOTTOM_END) }

		setButtonBackgroundColour1.setOnClickListener { setButtonBackgroundColour(0) }
		setButtonBackgroundColour2.setOnClickListener { setButtonBackgroundColour(1) }
		setButtonBackgroundColour3.setOnClickListener { setButtonBackgroundColour(2) }
		setButtonBackgroundColour4.setOnClickListener { setButtonBackgroundColour(3) }

		setButtonIcon1.setOnClickListener { setButtonIcon(0) }
		setButtonIcon2.setOnClickListener { setButtonIcon(1) }
		setButtonIcon3.setOnClickListener { setButtonIcon(2) }
		setButtonIcon4.setOnClickListener { setButtonIcon(3) }
		setButtonIcon5.setOnClickListener { setButtonIcon(4) }
	}

	private fun updateDisabledControls() {
		setButtonPositionTopStart.isEnabled = buttonPosition != TOP_START
		setButtonPositionTopEnd.isEnabled = buttonPosition != TOP_END
		setButtonPositionBottomStart.isEnabled = buttonPosition != BOTTOM_START
		setButtonPositionBottomEnd.isEnabled = buttonPosition != BOTTOM_END

		setButtonBackgroundColour1.isEnabled = buttonBackgroundColour != 0
		setButtonBackgroundColour2.isEnabled = buttonBackgroundColour != 1
		setButtonBackgroundColour3.isEnabled = buttonBackgroundColour != 2
		setButtonBackgroundColour4.isEnabled = buttonBackgroundColour != 3

		setButtonIcon1.isEnabled = buttonIcon != 0
		setButtonIcon2.isEnabled = buttonIcon != 1
		setButtonIcon3.isEnabled = buttonIcon != 2
		setButtonIcon4.isEnabled = buttonIcon != 3
		setButtonIcon5.isEnabled = buttonIcon != 4
	}

	private fun toast(str: String) {
		activeToast?.cancel()
		activeToast = Toast.makeText(this, str, Toast.LENGTH_SHORT)
		activeToast?.show()
	}

	private fun setButtonPosition(buttonPosition: Int) {
		this.buttonPosition = buttonPosition
		fab.setButtonPosition(buttonPosition)
		updateDisabledControls()
	}

	private fun setButtonBackgroundColour(buttonBackgroundColour: Int) {
		this.buttonBackgroundColour = buttonBackgroundColour
		fab.setButtonBackgroundColour(BUTTON_BG_COLOURS[buttonBackgroundColour])
		updateDisabledControls()
	}

	private fun setButtonIcon(buttonIcon: Int) {
		this.buttonIcon = buttonIcon
		fab.setButtonIconResource(ICONS[buttonIcon])
		updateDisabledControls()
	}
}
