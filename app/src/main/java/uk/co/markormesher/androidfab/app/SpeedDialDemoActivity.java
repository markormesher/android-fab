package uk.co.markormesher.androidfab.app;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
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

		// find FAB
		fab = (FloatingActionButton) findViewById(R.id.fab);

		// set up speed-dial
		fab.setMenuAdapter(new DemoAdapter());
	}

	private class DemoAdapter extends SpeedDialMenuAdapter {

		@Override
		protected int getCount() {
			return 5;
		}

		@Override
		protected View[] getViews(Context context, int position) {
			return new View[2];
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