package uk.co.markormesher.android_fab;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Parcelable;
import android.support.annotation.DrawableRes;
import android.support.v7.widget.CardView;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;
import uk.co.markormesher.android_fab.constants.C;
import uk.co.markormesher.android_fab.fab.R;

import java.util.ArrayList;

public class FloatingActionButton extends RelativeLayout {

	private static final long SPEED_DIAL_ANIMATION_DURATION = 200L;
	private static final long HIDE_SHOW_ANIMATION_DURATION = 100L;

	/*==============*
	 * Constructors *
	 *==============*/

	public FloatingActionButton(Context context) {
		super(context);
		initView();
	}

	public FloatingActionButton(Context context, AttributeSet attrs) {
		super(context, attrs);
		initView();
	}

	public FloatingActionButton(Context context, AttributeSet attrs, int defStyleAttr) {
		super(context, attrs, defStyleAttr);
		initView();
	}

	/*=======*
	 * Views *
	 *=======*/

	private RelativeLayout fabContainer;
	private CardView cardView;
	private ViewGroup iconContainer;
	private View coverView;

	private boolean shown = true;

	/**
	 * Sets up the view by finding components and setting styles.
	 */
	private void initView() {
		// inflate layout
		inflate(getContext(), R.layout.floating_action_button, this);

		// collect views
		fabContainer = (RelativeLayout) findViewById(R.id.fab_container);
		cardView = (CardView) findViewById(R.id.card);
		iconContainer = (ViewGroup) findViewById(R.id.icon_container);
		coverView = findViewById(R.id.cover);

		// fade out the cover
		coverView.setAlpha(0F);

		// clicks
		cardView.setClickable(true);
		cardView.setFocusable(true);
		cardView.setOnClickListener(v -> onClick());

		// make sure Android knows we want to save this state
		setSaveEnabled(true);
	}

	/**
	 * Sets the {@code android.view.View} to use as the icon on the FAB.
	 *
	 * @param icon the {@code View} to use as the icon on the FAB
	 */
	public void setIcon(View icon) {
		resetIcon();
		if (icon != null) {
			if (icon.getParent() != null) ((ViewGroup) icon.getParent()).removeView(icon);
			iconContainer.addView(icon);
		}
	}

	/**
	 * Sets the {@code android.graphics.drawable.Drawable} to use as the icon on the FAB.
	 *
	 * @param icon the {@code Drawable} to use as the icon on the FAB
	 */
	@SuppressWarnings("deprecation")
	public void setIcon(Drawable icon) {
		resetIcon();
		if (icon != null) {
			if (Build.VERSION.SDK_INT >= 16) {
				iconContainer.setBackground(icon);
			} else {
				//noinspection deprecation
				iconContainer.setBackgroundDrawable(icon);
			}
		}
	}

	/**
	 * Sets the resource ID of the {@code android.graphics.drawable.Drawable} to use as the icon on the FAB.
	 *
	 * @param icon the resource ID of the {@code Drawable} to use as the icon on the FAB
	 */
	public void setIcon(@DrawableRes int icon) {
		resetIcon();
		savedIconResId = icon;
		iconContainer.setBackgroundResource(icon);
	}

	/**
	 * Reset the FAB icon, whether it's created from an inserted view or a drawable.
	 */
	@SuppressWarnings("deprecation")
	private void resetIcon() {
		savedIconResId = -1;
		iconContainer.removeAllViews();
		iconContainer.setBackgroundResource(0);
		if (Build.VERSION.SDK_INT >= 16) {
			iconContainer.setBackground(null);
		} else {
			//noinspection deprecation
			iconContainer.setBackgroundDrawable(null);
		}
	}

	/**
	 * Sets the colour of the FAB background.
	 *
	 * @param colour the colour of the FAB background, in aRGB format
	 */
	public void setBackgroundColour(int colour) {
		savedBgColour = colour;
		cardView.setCardBackgroundColor(colour);
	}

	/**
	 * Hide the FAB.
	 */
	public void hide() {
		hide(false);
	}

	/**
	 * Hide the FAB.
	 *
	 * @param fast {@code true} to run this animation in zero-time.
	 */
	private void hide(boolean fast) {
		if (!shown && !fast) return;

		closeSpeedDialMenu();
		cardView.clearAnimation();
		cardView.animate()
				.scaleX(0F)
				.scaleY(0F)
				.setDuration(fast ? 0 : HIDE_SHOW_ANIMATION_DURATION)
				.setListener(new AnimatorListenerAdapter() {
					@Override
					public void onAnimationEnd(Animator animation) {
						cardView.setVisibility(GONE);
						shown = false;
					}
				});
	}

	/**
	 * Show the FAB.
	 */
	public void show() {
		if (shown) return;

		cardView.setVisibility(VISIBLE);
		cardView.clearAnimation();
		cardView.animate()
				.scaleX(1F)
				.scaleY(1F)
				.setDuration(HIDE_SHOW_ANIMATION_DURATION)
				.setListener(new AnimatorListenerAdapter() {
					@Override
					public void onAnimationEnd(Animator animation) {
						shown = true;
					}
				});
	}

