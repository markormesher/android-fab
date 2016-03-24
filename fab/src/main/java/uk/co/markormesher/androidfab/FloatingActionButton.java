package uk.co.markormesher.androidfab;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.annotation.SuppressLint;
import android.content.Context;
import android.support.v7.widget.CardView;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import uk.co.markormesher.androidfab.constants.C;
import uk.co.markormesher.androidfab.fab.R;

import java.util.ArrayList;

public class FloatingActionButton extends RelativeLayout {

	private static final long ANIMATION_DURATION = 200L;

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

	/*=====================*
	 * View initialisation *
	 *=====================*/

	private RelativeLayout fabContainer;
	private CardView cardView;
	private ViewGroup iconContainer;
	private View coverView;

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
	}

	/**
	 * Sets the @{code View} to use as the icon on the FAB.
	 *
	 * @param icon the @{code View} to use as the icon on the FAB
	 */
	public void setIcon(View icon) {
		iconContainer.removeAllViews();
		if (icon != null) {
			if (icon.getParent() != null) ((ViewGroup) icon.getParent()).removeView(icon);
			iconContainer.addView(icon);
		}
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
	 */
	public void setMenuAdapter(SpeedDialMenuAdapter menuAdapter) {
		this.listener = null;
		this.menuAdapter = menuAdapter;
		if (menuAdapter != null) createSpeedDialMenuItems();
	}

	/**
	 * Generates the items for the speed dial menu, according to the specified adapter.
	 */
	@SuppressLint("InlinedApi")
	private void createSpeedDialMenuItems() {
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
			View view = LayoutInflater.from(getContext()).inflate(R.layout.speed_dial_button, null);
			fabContainer.addView(view, 1);
			speedDialMenuItems.add(view);

			// add child views
			View[] adapterViews = menuAdapter.getViews(getContext(), i);
			if (adapterViews.length != 2) throw new IllegalStateException("getViews() must return exactly two views.");
			if (adapterViews[0] != null) {
				((ViewGroup) view.findViewById(R.id.icon_container)).addView(adapterViews[0], 0);
			}
			if (adapterViews[1] != null) {
				((ViewGroup) view.findViewById(R.id.speed_dial_item_container)).addView(adapterViews[1], 0);
			}

			// reposition
			RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams) view.getLayoutParams();
			params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
			if (android.os.Build.VERSION.SDK_INT >= 17) params.addRule(RelativeLayout.ALIGN_PARENT_END);
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
	 * Opens the speed-dial menu, if it's closed.
	 */
	public void openSpeedDialMenu() {
		if (!speedDialMenuOpen) toggleSpeedDialMenu();
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
	 * @param visible @{code true} to indicate that the menu is open
	 */
	private void toggleFabIconForSpeedDialMenu(boolean visible) {
		// busy?
		if (busyAnimatingFabIcon) return;
		busyAnimatingFabIcon = true;

		// animate
		iconContainer.animate()
				.rotation(visible ? 45F : 0F)
				.setDuration(ANIMATION_DURATION)
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
	 * @param visible @{code true} to indicate that the menu is open
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
				.setDuration(ANIMATION_DURATION)
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
	 * @param visible @{code true} to indicate that the menu is open
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
					.setDuration(ANIMATION_DURATION)
					.setListener(new AnimatorListenerAdapter() {
						@Override
						public void onAnimationEnd(Animator animation) {
							busyAnimatingSpeedDialMenu = false;
						}
					});
		}
	}

}