#!/system/bin/sh
MODDIR=${0%/*}
CONFIG="$MODDIR/config.ini"

BRIGHTNESS=$(grep -E '^brightness=' "$CONFIG" 2>/dev/null | cut -d= -f2)
[ -z "$BRIGHTNESS" ] && BRIGHTNESS=40
[ "$BRIGHTNESS" -lt 1 ] && BRIGHTNESS=1
[ "$BRIGHTNESS" -gt 100 ] && BRIGHTNESS=100

b1=$BRIGHTNESS
b2=$((BRIGHTNESS * 2)); [ "$b2" -gt 255 ] && b2=255
b3=$((BRIGHTNESS * 3)); [ "$b3" -gt 255 ] && b3=255
b4=$((BRIGHTNESS * 4)); [ "$b4" -gt 255 ] && b4=255

AOD="screen_brightness_array=-1:$b1:$b2:$b3:$b4,dimming_scrim_array=-1:0:0:0:0,wallpaper_dimming_scrim_array=-1:0:0:0:0"

settings put global always_on_display_constants "$AOD"
settings put secure doze_always_on_wallpaper_enabled 1
settings put secure doze_always_on 1

sed -i "s/^description=.*/description=Enable wallpaper on AOD. Brightness: $BRIGHTNESS (set via Action\/WebUI). Framework: AOD wallpaper + doze brightness./" "$MODDIR/module.prop"

killall com.android.systemui
