package uk.co.markormesher.android_fab

import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import uk.co.markormesher.android_fab.extensions.clearParentAlignmentRules
import uk.co.markormesher.android_fab.fab.R

class FloatingActionButton: RelativeLayout {

	val containerView by lazy { findViewById<ViewGroup>(R.id.container) }
	val coverView by lazy { findViewById<View>(R.id.cover) }
	val buttonView by lazy { findViewById<View>(R.id.buttonCard) }

	private var buttonPosition = POSITION_BOTTOM.or(POSITION_END)

	companion object {
		const val POSITION_TOP = 1
		const val POSITION_BOTTOM = 2
		const val POSITION_START = 4
		const val POSITION_END = 8
		const val POSITION_LEFT = 16
		const val POSITION_RIGHT = 32
	}

	constructor(context: Context):
			super(context) {
		initView(null)
	}

	constructor(context: Context, attrs: AttributeSet):
			super(context, attrs) {
		initView(attrs)
	}

	constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int):
			super(context, attrs, defStyleAttr) {
		initView(attrs)
	}

	private fun initView(rawAttrs: AttributeSet?) {
		isSaveEnabled = true
		inflate(context, R.layout.floating_action_button, this)

		val attrs = context.theme.obtainStyledAttributes(rawAttrs, R.styleable.FloatingActionButton, 0, 0)
		try {
			setButtonPosition(attrs.getInteger(R.styleable.FloatingActionButton_position, buttonPosition))

		} finally {
			attrs.recycle()
		}

		coverView.alpha = 0f
	}

	fun setButtonPosition(position: Int) {
		this.buttonPosition = position

		val buttonLayoutParams = buttonView.layoutParams as RelativeLayout.LayoutParams
		val coverLayoutParams = coverView.layoutParams as RelativeLayout.LayoutParams
		buttonLayoutParams.clearParentAlignmentRules()
		coverLayoutParams.clearParentAlignmentRules()

		if (position.and(POSITION_TOP) > 0) {
			buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP)
			coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP)
		}
		if (position.and(POSITION_BOTTOM) > 0) {
			buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
			coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
		}
		if (position.and(POSITION_START) > 0) {
			if (Build.VERSION.SDK_INT >= 17) {
				buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_START)
				coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_START)
			} else {
				buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
				coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
			}
		}
		if (position.and(POSITION_END) > 0) {
			if (Build.VERSION.SDK_INT >= 17) {
				buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_END)
				coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_END)
			} else {
				buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
				coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
			}
		}
		if (position.and(POSITION_LEFT) > 0) {
			buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
			coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
		}
		if (position.and(POSITION_RIGHT) > 0) {
			buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
			coverLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
		}

		buttonView.layoutParams = buttonLayoutParams
		coverView.layoutParams = coverLayoutParams
	}

}
