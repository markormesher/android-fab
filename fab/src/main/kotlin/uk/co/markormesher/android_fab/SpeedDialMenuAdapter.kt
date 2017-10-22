package uk.co.markormesher.android_fab

import android.content.Context
import android.graphics.Color
import android.support.annotation.ColorInt

abstract class SpeedDialMenuAdapter {

	abstract fun getCount(): Int

	abstract fun getMenuItem(context: Context, position: Int): SpeedDialMenuItem

	open fun onMenuItemClick(position: Int): Boolean = true

	@ColorInt open fun getBackgroundColour(position: Int): Int = Color.argb(255, 192, 192, 192)

	open fun fabRotationDegrees() = 0F

	open fun isEnabled() = true

}
