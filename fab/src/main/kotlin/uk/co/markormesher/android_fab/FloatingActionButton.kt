package uk.co.markormesher.android_fab

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Resources
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Parcelable
import android.support.annotation.ColorInt
import android.support.annotation.Dimension
import android.support.annotation.DrawableRes
import android.support.design.widget.CoordinatorLayout
import android.support.design.widget.Snackbar
import android.support.v4.view.ViewCompat
import android.support.v7.widget.CardView
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.RelativeLayout
import kotlinx.android.synthetic.main.fab_container.view.*
import kotlinx.android.synthetic.main.floating_action_button.view.*
import kotlinx.android.synthetic.main.menu_item.view.*
import kotlinx.android.synthetic.main.menu_item_icon.view.*
import uk.co.markormesher.android_fab.extensions.clearParentAlignmentRules
import uk.co.markormesher.android_fab.fab.R


@Suppress("MemberVisibilityCanBePrivate", "unused") // because we want to expose the methods to end users
class FloatingActionButton: RelativeLayout {

	companion object {
		private const val SPEED_DIAL_ANIMATION_DURATION = 200L
		private const val HIDE_SHOW_ANIMATION_DURATION = 100L
		const val POSITION_TOP = 1
		const val POSITION_BOTTOM = 2
		const val POSITION_START = 4
		const val POSITION_END = 8
		const val POSITION_LEFT = 16
		const val POSITION_RIGHT = 32
	}

	private val layoutInflater by lazy { LayoutInflater.from(context) }
	private val isRightToLeft by lazy { resources.getBoolean(R.bool.is_right_to_left) }
	val originalInternalOffset by lazy { resources.getDimension(R.dimen.fab_offset) }

	private var isShown: Boolean = true
	override fun isShown() = isShown

	// defaults for all user-controllable parameters
	private var buttonPosition = POSITION_BOTTOM.or(POSITION_END)
	private var buttonBackgroundColour = 0xff0099ff.toInt()
	private var buttonIconResource = 0
	private var contentCoverColour = 0xccffffff.toInt()
	var contentCoverEnabled = true
	private var internalOffsetTop = 0f
	private var internalOffsetBottom = 0f
	private var internalOffsetStart = 0f
	private var internalOffsetEnd = 0f
	private var internalOffsetLeft = 0f
	private var internalOffsetRight = 0f

	private var onClickListener: OnClickListener? = null
	private var speedDialMenuOpenListener: SpeedDialMenuOpenListener? = null
	private var speedDialMenuCloseListener: SpeedDialMenuCloseListener? = null

	var isSpeedDialMenuOpen = false
		private set
	private val speedDialMenuViews = ArrayList<ViewGroup>()
	var speedDialMenuAdapter: SpeedDialMenuAdapter? = null
		set(value) {
			field = value
			rebuildSpeedDialMenu()
		}

	private var busyAnimatingFabIconRotation = false
	private var busyAnimatingContentCover = false
	private var busyAnimatingSpeedDialMenuItems = false
	private var isBusyAnimating = false
		get() = busyAnimatingFabIconRotation || busyAnimatingContentCover || busyAnimatingSpeedDialMenuItems

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

	override fun onSaveInstanceState(): Parcelable {
		val state = Bundle()
		state.putParcelable("_super", super.onSaveInstanceState())

		state.putBoolean("isShown", isShown)
		state.putInt("buttonPosition", buttonPosition)
		state.putInt("buttonBackgroundColour", buttonBackgroundColour)
		state.putInt("buttonIconResource", buttonIconResource)
		state.putInt("contentCoverColour", contentCoverColour)
		state.putBoolean("contentCoverEnabled", contentCoverEnabled)
		state.putFloat("internalOffsetTop", internalOffsetTop)
		state.putFloat("internalOffsetBottom", internalOffsetBottom)
		state.putFloat("internalOffsetStart", internalOffsetStart)
		state.putFloat("internalOffsetEnd", internalOffsetEnd)
		state.putFloat("internalOffsetLeft", internalOffsetLeft)
		state.putFloat("internalOffsetRight", internalOffsetRight)

		return state
	}

