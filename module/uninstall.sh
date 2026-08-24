#!/system/bin/sh
# Restore stock AOD behavior when the module is removed.
#
# apply.sh and service.sh write these keys directly into /data/system
# (Settings provider). Removing the module folder does NOT revert them:
#   secure doze_always_on_wallpaper_enabled=1
#   secure doze_always_on=1
#   global always_on_display_constants=screen_brightness_array=...
# This script is run by Magisk/KernelSU during module uninstall,
# BEFORE the module directory is deleted.

settings delete secure doze_always_on_wallpaper_enabled
settings delete secure doze_always_on
settings delete global always_on_display_constants

killall com.android.systemui 2>/dev/null

echo "AOD wallpaper disabled, settings restored to stock."
echo "If Always-On Display got disabled, re-enable it in Settings > Display > Lock screen."
