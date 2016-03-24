package uk.co.markormesher.androidfab.app;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import uk.co.markormesher.androidfab.FloatingActionButton;
import uk.co.markormesher.androidfab.SpeedDialMenuAdapter;

public class SpeedDialDemoActivity extends AppCompatActivity {

	private FloatingActionButton fab;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.fab_activity);
		setTitle(R.string.speed_dial_demo);

		// switch button
		Button switchDemoButton = (Button) findViewById(R.id.switch_demo);
		switchDemoButton.setText(R.string.goto_click_demo);
		switchDemoButton.setOnClickListener(v -> {
			startActivity(new Intent(SpeedDialDemoActivity.this, ClickDemoActivity.class));
			finish();
		});

		// initialise fab
		fab = (FloatingActionButton) findViewById(R.id.fab);
		ImageView icon = new ImageView(this);
		icon.setImageResource(R.mipmap.ic_add);
		fab.setIcon(icon);

		// set up speed-dial
		fab.setMenuAdapter(new DemoAdapter());
	}

	private class DemoAdapter extends SpeedDialMenuAdapter {

		@Override
		protected int getCount() {
			return 4;
		}

		@Override
		protected View[] getViews(Context context, int position) {
			// make views
			ImageView icon = new ImageView(context);
			TextView label = new TextView(context);

			// set content
			switch (position) {
				case 0:
					icon.setImageResource(R.mipmap.ic_cloud);
					label.setText(R.string.label_optional_close);
					break;

				case 1:
					icon.setImageResource(R.mipmap.ic_done);
					label.setText(R.string.label_done);
					break;

				case 2:
					icon.setImageResource(R.mipmap.ic_swap_horiz);
					label.setText(R.string.label_swap_h);
					break;

				case 3:
					icon.setImageResource(R.mipmap.ic_swap_vert);
					label.setText(R.string.label_swap_v);
					break;

			}

			View[] output = new View[2];
			output[0] = icon;
			output[1] = label;
			return output;
		}

		@Override
		protected boolean onMenuItemClick(int position) {
			// possibly keep the menu open
			if (position == 0) {
				AlertDialog.Builder builder = new AlertDialog.Builder(SpeedDialDemoActivity.this);
				builder
						.setTitle(R.string.menu_close_dialog_title)
						.setMessage(R.string.menu_close_dialog_text)
						.setPositiveButton(R.string.yes, null)
						.setNegativeButton(R.string.no, (dialog, which) -> fab.closeSpeedDialMenu())
						.setCancelable(false);
				builder.create().show();
				return false;
			}

			// otherwise, show a message...
			Toast.makeText(SpeedDialDemoActivity.this, getString(R.string.click_with_item, position), Toast.LENGTH_SHORT).show();

			// ...and close the menu
			return true;
		}
	}
}