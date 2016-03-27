package uk.co.markormesher.android_fab.app;

import android.content.Context;
import android.os.Bundle;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import uk.co.markormesher.android_fab.FloatingActionButton;
import uk.co.markormesher.android_fab.SpeedDialMenuAdapter;

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

		// initialise fab
		fab = (FloatingActionButton) findViewById(R.id.fab);

		// clicks
		final Button switchModeButton = (Button) findViewById(R.id.switch_mode);
		switchModeButton.setOnClickListener(v -> {
			inClickMode = !inClickMode;
			if (inClickMode) {
				fab.setOnClickListener(iv -> Toast.makeText(DemoActivity.this, R.string.click_simple, Toast.LENGTH_SHORT).show());
				switchModeButton.setText(R.string.switch_mode_1);
			} else {
				fab.setMenuAdapter(new SpeedDialAdapter());
				switchModeButton.setText(R.string.switch_mode_2);
			}
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
			ImageView icon = new ImageView(this);
			icon.setImageResource(icons[iconSelected]);
			fab.setIcon(icon);
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
		findViewById(R.id.toggle_colours).setOnClickListener(v -> {
			speedDialColoursEnabled = !speedDialColoursEnabled;
			fab.rebuildSpeedDialMenu();
		});
		findViewById(R.id.toggle_optional_close).setOnClickListener(v -> {
			speedDialOptionalCloseEnabled = !speedDialOptionalCloseEnabled;
			fab.rebuildSpeedDialMenu();
		});

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
		protected View[] getViews(Context context, int position) {
			ImageView icon = new ImageView(context);
			TextView label = new TextView(context);

			switch (position) {
				case 0:
					icon.setImageResource(R.mipmap.ic_done);
					label.setText(getString(R.string.speed_dial_label, position));
					break;

				case 1:
					icon.setImageResource(R.mipmap.ic_swap_horiz);
					label.setText(getString(R.string.speed_dial_label, position));
					break;

				case 2:
					icon.setImageResource(R.mipmap.ic_swap_vert);
					label.setText(getString(R.string.speed_dial_label, position));
					break;

				case 3:
					icon.setImageResource(R.mipmap.ic_cloud);
					label.setText(getString(R.string.label_optional_close));
					break;
			}

			View[] output = new View[2];
			output[0] = icon;
			output[1] = label;
			return output;
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
						.setPositiveButton(R.string.yes, null)
						.setNegativeButton(R.string.no, (dialog, which) -> fab.closeSpeedDialMenu())
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