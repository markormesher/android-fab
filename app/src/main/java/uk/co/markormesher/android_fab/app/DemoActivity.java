package uk.co.markormesher.android_fab.app;

import android.content.Context;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import uk.co.markormesher.android_fab.FloatingActionButton;
import uk.co.markormesher.android_fab.SpeedDialMenuAdapter;
import uk.co.markormesher.android_fab.constants.C;

public class DemoActivity extends AppCompatActivity {

	private FloatingActionButton fab;
	private boolean inClickMode = false;
	private int iconSelected = -1;
	private int fabColourSelected = -1;
	private boolean speedDialColoursEnabled = false;
	private boolean speedDialOptionalCloseEnabled = false;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.fab_activity);
		setTitle(R.string.app_name);

		// get reference to FAB
		fab = (FloatingActionButton) findViewById(R.id.fab);

		// get references to buttons
		final Button switchModeButton = (Button) findViewById(R.id.switch_mode);
		final Button toggleSpeedDialColoursSwitch = (Button) findViewById(R.id.toggle_colours);
		final Button toggleSpeedDialOptionalCloseButton = (Button) findViewById(R.id.toggle_optional_close);
		final Button openSpeedDialButton = (Button) findViewById(R.id.open_speed_dial);

		switchModeButton.setOnClickListener(v -> {
			inClickMode = !inClickMode;
			if (inClickMode) {
				fab.setOnClickListener(iv -> Toast.makeText(DemoActivity.this, R.string.click_simple, Toast.LENGTH_SHORT).show());
				switchModeButton.setText(R.string.switch_mode_1);
			} else {
				fab.setMenuAdapter(new SpeedDialAdapter());
				switchModeButton.setText(R.string.switch_mode_2);
			}
			toggleSpeedDialColoursSwitch.setEnabled(!inClickMode);
			toggleSpeedDialOptionalCloseButton.setEnabled(!inClickMode);
			openSpeedDialButton.setEnabled(!inClickMode);
		});

		findViewById(R.id.change_icon).setOnClickListener(v -> {
			int[] icons = new int[]{
					R.mipmap.ic_add,
					R.mipmap.ic_done,
					R.mipmap.ic_cloud,
					R.mipmap.ic_swap_horiz,
					R.mipmap.ic_swap_vert
			};
			iconSelected = ++iconSelected % icons.length;
			fab.setIcon(icons[iconSelected]);
		});

		findViewById(R.id.change_button_colour).setOnClickListener(v -> {
			int[] colours = new int[]{
					0xff0099ff,
					0xffff9900,
					0xffff0099,
					0xff9900ff
			};
			fabColourSelected = ++fabColourSelected % colours.length;
			fab.setBackgroundColour(colours[fabColourSelected]);
		});

		toggleSpeedDialColoursSwitch.setOnClickListener(v -> {
			speedDialColoursEnabled = !speedDialColoursEnabled;
			if (speedDialColoursEnabled) {
				toggleSpeedDialColoursSwitch.setText(R.string.toggle_colours_2);
			} else {
				toggleSpeedDialColoursSwitch.setText(R.string.toggle_colours_1);
			}
			fab.rebuildSpeedDialMenu();
		});

		toggleSpeedDialOptionalCloseButton.setOnClickListener(v -> {
			speedDialOptionalCloseEnabled = !speedDialOptionalCloseEnabled;
			if (speedDialOptionalCloseEnabled) {
				toggleSpeedDialOptionalCloseButton.setText(R.string.toggle_optional_close_2);
			} else {
				toggleSpeedDialOptionalCloseButton.setText(R.string.toggle_optional_close_1);
			}
			fab.rebuildSpeedDialMenu();
		});

		openSpeedDialButton.setOnClickListener(v -> fab.openSpeedDialMenu());

		// set stuff going
		findViewById(R.id.switch_mode).performClick();
		findViewById(R.id.change_icon).performClick();
	}

	private class SpeedDialAdapter extends SpeedDialMenuAdapter {

		@Override
		protected int getCount() {
			return speedDialOptionalCloseEnabled ? 4 : 3;
		}

		@Override
		protected MenuItem getViews(Context context, int position) {
			switch (position) {
				case 0:
					// example: View and View
					ImageView icon0 = new ImageView(context);
					icon0.setImageResource(R.mipmap.ic_done);
					TextView label0 = new TextView(context);
					label0.setText(getString(R.string.speed_dial_label, position));
					return new MenuItem() {{
						iconView = icon0;
						labelView = label0;
					}};

				case 1:
					// example: Drawable and String
					return new MenuItem() {{
						iconDrawable = ContextCompat.getDrawable(context, R.mipmap.ic_swap_horiz);
						labelString = getString(R.string.speed_dial_label, position);
					}};

				case 2:
					// example: Drawable ID and String
					return new MenuItem() {{
						iconDrawableId = R.mipmap.ic_swap_vert;
						labelString = getString(R.string.speed_dial_label, position);
					}};

				case 3:
					// example: Drawable ID and String ID
					return new MenuItem() {{
						iconDrawableId = R.mipmap.ic_cloud;
						labelStringId =  R.string.label_optional_close;
					}};

				default:
					Log.wtf(C.LOG_TAG, "Okay, something went *really* wrong.");
					return new MenuItem();
			}
		}

		@Override
		protected int getBackgroundColour(int position) {
			if (speedDialColoursEnabled) {
				int[] colours = new int[]{
						0xffff9900,
						0xff0099ff,
						0xffff0099,
						0xff9900ff
				};
				return colours[position];
			}

			return super.getBackgroundColour(position);
		}

		@Override
		protected boolean onMenuItemClick(int position) {
			if (position == 3) {
				AlertDialog.Builder builder = new AlertDialog.Builder(DemoActivity.this);
				builder
						.setTitle(R.string.menu_close_dialog_title)
						.setMessage(R.string.menu_close_dialog_text)
						.setPositiveButton(R.string.yes, (dialog, which) -> fab.closeSpeedDialMenu())
						.setNegativeButton(R.string.no, null)
						.setCancelable(false);
				builder.create().show();
				return false;
			} else {
				Toast.makeText(DemoActivity.this, getString(R.string.click_with_item, position), Toast.LENGTH_SHORT).show();
				return true;
			}
		}

		@Override
		protected boolean rotateFab() {
			return iconSelected == 0;
		}
	}
}