	override fun onRestoreInstanceState(state: Parcelable?) {
		if (state is Bundle) {
			isShown = state.getBoolean("isShown", isShown)
			if (isShown) {
				show()
			} else {
				hide(true)
			}

			buttonPosition = state.getInt("buttonPosition", buttonPosition)
			setButtonPosition(buttonPosition)

			buttonBackgroundColour = state.getInt("buttonBackgroundColour", buttonBackgroundColour)
			setButtonBackgroundColour(buttonBackgroundColour)

			buttonIconResource = state.getInt("buttonIconResource", buttonIconResource)
			setButtonIconResource(buttonIconResource)

			contentCoverColour = state.getInt("contentCoverColour", contentCoverColour)
			setContentCoverColour(contentCoverColour)

			contentCoverEnabled = state.getBoolean("contentCoverEnabled", contentCoverEnabled)

			internalOffsetTop = state.getFloat("internalOffsetTop", internalOffsetTop)
			setInternalOffsetTop(internalOffsetTop)

			internalOffsetBottom = state.getFloat("internalOffsetBottom", internalOffsetBottom)
			setInternalOffsetBottom(internalOffsetBottom)

			internalOffsetStart = state.getFloat("internalOffsetStart", internalOffsetStart)
			setInternalOffsetStart(internalOffsetStart)

			internalOffsetEnd = state.getFloat("internalOffsetEnd", internalOffsetEnd)
			setInternalOffsetEnd(internalOffsetEnd)

			internalOffsetLeft = state.getFloat("internalOffsetLeft", internalOffsetLeft)
			setInternalOffsetLeft(internalOffsetLeft)

			internalOffsetRight = state.getFloat("internalOffsetRight", internalOffsetRight)
			setInternalOffsetRight(internalOffsetRight)

			super.onRestoreInstanceState(state.getParcelable("_super"))
		} else {
			super.onRestoreInstanceState(state)
		}
	}

