# This is a configuration file for ProGuard.
# http://proguard.sourceforge.net/index.html#manual/usage.html

-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Optimization is turned off by default. Dex does not like code run
# through the ProGuard optimize and preverify steps (and performs some
# of these optimizations on its own).
-dontoptimize
-dontpreverify
-keepattributes *Annotation*
-keep public class com.google.vending.licensing.ILicensingService
-keep public class com.android.vending.licensing.ILicensingService

# hide warnings caused by Retrolamdba
-dontwarn java.lang.invoke.*

# native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# parcelable object
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# keep line numbers intact
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
