#!/system/bin/sh
MODDIR=${0%/*}

pm path io.github.a13e300.ksuwebui > /dev/null 2>&1 && {
    echo "- Launching WebUI in KSUWebUIStandalone..."
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "doze_aod_wallpaper"
    exit 0
}

BRIGHTNESS=$(grep -E '^brightness=' "$MODDIR/config.ini" 2>/dev/null | cut -d= -f2)
[ -z "$BRIGHTNESS" ] && BRIGHTNESS=40

if [ "$BRIGHTNESS" -lt 30 ]; then
    NEXT=40
    NAME="Medium"
elif [ "$BRIGHTNESS" -lt 70 ]; then
    NEXT=80
    NAME="High"
else
    NEXT=15
    NAME="Low"
fi

sed -i "s/^brightness=.*/brightness=$NEXT/" "$MODDIR/config.ini"
sh "$MODDIR/apply.sh"
echo "Doze AOD brightness set to: $NAME ($NEXT)"
