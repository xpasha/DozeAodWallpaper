<div align="center">

# 🌙 Doze AOD Wallpaper

**Always-On Display with your wallpaper — on Pixel 8 Pro (Android 17)**

Magisk module that unlocks AOD wallpaper, boosts its brightness,
and lets you fine-tune it right from your phone.

<br>

![Magisk](https://img.shields.io/badge/Magisk-25%2B-brightgreen?logo=magisk)
![Android](https://img.shields.io/badge/Android-17-3ddc84?logo=android)
![Pixel](https://img.shields.io/badge/Pixel-8%20Pro-4285f4?logo=google)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## ✨ What it does

Google ships the Pixel with **AOD wallpaper disabled** — the feature gate
`config_dozeSupportsAodWallpaper` is hardcoded to `false`. This module flips
it back on and fixes the brightness that Google left at a barely-visible level.

| | Before | After |
|---|---|---|
| Wallpaper on AOD | ❌ off | ✅ on |
| AOD brightness | ~1/255 (invisible) | **adjustable 5–100** |

## 🚀 Features

- **🖼️ Wallpaper on Always-On Display** — your lockscreen wallpaper now shows on AOD
- **🎚️ Live brightness control** — uniform scaling of the AOD brightness array (`-1:V:2V:3V:4V`)
- **🎛️ WebUI** — full page with slider + presets, powered by [KSUWebUI](https://github.com/5ec1cff/KSUWebUIStandalone)
- **⚡ Action button** — one tap on the module card in Magisk opens the WebUI
- **🔄 Smart fallback** — no KSUWebUI installed? The Action button cycles presets `Low → Medium → High`
- **♻️ Survives factory reset** — re-applies everything on boot via `service.sh`

## 🎯 Presets

| Preset | Array | ~Brightness |
|--------|-------|-------------|
| 🟢 Low | `-1:15:30:45:60` | up to ~24% |
| 🟡 Medium | `-1:40:80:120:160` | up to ~63% |
| 🔴 High | `-1:80:160:240:255` | up to 100% |

## 📦 Installation

1. Download [`AOD-Wallpaper-Module-v2.0.zip`](AOD-Wallpaper-Module-v2.0.zip)
2. Install it in **Magisk** → Modules → Install from storage
3. **Reboot**
4. Lock your screen and enjoy the wallpaper on AOD ✨

### ⚙️ Adjusting brightness (2 ways)

**Recommended — WebUI:**
1. Make sure [KSUWebUI](https://github.com/5ec1cff/KSUWebUIStandalone) is installed
2. Open **Magisk → Doze AOD Wallpaper → Action** (⚙️ button on the module card)
3. Move the slider or tap a preset — brightness applies instantly

**No KSUWebUI — tap-to-cycle:**
- Tap the **Action** button on the module card to cycle `Low → Medium → High`
- Current level is shown in the module description

## 🛠️ Compatibility

- **Tested on:** Pixel 8 Pro (husky), Android 17 / SDK 37, Magisk Alpha
- **Should work on:** other Pixel devices where the resource gate exists

> ⚠️ **OLED burn-in warning:** AOD wallpaper keeps the whole screen lit.
> Keep brightness moderate — this is why Google ships the feature off.

## 🧩 How it works

The module ships a **static RRO** (`DozeAodWallpaper.apk`) placed in
`/product/overlay` that overrides two framework-res resources:

| Resource | Override |
|----------|----------|
| `config_dozeSupportsAodWallpaper` | `true` |
| `config_screenBrightnessDoze` | `60` |

On boot, `service.sh` restores the persisted brightness array into
`Settings.Global.always_on_display_constants`. The WebUI writes
`config.ini` and calls `apply.sh`, which updates the setting and restarts
SystemUI — the only way to make the brightness array take effect.

## 📂 Module structure

```
module/
├── module.prop           # module metadata (shows current brightness)
├── action.sh             # Action button → WebUI / preset cycle fallback
├── apply.sh              # applies config.ini → settings + restart SystemUI
├── service.sh            # restores settings on every boot
├── config.ini            # persisted brightness level (0–100)
├── webroot/              # KSUWebUI page (slider + presets)
│   ├── index.html
│   └── assets/app.js
└── system/product/overlay/
    └── DozeAodWallpaper.apk   # static RRO for framework-res
```

## 🏗️ Building the overlay

The static RRO is built with `aapt2` from the Android SDK:

```bash
aapt2 compile --dir res -o compiled.zip
aapt2 link -o DozeAodWallpaper.apk \
    -I android.jar \
    --manifest AndroidManifest.xml \
    compiled.zip
```

Sources live in [`build/`](build/).

## 📄 License

MIT

---

<div align="center">

Made with 💙 for Pixel owners who miss their wallpaper

</div>
