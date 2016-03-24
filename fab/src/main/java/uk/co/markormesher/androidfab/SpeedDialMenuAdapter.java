package uk.co.markormesher.androidfab;

import android.content.Context;
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
	 * An array of exactly two views must be returned: the first will be used as the icon inside the small circle,
	 * the second (which may be @{code null}) as the label.
	 *
	 * @param context  @{code Context} for the FAB, which can be used to create views
	 * @param position the position to generate a view for, from 0 (furthest from the FAB) to @{code getCount()} - 1, inclusive
	 * @return an array of exactly two views
	 */
	protected abstract View[] getViews(Context context, int position);

	/**
	 * Returns the background colour to set for the menu item's "disc".
	 *
	 * @param position the position to generate a view for, from 0 (furthest from the FAB) to @{code getCount()} - 1, inclusive
	 * @return the colour to set
	 */
	protected int getBackgroundColour(int position) {
		return 0xffc0c0c0;
	}

	/**
	 * Called when a menu item is clicked.
	 *
	 * @param position the position of the menu item that was clicked
	 * @return @{code true} to close the menu, @{code false} to leave it open.
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

}
