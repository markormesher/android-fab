package uk.co.markormesher.android_fab.app

import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.widget.Button
import kotlinx.android.synthetic.main.demo_activity.*
import uk.co.markormesher.android_fab.FloatingActionButton

class DemoActivity: AppCompatActivity() {

	private var buttonPosition = FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_END)

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.demo_activity)

		setButtonPositionTopStart.setOnClickListener { btn ->
			setButtonPosition(FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_START))
			btn.isEnabled = false
		}
		setButtonPositionTopEnd.setOnClickListener { btn ->
			setButtonPosition(FloatingActionButton.POSITION_TOP.or(FloatingActionButton.POSITION_END))
			btn.isEnabled = false
		}
		setButtonPositionBottomStart.setOnClickListener { btn ->
			setButtonPosition(FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_START))
			btn.isEnabled = false
		}
		setButtonPositionBottomEnd.setOnClickListener { btn ->
			setButtonPosition(FloatingActionButton.POSITION_BOTTOM.or(FloatingActionButton.POSITION_END))
			btn.isEnabled = false
		}

		setButtonPosition(buttonPosition)
		setButtonPositionBottomEnd.isEnabled = false
	}

	private fun setButtonPosition(buttonPosition: Int) {
		this.buttonPosition = buttonPosition

		fab.setButtonPosition(buttonPosition)

		listOf<Button>(
				setButtonPositionTopEnd,
				setButtonPositionTopStart,
				setButtonPositionBottomEnd,
				setButtonPositionBottomStart
		).forEach({ it.isEnabled = true })
	}

}