	/**
	 * Checks whether the FAB is shown.
	 *
	 * @return {@code true} if the FAB is shown
	 */
	public boolean isShown() {
		return shown;
	}

	/*=============*
	 * Interaction *
	 *=============*/

	private OnClickListener listener;

	@Override
	public void setOnClickListener(OnClickListener listener) {
		this.menuAdapter = null;
		this.listener = listener;
	}

	private void onClick() {
		if (listener != null) {
			listener.onClick(this);
		} else if (menuAdapter != null) {
			toggleSpeedDialMenu();
		}
	}

	/*=================*
	 * Speed-dial menu *
	 *=================*/

	private boolean speedDialMenuOpen = false;
	private boolean busyAnimatingFabIcon = false;
	private boolean busyAnimatingSpeedDialCover = false;
	private boolean busyAnimatingSpeedDialMenu = false;

	private SpeedDialMenuAdapter menuAdapter;

	private ArrayList<View> speedDialMenuItems;

	/**
	 * Sets the menu adapter to be used with this floating action button.
	 * By setting an adapter, the speed-dial menu will be activated and the click listener will be removed.
	 *
	 * @param menuAdapter the menu adapter to use with this floating action button
	 * @see uk.co.markormesher.android_fab.SpeedDialMenuAdapter
	 */
	public void setMenuAdapter(SpeedDialMenuAdapter menuAdapter) {
		this.listener = null;
		this.menuAdapter = menuAdapter;
		if (menuAdapter != null) rebuildSpeedDialMenu();
	}

	/**
	 * (Re-)generates the items for the speed dial menu, according to the currently specified adapter.
	 * This should be called each time the functionality of the adapter is changed; it is called
	 * automatically when the adapter itself is changed (with {@code setMenuAdapter()}.
	 */
	@SuppressLint("InlinedApi")
	@SuppressWarnings("deprecation")
	public void rebuildSpeedDialMenu() {
		// sanity check
		if (menuAdapter.getCount() == 0) {
			Log.w(C.LOG_TAG, "SpeedDialMenuAdapter contained zero items; speed-dial functionality was disabled.");
			setMenuAdapter(null);
			return;
		}

		// init empty array
		speedDialMenuItems = new ArrayList<>(menuAdapter.getCount());

		for (int i = menuAdapter.getCount() - 1; i >= 0; --i) {
			// inflate a new item container and add to layout
			@SuppressLint("InflateParams")
			View view = LayoutInflater.from(getContext()).inflate(R.layout.speed_dial_icon, null);
			fabContainer.addView(view, 1);
			speedDialMenuItems.add(view);

			// set background colour
			((CardView) view.findViewById(R.id.card)).setCardBackgroundColor(menuAdapter.getBackgroundColour(i));

			// get child views
			SpeedDialMenuAdapter.MenuItem itemViews = menuAdapter.getViews(getContext(), i);

			// add icon
			ViewGroup iconContainer = (ViewGroup) view.findViewById(R.id.icon_container);
			if (itemViews.iconView != null) {
				iconContainer.addView(itemViews.iconView, 0);
			} else if (itemViews.iconDrawable != null) {
				if (Build.VERSION.SDK_INT >= 16) {
					iconContainer.setBackground(itemViews.iconDrawable);
				} else {
					//noinspection deprecation
					iconContainer.setBackgroundDrawable(itemViews.iconDrawable);
				}
			} else if (itemViews.iconDrawableId > 0) {
				iconContainer.setBackgroundResource(itemViews.iconDrawableId);
			}

			// add label
			ViewGroup itemContainer = (ViewGroup) view.findViewById(R.id.speed_dial_item_container);
			if (itemViews.labelView != null) {
				itemContainer.addView(itemViews.labelView, 0);
			} else if (itemViews.labelString != null) {
				TextView tv = new TextView(getContext());
				tv.setText(itemViews.labelString);
				itemContainer.addView(tv, 0);
			} else if (itemViews.labelStringId > 0) {
				TextView tv = new TextView(getContext());
				tv.setText(itemViews.labelStringId);
				itemContainer.addView(tv, 0);
			}

			// reposition
			LayoutParams params = (LayoutParams) view.getLayoutParams();
			params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
			if (Build.VERSION.SDK_INT >= 17) params.addRule(RelativeLayout.ALIGN_PARENT_END);
			params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
			view.setLayoutParams(params);

			// hide
			view.setAlpha(0F);

			// clicks
			view.setTag(i);
			view.setOnClickListener(v -> {
				if (menuAdapter.onMenuItemClick((int) v.getTag())) closeSpeedDialMenu();
			});
		}
	}

	/**
	 * Closes the speed-dial menu, if it's open.
	 */
	public void closeSpeedDialMenu() {
		if (speedDialMenuOpen) toggleSpeedDialMenu();
	}

