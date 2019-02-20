package uk.co.markormesher.android_fab

import android.content.Context
import android.graphics.drawable.Drawable
import android.os.Build
import androidx.annotation.DrawableRes
import androidx.annotation.StringRes

/**
 * Represents an item to display in the speed-dial menu.
 * Each menu item is a pairing of an icon and a label.
 * This class contains constructors to create this pairing using `Drawable`s, `String`s and corresponding resource IDs.
 */
class SpeedDialMenuItem(private val context: Context) {

	private var icon: Drawable? = null
	private var label: String? = null

	constructor(context: Context, icon: Drawable, label: String): this(context) {
		setIcon(icon)
		setLabel(label)
	}

	constructor(context: Context, icon: Drawable, @StringRes label: Int): this(context) {
		setIcon(icon)
		setLabel(label)
	}

	constructor(context: Context, @DrawableRes icon: Int, label: String): this(context) {
		setIcon(icon)
		setLabel(label)
	}

	constructor(context: Context, @DrawableRes icon: Int, @StringRes label: Int): this(context) {
		setIcon(icon)
		setLabel(label)
	}

	fun setIcon(icon: Drawable) {
		this.icon = icon
	}

	fun setIcon(@DrawableRes icon: Int) {
		if (Build.VERSION.SDK_INT >= 21) {
			this.icon = context.resources.getDrawable(icon, context.theme)
		} else {
			@Suppress("DEPRECATION")
			this.icon = context.resources.getDrawable(icon)
		}
	}

	fun getIcon() = icon

	fun setLabel(label: String) {
		this.label = label
	}

	fun setLabel(@StringRes label: Int) {
		this.label = context.getString(label)
	}

	fun getLabel() = label

}
