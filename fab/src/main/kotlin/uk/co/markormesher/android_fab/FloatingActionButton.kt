package uk.co.markormesher.android_fab

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.support.annotation.DrawableRes
import android.support.v7.widget.CardView
import android.util.AttributeSet
import android.widget.RelativeLayout
import kotlinx.android.synthetic.main.floating_action_button.view.*
import kotlinx.android.synthetic.main.floating_action_button_inner.view.*
import uk.co.markormesher.android_fab.extensions.clearParentAlignmentRules
import uk.co.markormesher.android_fab.fab.R

class FloatingActionButton: RelativeLayout {

	private var buttonPosition = POSITION_BOTTOM.or(POSITION_END)
	private var buttonBackgroundColour = 0xff0099ff.toInt()
	private var buttonIconResource = 0

	private var onClickListener: OnClickListener? = null

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

	private fun initView(attrs: AttributeSet?) {
		isSaveEnabled = true
		inflate(context, R.layout.floating_action_button, this)
		applyAttributes(attrs)
		applyListeners()

		cover_view.alpha = 0f
	}

	private fun applyAttributes(rawAttrs: AttributeSet?) {
		val attrs = context.theme.obtainStyledAttributes(rawAttrs, R.styleable.FloatingActionButton, 0, 0)
		try {
			setButtonPosition(attrs.getInteger(R.styleable.FloatingActionButton_buttonPosition, buttonPosition))
			setButtonBackgroundColour(attrs.getColor(R.styleable.FloatingActionButton_buttonBackgroundColour, buttonBackgroundColour))
			setButtonIconResource(attrs.getResourceId(R.styleable.FloatingActionButton_buttonIcon, 0))
		} finally {
			attrs.recycle()
		}
	}

	private fun applyListeners() {
		button_card.setOnClickListener {
			// TODO: check for speed-dial mode
			onClickListener?.onClick(this)
		}
	}

	fun setButtonPosition(position: Int) {
		this.buttonPosition = position

		val buttonLayoutParams = button_card.layoutParams as RelativeLayout.LayoutParams
		val coverLayoutParams = cover_view.layoutParams as RelativeLayout.LayoutParams
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

		button_card.layoutParams = buttonLayoutParams
		cover_view.layoutParams = coverLayoutParams
	}

	fun setButtonBackgroundColour(colour: Int) {
		this.buttonBackgroundColour = colour
		if (Build.VERSION.SDK_INT >= 21) {
			(button_card as CardView).setCardBackgroundColor(colour)
		} else {
			(button_card.background as GradientDrawable).setColor(colour)
		}
	}

	fun setButtonIconResource(@DrawableRes icon: Int) {
		this.buttonIconResource = icon
		if (icon <= 0) {
			icon_container.setBackgroundResource(0)
		} else {
			icon_container.setBackgroundResource(icon)
		}
	}

	override fun setOnClickListener(listener: OnClickListener?) {
		onClickListener = listener
	}
}
