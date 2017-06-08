# Floating Action Button with Speed-Dial Menu

[ ![Download](https://api.bintray.com/packages/markormesher/maven/android-fab/images/download.svg) ](https://bintray.com/markormesher/maven/android-fab/_latestVersion)

This library provides a clickable floating action button (FAB) with an optional speed-dial menu. The FAB can trigger a standard click listener or a open the speed-dial menu with further options. All aspects of the FAB and speed-dial menu are customisable.

- [Demo](#demo)
- [Installation](#installation)
- [Usage & Customisation](#usage--customisation)
- [Links & Other Projects](#links--other-projects)

## Demo

![Demonstration of the speed-dial menu](misc/demo.gif)

You can try the demo yourself in one of two ways:

1. Clone this repository and install the demo app from the `app/` folder (you can do this with Gradle, using `gradle clean installDebug start`).

2. Download the sample app from the Google Play Store: [Floating Action Button Demo](https://play.google.com/store/apps/details?id=uk.co.markormesher.android_fab.app)

## Installation

### Gradle

    compile 'uk.co.markormesher:android-fab:**VERSION**'

### Maven

    <dependency>
      <groupId>uk.co.markormesher</groupId>
      <artifactId>android-fab</artifactId>
      <version>**VERSION**</version>
      <type>pom</type>
    </dependency>

### Ivy

    <dependency org='uk.co.markormesher' name='android-fab' rev='**VERSION**'>
      <artifact name='$AID' ext='pom'></artifact>
    </dependency>

---

Note: depending on your app's configuration, you may need to add the following to your ProGuard rules:

    -dontwarn java.lang.invoke.*

See [app/proguard-rules.pro](https://github.com/markormesher/android-fab/blob/development/app/proguard-rules.pro) for an example.

## Usage & Customisation

**Note:** all of the instructions below assume that the Floating Action Button is referenced by the variable `fab`, i.e.

    FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);

### Placing the FAB in Your Layout

The `FloatingActionButton` view must be placed at the **root** of your layout, **above** all other views, and with **maximum width and height**. This allows the semi-transparent layer to expand and cover the entire layout when the speed-dial menu is opened.

    <uk.co.markormesher.android_fab.FloatingActionButton
        android:id="@+id/fab"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>

### FAB Icon

The icon displayed in the centre of the FAB should be set with `fab.setIcon(...)`, passing in the `View`, `Drawable` or `Drawable` resource ID to use. This `View` will be centred in a 24dp x 24dp view group, as per the Android Material Design specs.

:warning: See the note below on [state preservation](#note-state-preservation).

### FAB Background Colour

The background colour to be used for the FAB should be set with `fab.setBackgroundColor(...)`, passing in an aRGB colour value (e.g. `0xffff9900` for a dark orange). Note that this method does **not** take a colour resource ID, so passing in `R.color.some_colour_name` will not work.

:warning: See the note below on [state preservation](#note-state-preservation).

### FAB Click Listener

A click listener can be added to the FAB in the same way as any other button:

    fab.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            // ...
        }
    });
    
or
    
    fab.setOnClickListener(v -> {
        // ...
    });

The view `v` passed in the callback can be safely cast to `FloatingActionButton`.

:warning: See the note below on [click action priority](#note-click-action-priority).

### Accessing FAB Views

Some of the component views that make up the FAB can be accessed (useful for positioning [tooltips](https://github.com/markormesher/android-tooltips)) using the following methods:

|Method | Description|
|:--- | :---|
|`RelativeLayout getFabContainer()` | Gets the container layout used for the whole FAB arrangement.|
|`ViewGroup getButton()` | Gets the `ViewGroup` used for the actual "button" of the FAB. On SDK >= 21 this can be safely cast to `CardView`.|

### Speed-Dial Menus

The speed-dial menu can be enabled by creating a class that extends `SpeedDialMenuAdapter` and then calling `setAdapter(...)` on the FAB.

The adapter class has several methods that can be overridden to control the menu:

|Method | Description|
|:--- | :---|
|`int getCount()` | **must** be overridden to return the number of menu items.|
|`MenuItem getViews(Context context, int position)` | **must** be overridden to return a `MenuItem` wrapper for the given position. This method will be called to create a wrapper once per menu item. The wrapper allows the icon for a menu item to be specified as a `View`, a `Drawable` or a `Drawable` ID, and allows the label to be specified as a `View`, a `String` or a `String` ID.<br /><br />If multiple properties are specified for the icon or label, the first non-null in the order [`View`, `Drawable` or `String`, resource ID] will be applied. No parameters are required: all label fields could be left as `null` to produce an icon-only menu item for example; everything could be left as `null` to produce a blank menu item, but that would be quite useless.
|`int getBackgroundColour(int position)` | **may** be overridden to return the background colour that should be used for the disc at the given position.|
|`boolean onMenuItemClick(int position)` | **may** be overridden to listen for clicks on the individual menu items. Return `true` to close the menu after the click has been handled (the default behaviour) or `false` to leave it open.|
|`boolean rotateFab()` | **may** be overridden to specify whether the FAB should rotate by 1/8th of a turn when the speed-dial menu opens. This is useful for smoothly transitioning between a '+' and 'x' icon.|
|`boolean isEnabled()` | **may** be overridden to enable or disable the speed-dial menu. This is useful for temporarily disabling the speed-dial menu without having to set the adapter to `null`.|

**Note:** for all methods, the view at position `0` is the furthest away from the FAB; the view at `getCount() - 1` is the closest.

If the state or functionality has changed such that `getCount()` or `getViews(...)` will have a different output, `fab.rebuildSpeedDialMenu()` must be called to regenerate the speed-dial menu item views. If `getCount()` returns zero when `rebuildSpeedDialMenu()` is called the speed-dial menu will be disabled until it is called again and `getCount()` returns a number greater than zero.

:warning: See the note below on [click action priority](#note-click-action-priority).

### Speed-Dial Content Cover Colour

The colour to be used for the layer that obscures content when the speed-dial menu is opened should be set with `fab.setContentCoverColour(...)`, passing in an aRGB colour value (e.g. `0x99ff9900` for a semi-transparent dark orange). Note that this method does **not** take a colour resource ID, so passing in `R.color.some_colour_name` will not work.

:warning: See the note below on [state preservation](#note-state-preservation).

### Speed-Dial State Change Listeners

Two state change listeners are provided to monitor when the speed-dial menu opens or closes. These can be used as follows:

    fab.setOnSpeedDialOpenListener(new FloatingActionButton.OnSpeedDialOpenListener() {
        @Override
        public void onOpen(FloatingActionButton v) {
            // ...
        }
    });
    fab.setOnSpeedDialCloseListener(new FloatingActionButton.OnSpeedDialCloseListener() {
        @Override
        public void onClose(FloatingActionButton v) {
            // ...
        }
    });
    
or
    
    fab.setOnSpeedDialOpenListener(v -> {
        // ...
    });
    fab.setOnSpeedDialCloseListener(v -> {
        // ...
    });

### Controls

The FAB can be hidden and shown with the `fab.hide()` and `fab.show()` methods, and the method `fab.isShown()` will return a boolean indicating the current state. These methods animate the FAB in and out of visibility. If the speed-dial menu is open when `.hide()` is called it will be closed.  

The speed-dial menu can be manually opened and closed with `fab.openSpeedDialMenu()` and `fab.closeSpeedDialMenu()`. These methods will do nothing if no speed-dial menu adapter is set, if the FAB is hidden, or if they are called when the menu is already in the indicated state (i.e. `fab.openSpeedDialMenu()` will do nothing if the menu is already open).

### Note: Click Action Priority

As per Material Design specs, the FAB functions as a regular button **or** a trigger for the speed-dial menu, but not both. For this reason, the click listener and the speed-dial menu are never invoked at the same time.

The speed-dial menu is given priority: when the FAB is clicked the speed-dial menu will be shown if the speed-dial menu adapter is non-null **and** the adapter's `isEnabled()` function returns true. Otherwise, the FAB's click listener will be called (if it has been set).

Setting a speed-dial menu adapter does not remove the click listener, and setting a click listener does not remove the speed-dial menu adapter. For an example of how the two operation modes interact, check the demo app's source code.
 
To receive state change updates when the speed-dial menu is opened or closed, use the open/close listeners described above.

### Note: State Preservation

When a configuration change happens within your app and the activity/fragment is forced to rebuild its layout, the FAB does some primitive state preservation and restoration. The following settings are preserved between configuration changes:

- whether the icon is shown or hidden (see [Controls](#controls));
- the FAB icon, **if and only if** it was set as a `Drawable` resource ID;
- the FAB background colour;
- the content cover background colour.

All other properties (`View`/`Drawable` icons, speed-dial menu adapters, etc.) will need to be restored "manually". The demo application shows how this can be accomplished.

## Links & Other Projects

- [Mark Ormesher](http://markormesher.co.uk) - My personal site
