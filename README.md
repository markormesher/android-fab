# Floating Action Button with Speed-Dial Menu

[ ![Download](https://api.bintray.com/packages/markormesher/maven/android-fab/images/download.svg) ](https://bintray.com/markormesher/maven/android-fab/_latestVersion)

This library provides a clickable floating action button (FAB) with an optional speed-dial menu. The FAB can trigger a standard click listener or a open the speed-dial menu with further options. All aspects of the FAB and speed-dial menu are customisable.

## Demo

![Demonstration of the speed-dial menu](misc/demo.gif)

You can try the demo in one of two ways:

1. Clone this repository and install the demo app from the `app/` folder (you can do this with Gradle, using `gradle clean installDebug`).

2. Download the sample app from the Google Play Store: [Floating Action Button Demo](https://play.google.com/store/apps/details?id=uk.co.markormesher.android_fab.app)

## Installation

### Gradle

    compile 'uk.co.markormesher:android-fab:2.0.0'

### Maven

    <dependency>
      <groupId>uk.co.markormesher</groupId>
      <artifactId>android-fab</artifactId>
      <version>2.0.0</version>
      <type>pom</type>
    </dependency>

---

Note: depending on your app's configuration, you may need to add the following to your ProGuard rules:

    -dontwarn java.lang.invoke.*

See [app/proguard-rules.pro](app/proguard-rules.pro) for an example.

## Usage & Customisation

**Note:** all of the instructions below assume that the FAB is referenced by the variable `fab`, i.e.

	// Java
    FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
    
    // Kotlin (without Android extensions)
    val fab = findViewById(R.id.fab) as FloatingActionButton

### Placing the FAB in Your Layout

The `FloatingActionButton` view must be placed at the **root** of your layout, **above** all other views, and with **maximum width and height**. This allows the semi-transparent layer to expand and cover the entire layout when the speed-dial menu is opened.

    <uk.co.markormesher.android_fab.FloatingActionButton
        android:id="@+id/fab"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        />

### FAB Position

The FAB can be positioned in any of the four corners of the activity via XML or with `fab.setButtonPosition(...)`. The default position is the bottom-end corner.

	// Java
	fab.setButtonPosition(POSITION_BOTTOM | POSITION_END);
	
	// Kotlin
	fab.setButtonPosition(POSITION_BOTTOM.or(POSITION_END))
	
	// XML
	<uk.co.markormesher.android_fab.FloatingActionButton
		xmlns:app="http://schemas.android.com/apk/res-auto"
		...
		app:buttonPosition="bottom|end"
		/>
		
The FAB is aware of text-direction (right-to-left or left-to-right) and adjusts the meaning of "start" and "end" positions accordingly. This functionality can be overridden using the named constants for left and right.

### FAB Icon

The icon displayed in the centre of the FAB can be set via XML using a `Drawable` reference or with `fab.setButtonIconResource(...)` using a `Drawable` resource ID. The icon will be centred in a 24dp x 24dp view group, as per the Android Material Design specs.

	// Java
	fab.setButtonIconResource(R.drawable.ic_add);
	
	// Kotlin
	fab.setButtonIconResource(R.drawable.ic_add)
	
	// XML
	<uk.co.markormesher.android_fab.FloatingActionButton
		xmlns:app="http://schemas.android.com/apk/res-auto"
		...
		app:buttonIcon="@drawable/ic_add"
		/>

### FAB Background Colour

The background colour of the FAB can be set via XML using a colour reference or programmatically with `fab.setButtonBackgroundColour(...)` using an aRGB colour value (e.g. `0xffff9900` for dark orange). Note that the second method does **not** take a colour resource ID, so passing in `R.color.some_colour_name` will not work.

	// Java
	fab.setButtonBackgroundColour(0xffff9900);
	
	// Kotlin
	fab.setButtonBackgroundColour(0xffff9900.toInt())
	
	// XML
	<uk.co.markormesher.android_fab.FloatingActionButton
		xmlns:app="http://schemas.android.com/apk/res-auto"
		...
		app:buttonBackgroundColour="@color/fab_colour"
		/>

### FAB Click Listener

A click listener can be added to the FAB in the same way as any other button. The view passed to the listener can be safely cast to a `FloatingActionButton`.

	// Java
	fab.setOnClickListener(new View.OnClickListener() {
		@Override
		public void onClick(View v) {
			// ...
		}
	});
	
	// Kotlin
	fab.setOnClickListener { v ->
		// ...
	}

:warning: See the note below on [click action priority](#note-click-action-priority).

:x: DOCS UP TO DATE UP TO THIS POINT.

### Speed-Dial Menu

The speed-dial menu is enabled by creating a class that extends `SpeedDialMenuAdapter` and passing it to `fab.setSpeedDialMenuAdapter(...)`. The adapter class methods are [documented in-situ](fab/src/main/java/uk/co/markormesher/android_fab/SpeedDialMenuAdapter.kt).

:warning: See the note below on [click action priority](#note-click-action-priority).

### Speed-Dial Menu Content Cover

The colour to be used for the layer that obscures content when the speed-dial menu is opened should be set with `fab.setContentCoverColour(...)`, passing in an aRGB colour value (e.g. `0x99ff9900` for a semi-transparent dark orange). Note that this method does **not** take a colour resource ID, so passing in `R.color.some_colour_name` will not work.

The cover can be enabled/disabled entirely using `fab.setContentCoverEnabled(...)`. It is enabled by default.

### Speed-Dial Menu State Change Listeners

Two state change listeners are provided to monitor when the speed-dial menu opens or closes, which can be specified with `fab.setOnSpeedDialMenuOpenListener` and `fab.setOnSpeedDialMenuCloseListener`.

### Show/Hide Controls

The FAB can be hidden and shown with the `fab.hide()` and `fab.show()` methods, and the method `fab.isShown()` will return a boolean indicating the current state. These methods animate the FAB in and out of visibility. If the speed-dial menu is open when `.hide()` is called it will be closed.  

The speed-dial menu can be manually opened and closed with `fab.openSpeedDialMenu()` and `fab.closeSpeedDialMenu()`. These methods will do nothing if no speed-dial menu adapter is set, if the FAB is hidden, or if they are called when the menu is already in the indicated state (i.e. `fab.openSpeedDialMenu()` will do nothing if the menu is already open).

### Note: Click Action Priority

As per Material Design specs, the FAB functions as a regular button **or** a trigger for the speed-dial menu, but not both. For this reason, the click listener and the speed-dial menu are never invoked at the same time.

The speed-dial menu is given priority: when the FAB is clicked the speed-dial menu will be shown if the speed-dial menu adapter is non-null, the adapter's `isEnabled()` function returns `true` and the adapter's `getCount()` returns a number greater than zero. Otherwise, the FAB's click listener will be called (if it has been set).

Setting a speed-dial menu adapter does not remove the click listener, and setting a click listener does not remove the speed-dial menu adapter. For an example of how the two operation modes interact, check the demo app's source code.
 
To receive state change updates when the speed-dial menu is opened or closed, use the open/close listeners described above.

### Note: State Preservation

TODO
