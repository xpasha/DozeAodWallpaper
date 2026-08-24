# Session context / handoff notes

Everything a fresh session needs to continue this project that is **not** in the
README. Updated 2026-08-24.

## v2.1 (2026-08-24): clean uninstall

v2.0 had a bug: settings keys written by apply.sh/service.sh were NOT reverted
on module removal (Settings provider lives in /data/system, Magisk doesn't touch
it). A public user reported AOD wallpaper persisting after uninstall. Fixed by
adding `uninstall.sh` (runs on module removal, `settings delete` on all three
keys + killall systemui). Users coming from v2.0 must revert manually or
install+remove v2.1. Manual rollback is documented in README ("Uninstalling").

## Target device & environment

- **Device:** Google Pixel 8 Pro (husky)
- **Android:** 17, SDK 37, stock Pixel firmware
- **Root:** `su` works from adb shell
- **Magisk Alpha** `30700` (`e8a58776-alpha`) — app package is
  `io.github.vvb2060.magisk` (NOT `com.topjohnwu.magisk`).
  Magisk Alpha has **no built-in WebUI**; it supports the **Action button**
  (`item_module_md2.xml`, "module_action") which runs `sh ./action.sh` in the
  module directory. Confirmed by decompiling the app APK.
- **KSUWebUIStandalone** is installed: package
  `io.github.a13e300.ksuwebui`. Launch a module's WebUI with:
  ```
  am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "doze_aod_wallpaper"
  ```
  It loads `/data/adb/modules/<id>/webroot/index.html`. The JS bridge uses
  `ksu.exec()` (root shell) and `ksu.toast()`. Reference integration:
  `/data/adb/modules/playintegrityfix/action.sh` on the device.
- GitHub: `gh` CLI authorized as **xpasha**. When committing, git identity must
  be passed explicitly:
  ```
  git -c user.name="xpasha" -c user.email="xpasha@users.noreply.github.com" commit ...
  ```

## How the module works (reverse-engineered)

AOD wallpaper is the **real wallpaper window** owned by `WallpaperManagerService`
in system_server. SystemUI only notifies it:
- `DozeWallpaperState.transitionTo()` → `IWallpaperManager.setInAmbientMode(bool, ms)`
  (`com/android/systemui/doze/DozeWallpaperState.java`).

Feature gate / resources (both live in **framework-res**, target `android`):
- `config_dozeSupportsAodWallpaper` (bool) — `false` by default on Pixel; the RRO flips it to `true`.
- `config_screenBrightnessDoze` (integer) — `1` by default (barely visible); RRO sets `60`.
  Read chain in SystemUI: `WallpaperRepositoryImpl$...$map$1.java` checks
  `Settings.Secure.doze_always_on` + `doze_always_on_wallpaper_enabled`, then
  `R.integer.config_dozeSupportsAodWallpaperOverride` (0=auto→framework bool).

Settings keys:
- `Settings.Secure.doze_always_on_wallpaper_enabled` (secure, =1)
- `Settings.Secure.doze_always_on` (secure, =1, forces AOD on)
- `Settings.Global.always_on_display_constants` — parsed by
  `AlwaysOnDisplayPolicy.java` into `screen_brightness_array`,
  `dimming_scrim_array`, `wallpaper_dimming_scrim_array`.

**Critical:** the brightness array is only re-read by SystemUI at startup. After
writing settings you must `killall com.android.systemui` for it to take effect.
This is the only way to apply without reboot.

## Build pipeline for the static RRO

Sources in `build/` (`res/values/values.xml`, `AndroidManifest.xml`). Full
reproducible build with SDK 37 build-tools:

```bash
SDK=/Users/pavel/Library/Android/sdk
BT=$SDK/build-tools/37.0.0
JAVA=/opt/homebrew/opt/openjdk@17/bin/java
ANDROID_JAR=$SDK/platforms/android-35/android.jar   # newest platform present; fine for -I

# 1. compile resources
$BT/aapt2 compile --dir res -o compiled.zip
# 2. link into apk (no code, no signing config)
$BT/aapt2 link -o DozeAodWallpaper.apk -I "$ANDROID_JAR" \
    --manifest AndroidManifest.xml compiled.zip
# 3. sign with a debug keystore (RROs are not signature-verified against target)
#    actual keystore used for v2.0 lives in the project temp dir:
#    /var/folders/n0/pq2y497506d61fp41fv62vw80000gn/T/opencode/debug.keystore
KEYSTORE=/var/folders/n0/pq2y497506d61fp41fv62vw80000gn/T/opencode/debug.keystore
$BT/apksigner sign --ks "$KEYSTORE" \
    --ks-key-alias androiddebugkey --ks-pass pass:android \
    --key-pass pass:android --in DozeAodWallpaper.apk --out DozeAodWallpaper.apk
```

Verify signing: `$BT/apksigner verify --print-certs DozeAodWallpaper.apk`
(expect `CN=Android Debug, O=Android, C=US`).

Notes:
- Keytool is `/usr/bin/keytool`; java 17 is at `/opt/homebrew/opt/openjdk@17/bin`
  (must be on PATH for apksigner, e.g. `export PATH=/opt/homebrew/opt/openjdk@17/bin:$PATH`).
- If the debug keystore is gone, regenerate it with:
  `keytool -genkeypair -v -keystore debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -storepass android -dname "CN=Android Debug,O=Android,C=US"`
- The overlay manifest: `package="com.android.systemui.dozeaod.overlay"`,
  `<overlay android:targetPackage="android" android:isStatic="true" android:priority="100"/>`.
- apk is installed via the Magisk module at `system/product/overlay/DozeAodWallpaper.apk`.

## Testing on device

```bash
adb push AOD-Wallpaper-Module-v2.0.zip /sdcard/Download/
# install via Magisk app → Modules → Install from storage → reboot
# verify:
adb shell cmd overlay list --user 0 | grep doze   # [x] com.android.systemui.dozeaod.overlay
adb shell settings get global always_on_display_constants
adb shell dumpsys window | grep -iE 'dozeScreenState|policy'  # DOZE state on AOD
```

Device is connected via USB adb; if `adb devices` shows none, re-enable USB
debugging / re-plug.

## Compatibility notes (for 4PDA post)

- Android **13+** for wallpaper-on-AOD (feature added in 13). On 12- the module
  still raises brightness but wallpaper won't show.
- **Pixel / stock-Pixel ROMs only** for the wallpaper feature; brightness works
  more broadly. OLED + AOD required (LCD: pointless).
- Works on Magisk (any recent, incl. Alpha) and KernelSU.
- Tested: Pixel 8 Pro, Android 17, Magisk Alpha 30700.

## Blur research (DEFERRED — do not restart without asking)

User asked how hard adjustable blur on AOD is. Findings so far:
- AOD wallpaper is a separate wallpaper window (system_server) — SystemUI local
  blur (`Modifier.blur` in `CommunalContainerKt`) only blurs scene content, NOT
  the wallpaper.
- Shade blur uses cross-window SurfaceFlinger blur: `BlurUtils.applyBlur()` →
  `SurfaceParams.withBackgroundBlurRadius()` on the SystemUI root window
  (`WindowRootViewBinder`, `WindowRootViewBlurInteractor`), applied only when
  shade/bouncer is open.
- To blur AOD wallpaper you'd need cross-window blur on the SystemUI root in
  DOZE state → requires modifying SystemUI **Java logic** (impossible via RRO;
  repackaging SystemUI.apk impossible — platform-signed).
- Only realistic route: **LSPosed/Zygisk hook** on `BlurUtils`/`WindowRootViewBinder`.
  Risky: doze renders in low-power/frozen mode; blur may not apply or may drain
  battery. Decision: deferred by user.

## Local artifacts (may be deleted — temp dir)

Decompiled framework/SystemUI and screenshots live in
`/var/folders/n0/pq2y497506d61fp41fv62vw80000gn/T/opencode/aod/`
(`apk_framework/`, `out_sysui_full/sources/...`, `webui.png`, `aod_*.png`).
Not in the repo; re-decompile from the device if needed.
