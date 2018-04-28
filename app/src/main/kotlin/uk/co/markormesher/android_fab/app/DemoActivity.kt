package uk.co.markormesher.android_fab.app

import android.content.Context
import android.graphics.Typeface
import android.os.*
import android.support.annotation.StringRes
import android.support.design.widget.Snackbar
import android.support.v7.app.AppCompatActivity
import android.view.KeyEvent
import android.view.Menu
import android.view.MenuItem
import android.view.MotionEvent
import android.widget.TextView
import android.widget.Toast
import kotlinx.android.synthetic.main.demo_activity.*
import uk.co.markormesher.android_fab.FloatingActionButton
import uk.co.markormesher.android_fab.SpeedDialMenuAdapter
import uk.co.markormesher.android_fab.SpeedDialMenuItem
import java.util.concurrent.ThreadLocalRandom

class DemoActivity: AppCompatActivity() {

	private val buttonShownOptions = arrayOf(
			Pair("Yes", true),
			Pair("No", false)
	)

	private val buttonPositionOptions = arrayOf(
			Pair("Bottom, end", FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_END)),
			Pair("Bottom, start", FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_START)),
			Pair("Top, start", FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_START)),
			Pair("Top, end", FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_END))
	)

	private val buttonBgColourOptions = arrayOf(
			Pair("Blue", 0xff0099ff.toInt()),
			Pair("Purple", 0xff9900ff.toInt()),
			Pair("Teal", 0xff00ff99.toInt()),
			Pair("Pink", 0xffff0099.toInt()),
			Pair("Orange", 0xffff9900.toInt())
	)

	private val buttonIconOptions = arrayOf(
			Pair("Add", R.drawable.ic_add),
			Pair("Cloud", R.drawable.ic_cloud),
			Pair("Done", R.drawable.ic_done),
			Pair("Swap H", R.drawable.ic_swap_horiz),
			Pair("Swap V", R.drawable.ic_swap_vert)
	)

	private val speedDialSizeOptions = arrayOf(
			Pair("None", 0),
			Pair("1 item", 1),
			Pair("2 items", 2),
			Pair("3 items", 3),
			Pair("4 items", 4)
	)

	private val contentCoverColourOptions = arrayOf(
			Pair("Faint White", 0xccffffff.toInt()),
			Pair("Full White", 0xffffffff.toInt()),
			Pair("Faint Blue", 0xcc0099ff.toInt()),
			Pair("Faint Purple", 0xcc9900ff.toInt()),
			Pair("Faint Teal", 0xcc00ff99.toInt()),
			Pair("Faint Pink", 0xccff0099.toInt()),
			Pair("Faint Orange", 0xccff9900.toInt())
	)

	private val snackbarEnabledOptions = arrayOf(
			Pair("Off", 0),
			Pair("On", 1)
	)

	private var buttonShown = 0
	private var buttonPosition = 0
	private var buttonBackgroundColour = 0
	private var buttonIcon = 0
	private var speedDialSize = 0
	private var contentCoverColour = 0
	private var snackbarEnabled = 0

	private var activeToast: Toast? = null
	private var snackbar: Snackbar? = null
	private var clickCounter = 0

	private var stressTestActive = false
	private val stressTestHandler = Handler(Looper.getMainLooper())
	private val random by lazy {
		if (Build.VERSION.SDK_INT >= 21) {
			ThreadLocalRandom.current()
		} else {
			throw UninitializedPropertyAccessException()
		}
	}

	private val speedDialMenuAdapter = object: SpeedDialMenuAdapter() {
		override fun getCount(): Int = speedDialSizeOptions[speedDialSize].second

		override fun getMenuItem(context: Context, position: Int): SpeedDialMenuItem = when (position) {
			0 -> SpeedDialMenuItem(context, R.drawable.ic_swap_horiz, "Item One")
			1 -> SpeedDialMenuItem(context, R.drawable.ic_swap_vert, "Item Two")
			2 -> SpeedDialMenuItem(context, R.drawable.ic_done, "Item Three")
			3 -> SpeedDialMenuItem(context, R.drawable.ic_cloud, "Item Four")
			else -> throw IllegalArgumentException("No menu item: $position")
		}

		override fun onMenuItemClick(position: Int): Boolean {
			toast(getString(R.string.toast_click, ++clickCounter))
			return true
		}

		override fun onPrepareItemLabel(context: Context, position: Int, label: TextView) {
			// make the first item bold if there are multiple items
			// (this isn't a design pattern, it's just to demo the functionality)
			if (position == 0 && speedDialSize > 1) {
				label.setTypeface(label.typeface, Typeface.BOLD)
			}
		}

		// rotate the "+" icon only
		override fun fabRotationDegrees(): Float = if (buttonIcon == 0) 135F else 0F
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		restoreSavedInstanceState(savedInstanceState)
		setContentView(R.layout.demo_activity)

		table_layout.setColumnStretchable(1, true)
		fab.setOnClickListener { toast(getString(R.string.toast_click, ++clickCounter)) }
		fab.speedDialMenuAdapter = speedDialMenuAdapter
		fab.contentCoverEnabled = true

		initControls()

		updateButtonShown()
		updateButtonPosition()
		updateButtonBackgroundColour()
		updateButtonIcon()
		updateSpeedDialSize()
		updateContentCoverColour()
		updateSnackbarEnabled()

		if (stressTestActive) {
			startStressTest()
		}
	}

	override fun onSaveInstanceState(outState: Bundle) {
		super.onSaveInstanceState(outState)
		outState.putInt("buttonShown", buttonShown)
		outState.putInt("buttonPosition", buttonPosition)
		outState.putInt("buttonBackgroundColour", buttonBackgroundColour)
		outState.putInt("buttonIcon", buttonIcon)
		outState.putInt("speedDialSize", speedDialSize)
		outState.putInt("contentCoverColour", contentCoverColour)
		outState.putInt("snackbarEnabled", snackbarEnabled)

		outState.putBoolean("stressTestActive", stressTestActive)
	}

	private fun restoreSavedInstanceState(savedInstanceState: Bundle?) {
		if (savedInstanceState != null) {
			buttonShown = savedInstanceState.getInt("buttonShown")
			buttonPosition = savedInstanceState.getInt("buttonPosition")
			buttonBackgroundColour = savedInstanceState.getInt("buttonBackgroundColour")
			buttonIcon = savedInstanceState.getInt("buttonIcon")
			speedDialSize = savedInstanceState.getInt("speedDialSize")
			contentCoverColour = savedInstanceState.getInt("contentCoverColour")
			snackbarEnabled = savedInstanceState.getInt("snackbarEnabled")

			stressTestActive = savedInstanceState.getBoolean("stressTestActive")
		}
	}

	override fun onCreateOptionsMenu(menu: Menu): Boolean {
		menuInflater.inflate(R.menu.demo_activity, menu)
		return true
	}

	override fun onOptionsItemSelected(item: MenuItem?): Boolean {
		if (item?.itemId == R.id.stress_test) {
			startStressTest()
			return true
		}

		return false
	}

	override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
		if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
			stressTestActive = false
			return true
		}

		return super.onKeyDown(keyCode, event)
	}

	private fun initControls() {
		set_button_shown_next.setOnClickListener {
			buttonShown = (buttonShown + 1).rem(buttonShownOptions.size)
			updateButtonShown()
		}
		set_button_shown_prev.setOnClickListener {
			buttonShown = (buttonShown + buttonShownOptions.size - 1).rem(buttonShownOptions.size)
			updateButtonShown()
		}

		set_button_position_next.setOnClickListener {
			buttonPosition = (buttonPosition + 1).rem(buttonPositionOptions.size)
			updateButtonPosition()
		}
		set_button_position_prev.setOnClickListener {
			buttonPosition = (buttonPosition + buttonPositionOptions.size - 1).rem(buttonPositionOptions.size)
			updateButtonPosition()
		}

		set_button_background_colour_next.setOnClickListener {
			buttonBackgroundColour = (buttonBackgroundColour + 1).rem(buttonBgColourOptions.size)
			updateButtonBackgroundColour()
		}
		set_button_background_colour_prev.setOnClickListener {
			buttonBackgroundColour = (buttonBackgroundColour + buttonBgColourOptions.size - 1).rem(buttonBgColourOptions.size)
			updateButtonBackgroundColour()
		}

		set_button_icon_next.setOnClickListener {
			buttonIcon = (buttonIcon + 1).rem(buttonIconOptions.size)
			updateButtonIcon()
		}
		set_button_icon_prev.setOnClickListener {
			buttonIcon = (buttonIcon + buttonIconOptions.size - 1).rem(buttonIconOptions.size)
			updateButtonIcon()
		}

		set_speed_dial_size_next.setOnClickListener {
			speedDialSize = (speedDialSize + 1).rem(speedDialSizeOptions.size)
			updateSpeedDialSize()
		}
		set_speed_dial_size_prev.setOnClickListener {
			speedDialSize = (speedDialSize + speedDialSizeOptions.size - 1).rem(speedDialSizeOptions.size)
			updateSpeedDialSize()
		}

		set_content_cover_colour_next.setOnClickListener {
			contentCoverColour = (contentCoverColour + 1).rem(contentCoverColourOptions.size)
			updateContentCoverColour()
		}
		set_content_cover_colour_prev.setOnClickListener {
			contentCoverColour = (contentCoverColour + contentCoverColourOptions.size - 1).rem(contentCoverColourOptions.size)
			updateContentCoverColour()
		}

		set_snackbar_enabled_next.setOnClickListener {
			snackbarEnabled = (snackbarEnabled + 1).rem(snackbarEnabledOptions.size)
			updateSnackbarEnabled()
		}
		set_snackbar_enabled_prev.setOnClickListener {
			snackbarEnabled = (snackbarEnabled + snackbarEnabledOptions.size - 1).rem(snackbarEnabledOptions.size)
			updateSnackbarEnabled()
		}
	}

	private fun toast(@StringRes str: Int) {
		toast(getString(str))
	}

	private fun toast(str: String) {
		activeToast?.cancel()
		activeToast = Toast.makeText(this, str, Toast.LENGTH_SHORT)
		activeToast?.show()
	}

	private fun updateButtonShown() {
		button_shown.text = buttonShownOptions[buttonShown].first
		if (buttonShownOptions[buttonShown].second) {
			fab.show()
		} else {
			fab.hide()
		}
	}

	private fun updateButtonPosition() {
		button_position.text = buttonPositionOptions[buttonPosition].first
		fab.setButtonPosition(buttonPositionOptions[buttonPosition].second)
	}

	private fun updateButtonBackgroundColour() {
		button_background_colour.text = buttonBgColourOptions[buttonBackgroundColour].first
		fab.setButtonBackgroundColour(buttonBgColourOptions[buttonBackgroundColour].second)
	}

	private fun updateButtonIcon() {
		button_icon.text = buttonIconOptions[buttonIcon].first
		fab.setButtonIconResource(buttonIconOptions[buttonIcon].second)
	}

	private fun updateSpeedDialSize() {
		speed_dial_size.text = speedDialSizeOptions[speedDialSize].first
		fab.rebuildSpeedDialMenu()
	}

	private fun updateContentCoverColour() {
		content_cover_colour.text = contentCoverColourOptions[contentCoverColour].first
		fab.setContentCoverColour(contentCoverColourOptions[contentCoverColour].second)
	}

	private fun updateSnackbarEnabled() {
		snackbar_enabled.text = snackbarEnabledOptions[snackbarEnabled].first
		if (snackbarEnabled == 1) {
			snackbar = Snackbar.make(root_view, "Hey there!", Snackbar.LENGTH_INDEFINITE)
			snackbar?.show()
		} else {
			snackbar?.dismiss()
		}
	}

	private fun startStressTest() {
		stressTestActive = true
		if (Build.VERSION.SDK_INT < 24) {
			toast(R.string.stress_test_version_error)
			return
		}
		toast(R.string.stress_test_exit_msg)
		stressTestHandler.postDelayed({ doStressTestEvent() }, 1000)
	}

	private fun doStressTestEvent() {
		if (!stressTestActive) return

		if (Build.VERSION.SDK_INT >= 24) {
			val x = random.nextInt(root_view.width).toFloat()
			val y = random.nextInt(root_view.height).toFloat()
			val now = SystemClock.uptimeMillis()

			val downTouch = MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, x, y, 0)
			root_view.dispatchTouchEvent(downTouch)
			downTouch.recycle()

			val upTouch = MotionEvent.obtain(now, now, MotionEvent.ACTION_UP, x, y, 0)
			root_view.dispatchTouchEvent(upTouch)
			upTouch.recycle()

			stressTestHandler.postDelayed({ doStressTestEvent() }, 25)
		}
	}
}
