package uk.co.markormesher.android_fab;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.View;

public abstract class SpeedDialMenuAdapter {

	/**
	 * Returns the number of items that should be displayed in the speed-dial menu.
	 *
	 * @return the number of items that should be displayed
	 */
	protected abstract int getCount();

	/**
	 * Returns the views that should be used for each item in the speed-dial menu.
	 *
	 * @param context  {@code android.content.Context} for the FAB, which can be used to create views
	 * @param position the position to generate a view for, from 0 (furthest from the FAB) to {@code getCount() - 1} (closest), inclusive
	 * @return an array of exactly two views
	 */
	protected abstract MenuItem getViews(Context context, int position);

	/**
	 * Returns the background colour to set for the menu item's "disc".
	 *
	 * @param position the position to set the colour for, from 0 (furthest from the FAB) to {@code getCount() - 1} (closest), inclusive
	 * @return the colour to set
	 */
	protected int getBackgroundColour(int position) {
		return 0xffc0c0c0;
	}

	/**
	 * Called when a menu item is clicked.
	 *
	 * @param position the position of the menu item that was clicked
	 * @return {@code true} to close the menu, {@code false} to leave it open.
	 */
	protected boolean onMenuItemClick(int position) {
		return true;
	}

	/**
	 * Returns a boolean indicating whether or not to rotate the FAB when the speed-dial menu is open.
	 * This is useful for smoothly transitioning from a '+' to a 'x' icon.
	 *
	 * @return a boolean indicating whether or not to rotate the FAB when the speed-dial menu is open
	 */
	protected boolean rotateFab() {
		return false;
	}

	/**
	 * Wrapper class for returning the views to use for a speed-dial menu item.
	 */
	public static class MenuItem {

		public View iconView;
		public Drawable iconDrawable;
		public int iconDrawableId = -1;

		public View labelView;
		public String labelString;
		public int labelStringId = -1;

	}

}
