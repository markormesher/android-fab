package uk.co.markormesher.android_fab

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.support.annotation.ColorInt
import android.support.annotation.DrawableRes
import android.support.v7.widget.CardView
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import kotlinx.android.synthetic.main.floating_action_button.view.*
import kotlinx.android.synthetic.main.floating_action_button_inner.view.*
import kotlinx.android.synthetic.main.speed_dial_icon_inner.view.*
import kotlinx.android.synthetic.main.speed_dial_menu_item.view.*
import uk.co.markormesher.android_fab.extensions.clearParentAlignmentRules
import uk.co.markormesher.android_fab.fab.R


class FloatingActionButton: RelativeLayout {

	private val SPEED_DIAL_ANIMATION_DURATION = 200L
	private val HIDE_SHOW_ANIMATION_DURATION = 100L

	private val layoutInflater by lazy { LayoutInflater.from(context) }

	private var buttonPosition = POSITION_BOTTOM.or(POSITION_END)
	private var buttonBackgroundColour = 0xff0099ff.toInt()
	private var buttonIconResource = 0
	private var onClickListener: OnClickListener? = null

	var speedDialMenuAdapter: SpeedDialMenuAdapter? = null
		set(value) {
			field = value
			rebuildSpeedDialMenu()
		}
	private val speedDialMenuViews = ArrayList<View>()
	var speedDialMenuOpen = false
		private set

	var contentCoverEnabled = true

	private var busyAnimatingFabIconRotation = false
	private var busyAnimatingContentCover = false
	private var busyAnimatingSpeedDialMenuItems = false
	private var isBusyAnimating = false
		get() = busyAnimatingFabIconRotation || busyAnimatingContentCover || busyAnimatingSpeedDialMenuItems

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
		rebuildSpeedDialMenu()

		content_cover.alpha = 0f
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
			if (speedDialMenuAdapter?.isEnabled() == true && speedDialMenuAdapter?.getCount() ?: 0 > 0) {
				toggleSpeedDialMenu()
			} else {
				onClickListener?.onClick(this)
			}
		}
	}

	fun setButtonPosition(position: Int) {
		this.buttonPosition = position

		val buttonLayoutParams = button_card.layoutParams as RelativeLayout.LayoutParams
		val coverLayoutParams = content_cover.layoutParams as RelativeLayout.LayoutParams
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
		content_cover.layoutParams = coverLayoutParams
	}

	fun setButtonBackgroundColour(@ColorInt colour: Int) {
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

	fun rebuildSpeedDialMenu() {
		speedDialMenuViews.forEach { (it.parent as ViewGroup).removeView(it) }
		speedDialMenuViews.clear()

		if (speedDialMenuAdapter == null || speedDialMenuAdapter?.getCount() == 0) {
			return
		}

		val adapter = speedDialMenuAdapter!!

		for (i in (0 until adapter.getCount())) {
			val menuItem = adapter.getMenuItem(context, i)

			val view = layoutInflater.inflate(R.layout.speed_dial_menu_item, null) as ViewGroup
			container.addView(view)
			speedDialMenuViews.add(view)

			view.menu_item_label.text = menuItem.getLabel()

			if (Build.VERSION.SDK_INT >= 21) {
				(view.menu_item_icon_background as CardView).setCardBackgroundColor(adapter.getBackgroundColour(i))
			} else {
				((view.menu_item_icon_background as ViewGroup).background as GradientDrawable).setColor(adapter.getBackgroundColour(i))
			}

			if (Build.VERSION.SDK_INT >= 16) {
				view.menu_item_icon_container.background = menuItem.getIcon()
			} else {
				@Suppress("DEPRECATION")
				view.menu_item_icon_container.setBackgroundDrawable(menuItem.getIcon())
			}

			// TODO: fix positioning
			val params = view.layoutParams as RelativeLayout.LayoutParams
			params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
			if (Build.VERSION.SDK_INT >= 17) params.addRule(RelativeLayout.ALIGN_PARENT_END)
			params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
			view.layoutParams = params

			view.alpha = 0F
			view.visibility = GONE

			view.tag = i
			view.setOnClickListener { v ->
				val closeMenuAfterAction = adapter.onMenuItemClick(v.tag as Int)
				if (closeMenuAfterAction) {
					toggleSpeedDialMenu()
				}
			}
		}
	}

	private fun toggleSpeedDialMenu() {
		if (isBusyAnimating) {
			return
		}

		speedDialMenuOpen = !speedDialMenuOpen

		// TODO: speed-dial listener

		animateFabIconRotation()
		animateContentCover()
		animateSpeedDialMenuItems()

		content_cover.isClickable = speedDialMenuOpen
		content_cover.isFocusable = speedDialMenuOpen
		if (speedDialMenuOpen) {
			content_cover.setOnClickListener({ toggleSpeedDialMenu() })
		} else {
			content_cover.setOnClickListener(null)
		}
	}

	private fun animateFabIconRotation() {
		if (busyAnimatingFabIconRotation) {
			return
		}
		busyAnimatingFabIconRotation = true

		icon_container.animate()
				.rotation(if (speedDialMenuOpen) speedDialMenuAdapter?.fabRotationDegrees() ?: 0F else 0F)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator?) {
						busyAnimatingFabIconRotation = false
					}
				})
	}

	private fun animateContentCover() {
		if (speedDialMenuOpen && !contentCoverEnabled) {
			// speedDialMenuOpen is checked to make sure the cover is closed if it is disabled whist open
			return
		}

		if (busyAnimatingContentCover) {
			return
		}
		busyAnimatingContentCover = true

		content_cover.visibility = View.VISIBLE
		content_cover.animate()
				.scaleX(if (speedDialMenuOpen) 50f else 0f)
				.scaleY(if (speedDialMenuOpen) 50f else 0f)
				.alpha(if (speedDialMenuOpen) 1f else 0f)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator) {
						busyAnimatingContentCover = false
						if (!speedDialMenuOpen) {
							content_cover.visibility = View.GONE
						}
					}
				})
	}

	private fun animateSpeedDialMenuItems() {
		if (busyAnimatingSpeedDialMenuItems) {
			return
		}
		busyAnimatingSpeedDialMenuItems = true

		val distance = button_card.height.toFloat()
		speedDialMenuViews.forEachIndexed { i, v ->
			if (speedDialMenuOpen) {
				v.visibility = View.VISIBLE
			}
			val translation = if (speedDialMenuOpen) {
				((i + 1) * distance * -1) - (distance / 8)
			} else {
				0f
			}
			v.animate()
					.translationY(translation)
					.alpha(if (speedDialMenuOpen) 1f else 0f)
					.setDuration(SPEED_DIAL_ANIMATION_DURATION)
					.setListener(object: AnimatorListenerAdapter() {
						override fun onAnimationEnd(animation: Animator) {
							busyAnimatingSpeedDialMenuItems = false
							if (!speedDialMenuOpen) {
								v.visibility = View.GONE
							}
						}
					})
		}
	}
}
