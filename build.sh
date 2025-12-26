#!/bin/bash
set -e

echo "=== APK AUTO BUILDER (Render) ==="

# REQUIRED ENV VARS (set in Render dashboard)
: "${APP_NAME:?Missing APP_NAME}"
: "${PACKAGE:?Missing PACKAGE}"
: "${TG_BOT_TOKEN:?Missing TG_BOT_TOKEN}"
: "${TG_CHAT_ID:?Missing TG_CHAT_ID}"

ANDROID_JAR=$ANDROID_HOME/platforms/android-34/android.jar
OUT=output
SRC=build

send_tg() {
 curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
  -d chat_id="$TG_CHAT_ID" \
  -d text="$1" > /dev/null
}

send_tg "🟡 Build started\n📦 $APP_NAME"

rm -rf $SRC $OUT
mkdir -p $SRC/src $SRC/obj $SRC/res/mipmap $OUT

# Manifest
cat > $SRC/AndroidManifest.xml <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
 package="$PACKAGE">
 <application android:label="$APP_NAME">
  <activity android:name="android.app.Activity">
   <intent-filter>
    <action android:name="android.intent.action.MAIN"/>
    <category android:name="android.intent.category.LAUNCHER"/>
   </intent-filter>
  </activity>
 </application>
</manifest>
EOF

# Java
cat > $SRC/src/MainActivity.java <<EOF
package $PACKAGE;
import android.app.Activity;
public class MainActivity extends Activity {}
EOF

javac -classpath $ANDROID_JAR -d $SRC/obj $SRC/src/MainActivity.java
send_tg "🟢 Java compiled"

aapt package -f \
 -M $SRC/AndroidManifest.xml \
 -I $ANDROID_JAR \
 -F $OUT/unsigned.apk

jar cf $SRC/classes.jar -C $SRC/obj .
aapt add $OUT/unsigned.apk $SRC/classes.jar

# Keystore
keytool -genkeypair -keystore debug.jks \
 -storepass android -keypass android \
 -alias debug -keyalg RSA \
 -dname "CN=Android" -validity 10000

apksigner sign \
 --ks debug.jks \
 --ks-pass pass:android \
 $OUT/unsigned.apk

send_tg "✅ Build SUCCESS\n📦 $APP_NAME\n📄 APK ready"