	/**
	 * Opens the speed-dial menu, if it's closed and the FAB is shown.
	 */
	public void openSpeedDialMenu() {
		if (!speedDialMenuOpen && shown) toggleSpeedDialMenu();
	}

	/**
	 * Toggles the speed-dial menu between open and closed.
	 */
	private void toggleSpeedDialMenu() {
		// busy?
		if (busyAnimatingFabIcon
				|| busyAnimatingSpeedDialCover
				|| busyAnimatingSpeedDialMenu) return;

		// flip
		speedDialMenuOpen = !speedDialMenuOpen;

		// change UI
		if (menuAdapter.rotateFab()) toggleFabIconForSpeedDialMenu(speedDialMenuOpen);
		setSpeedDialCoverVisible(speedDialMenuOpen);
		setSpeedDialMenuVisible(speedDialMenuOpen);

		// setup "outside click" listeners
		coverView.setClickable(speedDialMenuOpen);
		coverView.setFocusable(speedDialMenuOpen);
		if (speedDialMenuOpen) {
			coverView.setOnClickListener(v -> toggleSpeedDialMenu());
		} else {
			coverView.setOnClickListener(null);
		}
	}

	/**
	 * Toggles the FAB icon state, based on whether or not the speed-dial menu is open.
	 *
	 * @param visible {@code true} to indicate that the menu is open
	 */
	private void toggleFabIconForSpeedDialMenu(boolean visible) {
		// busy?
		if (busyAnimatingFabIcon) return;
		busyAnimatingFabIcon = true;

		// animate
		iconContainer.animate()
				.rotation(visible ? 45F : 0F)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(new AnimatorListenerAdapter() {
					@Override
					public void onAnimationEnd(Animator animation) {
						busyAnimatingFabIcon = false;
					}
				});
	}

	/**
	 * Toggles the "cover", based on whether or not the speed-dial menu is open.
	 *
	 * @param visible {@code true} to indicate that the menu is open
	 */
	private void setSpeedDialCoverVisible(boolean visible) {
		// busy?
		if (busyAnimatingSpeedDialCover) return;
		busyAnimatingSpeedDialCover = true;

		// animate
		coverView.animate()
				.scaleX(visible ? 50F : 0F)
				.scaleY(visible ? 50F : 0F)
				.alpha(visible ? 1F : 0F)
				.setDuration(SPEED_DIAL_ANIMATION_DURATION)
				.setListener(new AnimatorListenerAdapter() {
					@Override
					public void onAnimationEnd(Animator animation) {
						busyAnimatingSpeedDialCover = false;
					}
				});
	}

	/**
	 * Toggles the speed-dial menu items, based on whether or not the speed-dial menu is open.
	 *
	 * @param visible {@code true} to indicate that the menu is open
	 */
	private void setSpeedDialMenuVisible(boolean visible) {
		// busy?
		if (busyAnimatingSpeedDialMenu) return;
		busyAnimatingSpeedDialMenu = true;

		// animate
		int distance = cardView.getHeight();
		for (int i = 0, n = speedDialMenuItems.size(); i < n; ++i) {
			speedDialMenuItems.get(i).animate()
					.translationY(visible ? ((i + 1) * distance * -1) - (distance / 8) : 0F)
					.alpha(visible ? 1F : 0F)
					.setDuration(SPEED_DIAL_ANIMATION_DURATION)
					.setListener(new AnimatorListenerAdapter() {
						@Override
						public void onAnimationEnd(Animator animation) {
							busyAnimatingSpeedDialMenu = false;
						}
					});
		}
	}

	/*====================*
	 * State preservation *
	 *====================*/

	private int savedIconResId = -1;
	private int savedBgColour = 0x3f51b5;

	@Override
	protected Parcelable onSaveInstanceState() {
		Bundle bundle = new Bundle();
		bundle.putBoolean("shown", shown);
		bundle.putInt("savedIconResId", savedIconResId);
		bundle.putInt("savedBgColour", savedBgColour);
		bundle.putParcelable("SUPER", super.onSaveInstanceState());
		return bundle;
	}

	@Override
	protected void onRestoreInstanceState(Parcelable state) {
		if (state != null && state instanceof Bundle) {
			Bundle bundle = (Bundle) state;

			// shown?
			if (bundle.containsKey("shown") && !bundle.getBoolean("shown")) {
				// hide immediately
				hide(true);
			}

			// icon resource ID
			if (bundle.containsKey("savedIconResId")) {
				savedIconResId = bundle.getInt("savedIconResId");
				if (savedIconResId > -1) setIcon(savedIconResId);
			}

			// background colour
			if (bundle.containsKey("savedBgColour")) {
				savedBgColour = bundle.getInt("savedBgColour");
				Log.d(C.LOG_TAG, "" + savedBgColour);
				setBackgroundColour(savedBgColour);
			}

			// super-state
			state = bundle.getParcelable("SUPER");
		}
		super.onRestoreInstanceState(state);
	}
}