package uk.co.markormesher.androidfab.app;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;
import uk.co.markormesher.androidfab.FloatingActionButton;

public class ClickDemoActivity extends AppCompatActivity {

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.fab_activity);
		setTitle(R.string.click_demo);

		// switch button
		Button switchDemoButton = (Button) findViewById(R.id.switch_demo);
		switchDemoButton.setText(R.string.goto_speed_dial_demo);
		switchDemoButton.setOnClickListener(v -> {
			startActivity(new Intent(ClickDemoActivity.this, SpeedDialDemoActivity.class));
			finish();
		});

		// initialise fab
		FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
		ImageView icon = new ImageView(this);
		icon.setImageResource(R.mipmap.ic_add);
		fab.setIcon(icon);

		// clicks
		fab.setOnClickListener(v -> Toast.makeText(ClickDemoActivity.this, R.string.click_simple, Toast.LENGTH_SHORT).show());
	}
}