	private fun initView(attrs: AttributeSet?) {
		inflate(context, R.layout.fab_container, this)
		applyAttributes(attrs)
		applyListeners()
		rebuildSpeedDialMenu()

		content_cover.alpha = 0f

		addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
			if (layoutParams is CoordinatorLayout.LayoutParams) {
				val lp = (layoutParams as CoordinatorLayout.LayoutParams)
				lp.behavior = MoveUpwardBehavior()
				layoutParams = lp
			}
		}
	}

	private fun applyAttributes(rawAttrs: AttributeSet?) {
		val attrs = context.theme.obtainStyledAttributes(rawAttrs, R.styleable.FloatingActionButton, 0, 0)
		try {
			setButtonPosition(attrs.getInteger(R.styleable.FloatingActionButton_buttonPosition, buttonPosition))
			setButtonBackgroundColour(attrs.getColor(R.styleable.FloatingActionButton_buttonBackgroundColour, buttonBackgroundColour))
			setButtonIconResource(attrs.getResourceId(R.styleable.FloatingActionButton_buttonIcon, 0))
			setInternalOffsetTop(attrs.getDimension(R.styleable.FloatingActionButton_internalOffsetTop, 0f))
			setInternalOffsetBottom(attrs.getDimension(R.styleable.FloatingActionButton_internalOffsetBottom, 0f))
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

	fun setButtonPosition(position: Int) {
		buttonPosition = position

		setViewLayoutParams(fab_card)
		setViewLayoutParams(content_cover)
		speedDialMenuViews.forEach { setViewLayoutParams(it) }
		speedDialMenuViews.forEach { setSpeedDialMenuItemViewOrder(it) }
	}

	fun setButtonBackgroundColour(@ColorInt colour: Int) {
		buttonBackgroundColour = colour
		if (Build.VERSION.SDK_INT >= 21) {
			(fab_card as CardView).setCardBackgroundColor(colour)
		} else {
			(fab_card.background as GradientDrawable).setColor(colour)
		}
	}

	fun setButtonIconResource(@DrawableRes icon: Int) {
		buttonIconResource = icon
		fab_icon_wrapper.setBackgroundResource(icon)
	}

	fun setInternalOffsetTop(@Dimension offsetPixels: Float) {
		internalOffsetTop = offsetPixels
		updateInternalOffset()
	}

	fun setInternalOffsetBottom(@Dimension offsetPixels: Float) {
		internalOffsetBottom = offsetPixels
		updateInternalOffset()
	}

	fun setInternalOffsetStart(@Dimension offsetPixels: Float) {
		internalOffsetStart = offsetPixels
		updateInternalOffset()
	}

	fun setInternalOffsetEnd(@Dimension offsetPixels: Float) {
		internalOffsetEnd = offsetPixels
		updateInternalOffset()
	}

	fun setInternalOffsetLeft(@Dimension offsetPixels: Float) {
		internalOffsetLeft = offsetPixels
		updateInternalOffset()
	}

	fun setInternalOffsetRight(@Dimension offsetPixels: Float) {
		internalOffsetRight = offsetPixels
		updateInternalOffset()
	}

	private fun updateInternalOffset() {
		// if left/right are explicitly set, use them
		if (internalOffsetLeft != 0f || internalOffsetRight != 0f) {
			container.setPadding(
					(originalInternalOffset + internalOffsetLeft).toInt(),
					(originalInternalOffset + internalOffsetTop).toInt(),
					(originalInternalOffset + internalOffsetRight).toInt(),
					(originalInternalOffset + internalOffsetBottom).toInt()
			)
		} else {
			if (Build.VERSION.SDK_INT >= 17) {
				container.setPaddingRelative(
						(originalInternalOffset + internalOffsetStart).toInt(),
						(originalInternalOffset + internalOffsetTop).toInt(),
						(originalInternalOffset + internalOffsetEnd).toInt(),
						(originalInternalOffset + internalOffsetBottom).toInt()
				)
			} else {
				container.setPadding(
						(originalInternalOffset + if (isRightToLeft) internalOffsetEnd else internalOffsetStart).toInt(),
						(originalInternalOffset + internalOffsetTop).toInt(),
						(originalInternalOffset + if (isRightToLeft) internalOffsetStart else internalOffsetEnd).toInt(),
						(originalInternalOffset + internalOffsetBottom).toInt()
				)
			}
		}
	}

	override fun setOnClickListener(listener: OnClickListener?) {
		onClickListener = listener
	}

	fun openSpeedDialMenu() {
		if (!isSpeedDialMenuOpen) {
			toggleSpeedDialMenu()
		}
	}

	fun closeSpeedDialMenu() {
		if (isSpeedDialMenuOpen) {
			toggleSpeedDialMenu()
		}
	}

	@Deprecated(
			"This method name is incorrect and is kept only for backwards compatibility",
			ReplaceWith("setOnSpeedDialMenuOpenListener"),
			DeprecationLevel.WARNING
	)
	fun setOnSpeedMenuDialOpenListener(listener: SpeedDialMenuOpenListener?) {
		setOnSpeedDialMenuOpenListener(listener)
	}

	fun setOnSpeedDialMenuOpenListener(listener: SpeedDialMenuOpenListener?) {
		speedDialMenuOpenListener = listener
	}

	fun setOnSpeedDialMenuCloseListener(listener: SpeedDialMenuCloseListener?) {
		speedDialMenuCloseListener = listener
	}

	fun setContentCoverColour(@ColorInt colour: Int) {
		contentCoverColour = colour
		(content_cover.background as GradientDrawable).setColor(colour)
	}

	fun show() {
		if (isShown) {
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
						isShown = true
					}
				})
	}

	fun hide(immediate: Boolean = false) {
		if (!isShown && !immediate) {
			return
		}

		fab_card.clearAnimation()
		fab_card.animate()
				.scaleX(0f)
				.scaleY(0f)
				.setDuration(if (immediate) 0L else HIDE_SHOW_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator) {
						fab_card.visibility = View.GONE
						isShown = false
					}
				})
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

			@SuppressLint("InflateParams") // because we handle attachment to root internally
			val view = layoutInflater.inflate(R.layout.menu_item, null) as ViewGroup
			container.addView(view)
			speedDialMenuViews.add(view)

			setViewLayoutParams(view)
			setSpeedDialMenuItemViewOrder(view)

			view.menu_item_label.text = menuItem.getLabel()
			speedDialMenuAdapter?.onPrepareItemLabel(context, i, view.menu_item_label)

			if (Build.VERSION.SDK_INT >= 21) {
				(view.menu_item_card as CardView).setCardBackgroundColor(adapter.getBackgroundColour(i))
			} else {
				((view.menu_item_card as ViewGroup).background as GradientDrawable).setColor(adapter.getBackgroundColour(i))
			}
			speedDialMenuAdapter?.onPrepareItemCard(context, i, view.menu_item_card)

			if (Build.VERSION.SDK_INT >= 16) {
				view.menu_item_icon_wrapper.background = menuItem.getIcon()
			} else {
				@Suppress("DEPRECATION")
				view.menu_item_icon_wrapper.setBackgroundDrawable(menuItem.getIcon())
			}
			speedDialMenuAdapter?.onPrepareItemIconWrapper(context, i, view.menu_item_icon_wrapper)

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

		if (isSpeedDialMenuOpen) {
			animateSpeedDialMenuItems(true)
		}
	}

	private fun toggleSpeedDialMenu() {
		if (isBusyAnimating) {
			return
		}

		isSpeedDialMenuOpen = !isSpeedDialMenuOpen

		if (isSpeedDialMenuOpen) {
			speedDialMenuOpenListener?.onOpen(this)
		} else {
			speedDialMenuCloseListener?.onClose(this)
		}

		animateFabIconRotation()
		animateContentCover()
		animateSpeedDialMenuItems()

		content_cover.isClickable = isSpeedDialMenuOpen
		content_cover.isFocusable = isSpeedDialMenuOpen
		if (isSpeedDialMenuOpen) {
			content_cover.setOnClickListener { toggleSpeedDialMenu() }
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
				.rotation(if (isSpeedDialMenuOpen) speedDialMenuAdapter?.fabRotationDegrees() ?: 0F else 0F)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator?) {
						busyAnimatingFabIconRotation = false
					}
				})
	}

	private fun animateContentCover() {
		if (isSpeedDialMenuOpen && !contentCoverEnabled) {
			// isSpeedDialMenuOpen is checked to make sure the cover is closed if it is disabled whilst open
			return
		}

		if (busyAnimatingContentCover) {
			return
		}
		busyAnimatingContentCover = true

		// calculate the cover scale only if we're going to need it
		var coverScale = 0f
		if (isSpeedDialMenuOpen) {
			// get the diagonal size of the screen to determine the proper scale factor
			val displayMetrics = Resources.getSystem().displayMetrics
			val windowHeight = displayMetrics.heightPixels.toDouble()
			val windowWidth = displayMetrics.widthPixels.toDouble()
			val windowDiagonal = Math.sqrt(Math.pow(windowHeight, 2.0) + Math.pow(windowWidth, 2.0))

			// the cover is the same size as the fab_card, so we use a ratio of that size
			// using the width is fine: both shapes are circles so their diameter is the same at any angle
			// we * 2 because only half of the cover will be on screen
			coverScale = 2 * windowDiagonal.toFloat() / fab_card.width
		}

		content_cover.visibility = View.VISIBLE
		content_cover.animate()
				.scaleX(coverScale)
				.scaleY(coverScale)
				.alpha(if (isSpeedDialMenuOpen) 1f else 0f)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(object: AnimatorListenerAdapter() {
					override fun onAnimationEnd(animation: Animator) {
						busyAnimatingContentCover = false
						if (!isSpeedDialMenuOpen) {
							content_cover.visibility = View.GONE
						}
					}
				})
	}

	private fun animateSpeedDialMenuItems(immediate: Boolean = false) {
		if (busyAnimatingSpeedDialMenuItems) {
			return
		}
		busyAnimatingSpeedDialMenuItems = true

		val duration = if (immediate) {
			0L
		} else {
			SPEED_DIAL_ANIMATION_DURATION
		}

		val distance = fab_card.height.toFloat()
		speedDialMenuViews.forEachIndexed { i, v ->
			if (isSpeedDialMenuOpen) {
				v.visibility = View.VISIBLE
			}
			val translation = if (isSpeedDialMenuOpen) {
				val direction = if (buttonPosition.and(POSITION_TOP) > 0) 1 else -1
				(i + 1.125F) * distance * direction
			} else {
				0f
			}
			v.animate()
					.translationY(translation)
					.alpha(if (isSpeedDialMenuOpen) 1f else 0f)
					.setDuration(duration)
					.setListener(object: AnimatorListenerAdapter() {
						override fun onAnimationEnd(animation: Animator) {
							busyAnimatingSpeedDialMenuItems = false
							if (!isSpeedDialMenuOpen) {
								v.visibility = View.GONE
							}
						}
					})
		}
	}

	val cardView: View
		get() = fab_card

	val contentCoverView: View
		get() = content_cover

	val iconWrapper: LinearLayout
		get() = fab_icon_wrapper


	inner class MoveUpwardBehavior: CoordinatorLayout.Behavior<View>() {

		override fun layoutDependsOn(parent: CoordinatorLayout, child: View, dependency: View): Boolean {
			return buttonPosition.and(POSITION_BOTTOM) > 0 && dependency is Snackbar.SnackbarLayout
		}

		override fun onDependentViewChanged(parent: CoordinatorLayout, child: View, dependency: View): Boolean {
			child.translationY = Math.min(0f, dependency.translationY - dependency.height)
			return true
		}

		override fun onDependentViewRemoved(parent: CoordinatorLayout, child: View, dependency: View) {
			ViewCompat.animate(child).translationY(0f).start()
		}
	}

}
