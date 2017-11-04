package uk.co.markormesher.android_fab.extensions

import android.os.Build
import android.widget.RelativeLayout

fun RelativeLayout.LayoutParams.clearParentAlignmentRules() {
	if (Build.VERSION.SDK_INT >= 17) {
		removeRule(RelativeLayout.ALIGN_PARENT_TOP)
		removeRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
		removeRule(RelativeLayout.ALIGN_PARENT_LEFT)
		removeRule(RelativeLayout.ALIGN_PARENT_RIGHT)
		removeRule(RelativeLayout.ALIGN_PARENT_START)
		removeRule(RelativeLayout.ALIGN_PARENT_END)
	} else {
		addRule(RelativeLayout.ALIGN_PARENT_TOP, 0)
		addRule(RelativeLayout.ALIGN_PARENT_BOTTOM, 0)
		addRule(RelativeLayout.ALIGN_PARENT_LEFT, 0)
		addRule(RelativeLayout.ALIGN_PARENT_RIGHT, 0)
	}
}
