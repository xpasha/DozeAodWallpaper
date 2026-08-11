#!/system/bin/sh
MODDIR=${0%/*}

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

BRIGHTNESS=$(grep -E '^brightness=' "$MODDIR/config.ini" 2>/dev/null | cut -d= -f2)
[ -z "$BRIGHTNESS" ] && BRIGHTNESS=40
[ "$BRIGHTNESS" -lt 1 ] && BRIGHTNESS=1
[ "$BRIGHTNESS" -gt 100 ] && BRIGHTNESS=100

b1=$BRIGHTNESS
b2=$((BRIGHTNESS * 2)); [ "$b2" -gt 255 ] && b2=255
b3=$((BRIGHTNESS * 3)); [ "$b3" -gt 255 ] && b3=255
b4=$((BRIGHTNESS * 4)); [ "$b4" -gt 255 ] && b4=255

AOD="screen_brightness_array=-1:$b1:$b2:$b3:$b4,dimming_scrim_array=-1:0:0:0:0,wallpaper_dimming_scrim_array=-1:0:0:0:0"

CHANGED=0
if [ "$(settings get global always_on_display_constants)" != "$AOD" ]; then
    settings put global always_on_display_constants "$AOD"
    CHANGED=1
fi
if [ "$(settings get secure doze_always_on_wallpaper_enabled)" != "1" ]; then
    settings put secure doze_always_on_wallpaper_enabled 1
    CHANGED=1
fi
if [ "$(settings get secure doze_always_on)" != "1" ]; then
    settings put secure doze_always_on 1
    CHANGED=1
fi

if [ "$CHANGED" = "1" ]; then
    sleep 3
    killall com.android.systemui
fi
