#!/usr/bin/env bash
set -e

echo "=============================="
echo " ANDROID AUTO BUILDER STARTED "
echo "=============================="

# ===============================
# CONFIG (from Render ENV)
# ===============================
APP_NAME="${APP_NAME:-AutoApp}"
PACKAGE="${PACKAGE:-com.example.autoapp}"
SDK="$ANDROID_HOME"
OUT="/app/output"
LOG="/app/build.log"

TG_TOKEN="${TG_BOT_TOKEN}"
TG_CHAT="${TG_CHAT_ID}"

mkdir -p "$OUT"
exec > >(tee "$LOG") 2>&1

# ===============================
# FUNCTIONS
# ===============================
tg_send() {
  if [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]]; then
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
      -d chat_id="$TG_CHAT" \
      -d text="$1" >/dev/null
  fi
}

fail() {
  echo "❌ BUILD FAILED"
  tg_send "❌ Android build failed. Check logs."
  exit 1
}

trap fail ERR

# ===============================
# VALIDATE SDK
# ===============================
echo "✔ Validating Android SDK"
test -f "$SDK/platforms/android-34/android.jar"

# ===============================
# PROJECT STRUCTURE
# ===============================
echo "✔ Creating project"

PKG_PATH=$(echo "$PACKAGE" | tr '.' '/')

mkdir -p build/src/$PKG_PATH
mkdir -p build/res/layout
mkdir -p build/res/mipmap-anydpi-v26
mkdir -p build/bin

# ===============================
# AndroidManifest.xml
# ===============================
cat > build/AndroidManifest.xml <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE">

    <application
        android:label="$APP_NAME"
        android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# ===============================
# MainActivity.java
# ===============================
cat > build/src/$PKG_PATH/MainActivity.java <<EOF
package $PACKAGE;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        TextView t = new TextView(this);
        t.setText("$APP_NAME running!");
        setContentView(t);
    }
}
EOF

# ===============================
# Compile
# ===============================
echo "✔ Compiling Java"
javac -source 8 -target 8 \
  -classpath "$SDK/platforms/android-34/android.jar" \
  -d build/bin \
  $(find build/src -name "*.java")

# ===============================
# APK Packaging
# ===============================
echo "✔ Packaging APK"
aapt package -f \
  -M build/AndroidManifest.xml \
  -S build/res \
  -I "$SDK/platforms/android-34/android.jar" \
  -F build/app-unsigned.apk \
  build/bin

# ===============================
# Debug Signing
# ===============================
echo "✔ Signing APK"
apksigner sign \
  --ks /root/.android/debug.keystore \
  --ks-pass pass:android \
  --out "$OUT/$APP_NAME.apk" \
  build/app-unsigned.apk

# ===============================
# CLOUD FLARED
# ===============================
echo "✔ Starting Cloudflared tunnel"
cloudflared tunnel --url http://localhost:8000 --no-autoupdate &

sleep 3

TUNNEL_URL=$(cloudflared tunnel info 2>/dev/null | grep -o 'https://[^ ]*' | head -n1)

# ===============================
# TELEGRAM NOTIFY
# ===============================
tg_send "✅ APK built successfully
📦 App: $APP_NAME
🌐 URL: $TUNNEL_URL"

# ===============================
# SERVE APK
# ===============================
echo "✔ Serving APK"
cd "$OUT"
python3 -m http.server 8000
