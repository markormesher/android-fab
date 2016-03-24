package uk.co.markormesher.androidfab.app;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import uk.co.markormesher.androidfab.FloatingActionButton;
import uk.co.markormesher.androidfab.SpeedDialMenuAdapter;

public class SpeedDialDemoActivity extends AppCompatActivity {

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
		FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);

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
	}
}