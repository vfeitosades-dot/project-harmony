#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
: "${ANDROID_JAR:?Set ANDROID_JAR to platform android.jar}"
: "${ANDROID_BUILD_TOOLS:?Set ANDROID_BUILD_TOOLS to the SDK build-tools directory}"
: "${QUEST_KEYSTORE:?Set QUEST_KEYSTORE to your private signing keystore}"
WORK=$(mktemp -d /tmp/harmony-apk.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/classes" "$WORK/dex" "$WORK/assets" "$ROOT/quest-android/dist"
cp "$ROOT/quest-vr/index.html" "$WORK/assets/index.html"
"$ANDROID_BUILD_TOOLS/aapt2" link -I "$ANDROID_JAR" --manifest "$ROOT/quest-android/AndroidManifest.xml" -A "$WORK/assets" -o "$WORK/app-unsigned.apk"
if [ -n "${ECJ_JAR:-}" ]; then
 java -jar "$ECJ_JAR" -1.8 -bootclasspath "$ANDROID_JAR" -d "$WORK/classes" "$ROOT/quest-android/src/dev/harmony/quest/MainActivity.java"
else
 javac --release 8 -classpath "$ANDROID_JAR" -d "$WORK/classes" "$ROOT/quest-android/src/dev/harmony/quest/MainActivity.java"
fi
python3 - "$WORK" <<'PYJAR'
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import sys
work=Path(sys.argv[1])
with ZipFile(work/'classes.jar','w',ZIP_DEFLATED) as jar:
 for path in (work/'classes').rglob('*.class'):
  jar.write(path,path.relative_to(work/'classes'))
PYJAR
"$ANDROID_BUILD_TOOLS/d8" --lib "$ANDROID_JAR" --min-api 26 --output "$WORK/dex" "$WORK/classes.jar"
python3 - "$WORK" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
work = Path(sys.argv[1])
with ZipFile(work/'app-unsigned.apk','a',ZIP_DEFLATED) as apk:
    for dex in (work/'dex').glob('*.dex'):
        apk.write(dex,dex.name)
PY
"$ANDROID_BUILD_TOOLS/zipalign" -p -f 4 "$WORK/app-unsigned.apk" "$WORK/app-aligned.apk"
# Standard Android development signing password; the private key remains outside Git.
"$ANDROID_BUILD_TOOLS/apksigner" sign --ks "$QUEST_KEYSTORE" --ks-key-alias harmony --ks-pass pass:android --key-pass pass:android --out "$ROOT/quest-android/dist/Harmony-VR.apk" "$WORK/app-aligned.apk"
"$ANDROID_BUILD_TOOLS/apksigner" verify --verbose "$ROOT/quest-android/dist/Harmony-VR.apk"
