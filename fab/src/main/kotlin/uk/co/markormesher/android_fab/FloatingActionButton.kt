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
import kotlinx.android.synthetic.main.fab_container.view.*
import kotlinx.android.synthetic.main.floating_action_button.view.*
import kotlinx.android.synthetic.main.menu_item.view.*
import kotlinx.android.synthetic.main.menu_item_icon.view.*
import uk.co.markormesher.android_fab.extensions.clearParentAlignmentRules
import uk.co.markormesher.android_fab.fab.R




class FloatingActionButton: RelativeLayout {

	private val SPEED_DIAL_ANIMATION_DURATION = 200L
	private val HIDE_SHOW_ANIMATION_DURATION = 100L

	private val layoutInflater by lazy { LayoutInflater.from(context) }

	private var buttonShown = true
	private var buttonPosition = POSITION_BOTTOM.or(POSITION_END)
	private var buttonBackgroundColour = 0xff0099ff.toInt()
	private var buttonIconResource = 0
	private var onClickListener: OnClickListener? = null

	private var speedDialMenuOpen = false
	private val speedDialMenuViews = ArrayList<ViewGroup>()
	var speedDialMenuAdapter: SpeedDialMenuAdapter? = null
		set(value) {
			field = value
			rebuildSpeedDialMenu()
		}

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
		inflate(context, R.layout.fab_container, this)
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
		fab_card.setOnClickListener {
			if (speedDialMenuAdapter?.isEnabled() == true && speedDialMenuAdapter?.getCount() ?: 0 > 0) {
				toggleSpeedDialMenu()
			} else {
				onClickListener?.onClick(this)
			}
		}
	}

	fun setButtonPosition(position: Int) {
		this.buttonPosition = position

		setViewLayoutParams(fab_card)
		setViewLayoutParams(content_cover)
		speedDialMenuViews.forEach { setViewLayoutParams(it) }
		speedDialMenuViews.forEach { setSpeedDialMenuItemViewOrder(it) }
	}

	private fun setViewLayoutParams(view: View) {
		val layoutParams = view.layoutParams as RelativeLayout.LayoutParams
		layoutParams.clearParentAlignmentRules()

		if (buttonPosition.and(POSITION_TOP) > 0) {
			layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP)
		}
		if (buttonPosition.and(POSITION_BOTTOM) > 0) {
			layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
		}
		if (buttonPosition.and(POSITION_START) > 0) {
			if (Build.VERSION.SDK_INT >= 17) {
				layoutParams.addRule(RelativeLayout.ALIGN_PARENT_START)
			} else {
				layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
			}
		}
		if (buttonPosition.and(POSITION_END) > 0) {
			if (Build.VERSION.SDK_INT >= 17) {
				layoutParams.addRule(RelativeLayout.ALIGN_PARENT_END)
			} else {
				layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
			}
		}
		if (buttonPosition.and(POSITION_LEFT) > 0) {
			layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT)
		}
		if (buttonPosition.and(POSITION_RIGHT) > 0) {
			layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
		}

		view.layoutParams = layoutParams
	}

	private fun setSpeedDialMenuItemViewOrder(view: ViewGroup) {
		var labelFirst = true
		val isRightToLeft = resources.getBoolean(R.bool.is_right_to_left)
		if (buttonPosition.and(POSITION_LEFT) > 0) {
			labelFirst = false
		}
		if (buttonPosition.and(POSITION_RIGHT) > 0) {
			labelFirst = true
		}
		if (buttonPosition.and(POSITION_START) > 0) {
			labelFirst = isRightToLeft
		}
		if (buttonPosition.and(POSITION_END) > 0) {
			labelFirst = !isRightToLeft
		}

		val label = view.menu_item_label
		val icon = view.menu_item_card
		view.removeView(label)
		view.removeView(icon)

		if (labelFirst) {
			view.addView(label)
			view.addView(icon)
		} else {
			view.addView(icon)
			view.addView(label)
		}
	}

	fun setButtonBackgroundColour(@ColorInt colour: Int) {
		this.buttonBackgroundColour = colour
		if (Build.VERSION.SDK_INT >= 21) {
			(fab_card as CardView).setCardBackgroundColor(colour)
		} else {
			(fab_card.background as GradientDrawable).setColor(colour)
		}
	}

	fun setButtonIconResource(@DrawableRes icon: Int) {
		this.buttonIconResource = icon
		if (icon <= 0) {
			fab_icon_wrapper.setBackgroundResource(0)
		} else {
			fab_icon_wrapper.setBackgroundResource(icon)
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

			val view = layoutInflater.inflate(R.layout.menu_item, null) as ViewGroup
			container.addView(view)
			speedDialMenuViews.add(view)

			setViewLayoutParams(view)
			setSpeedDialMenuItemViewOrder(view)

			view.menu_item_label.text = menuItem.getLabel()

			if (Build.VERSION.SDK_INT >= 21) {
				(view.menu_item_card as CardView).setCardBackgroundColor(adapter.getBackgroundColour(i))
			} else {
				((view.menu_item_card as ViewGroup).background as GradientDrawable).setColor(adapter.getBackgroundColour(i))
			}

			if (Build.VERSION.SDK_INT >= 16) {
				view.menu_item_icon_wrapper.background = menuItem.getIcon()
			} else {
				@Suppress("DEPRECATION")
				view.menu_item_icon_wrapper.setBackgroundDrawable(menuItem.getIcon())
			}

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

	fun showButton() {
		if (buttonShown) {
			return
		}

		closeSpeedDialMenu()
		fab_card.visibility = View.VISIBLE
		fab_card.clearAnimation()
		fab_card.animate()
				.scaleX(1f)
				.scaleY(1f)
				.setDuration(HIDE_SHOW_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator) {
						buttonShown = true
					}
				})
	}

	fun hideButton() {
		if (!buttonShown) {
			return
		}

		fab_card.clearAnimation()
		fab_card.animate()
				.scaleX(0f)
				.scaleY(0f)
				.setDuration(HIDE_SHOW_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator) {
						fab_card.visibility = View.GONE
						buttonShown = false
					}
				})
	}

	fun openSpeedDialMenu() {
		if (!speedDialMenuOpen) {
			toggleSpeedDialMenu()
		}
	}

	fun closeSpeedDialMenu() {
		if (speedDialMenuOpen) {
			toggleSpeedDialMenu()
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

		fab_icon_wrapper.animate()
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

		val distance = fab_card.height.toFloat()
		speedDialMenuViews.forEachIndexed { i, v ->
			if (speedDialMenuOpen) {
				v.visibility = View.VISIBLE
			}
			val translation = if (speedDialMenuOpen) {
				val direction = if (buttonPosition.and(POSITION_TOP) > 0) 1 else -1
				(i + 1.125F) * distance * direction
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
