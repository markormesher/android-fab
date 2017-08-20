package uk.co.markormesher.android_fab.app

import android.os.Bundle
import android.os.PersistableBundle
import android.support.v7.app.AppCompatActivity

class DemoActivity: AppCompatActivity() {

	override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
		super.onCreate(savedInstanceState, persistentState)
		setContentView(R.layout.demo_activity)
	}
}
