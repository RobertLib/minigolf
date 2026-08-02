#!/bin/bash
#
# appstore_media.sh — regenerates every screenshot and App Preview in AppStore/.
#
#     Tools/appstore_media.sh                 # screenshots + previews
#     Tools/appstore_media.sh screenshots     # screenshots only
#     Tools/appstore_media.sh video           # previews only
#
# Needs Xcode, the two simulators named below and ImageMagick (`brew install
# imagemagick`) for the lossless PNG squeeze. Everything is driven by the DEBUG
# launch arguments in GameController/GameSceneCoordinator, so it builds Debug —
# the flags do nothing in a Release build.
#
# Output goes to AppStore/screenshots/<locale>/<device>/ and
# AppStore/preview/<locale>/<device>.mp4. Override the root with OUT_ROOT=…
# to try things out without touching the committed set.
#
set -euo pipefail

MODE="${1:-all}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_ROOT="${OUT_ROOT:-$ROOT/AppStore}"
WORK="${WORK:-$(mktemp -d -t minigolf-appstore)}"
BID=cz.rob.Minigolf

IPHONE_NAME="iPhone 17 Pro Max"   # 1320 × 2868 — App Store "iPhone 6.9""
IPAD_NAME="iPad Pro 13-inch (M5)" # 2064 × 2752 — App Store "iPad 13""

# App Preview render sizes. The iPhone recording is scaled down a touch and
# centre-cropped; the iPad is an exact 0.75 aspect match.
IPHONE_VIDEO_SIZE=(1290 2796)
IPAD_VIDEO_SIZE=(1200 1600)

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

udid_for() {
    # Device lines are indented four spaces and read "<name> (<udid>) (<state>)".
    # Matched as a fixed string, because names like "iPad Pro 13-inch (M5)"
    # carry brackets of their own; the trailing " (" keeps "iPhone 17" from
    # matching "iPhone 17 Pro Max".
    xcrun simctl list devices available \
        | grep -F "    $1 (" \
        | grep -oE '[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}' \
        | head -n 1 || true
}

boot_and_install() {
    local udid="$1"
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
    xcrun simctl install "$udid" "$APP"
    # The game hides the status bar, but pin it anyway so nothing stray shows.
    xcrun simctl status_bar "$udid" override --time "9:41" \
        --batteryState charged --batteryLevel 100 --wifiMode active --wifiBars 3 >/dev/null 2>&1 || true
}

locale_args() {
    case "$1" in
        cs)    printf '%s\0%s\0%s\0%s\0' -AppleLanguages "(cs)" -AppleLocale cs_CZ ;;
        en-US) printf '%s\0%s\0%s\0%s\0' -AppleLanguages "(en-US)" -AppleLocale en_US ;;
    esac
}

launch() { # launch <udid> <locale> <args...>
    local udid="$1" loc="$2"; shift 2
    local largs=()
    while IFS= read -r -d '' a; do largs+=("$a"); done < <(locale_args "$loc")
    xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BID" "${largs[@]}" "$@" >/dev/null
}

# ---------------------------------------------------------------- build

say "Building Debug for the simulator"
xcodebuild -project "$ROOT/Minigolf.xcodeproj" -scheme Minigolf \
    -configuration Debug -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=$IPHONE_NAME" \
    -derivedDataPath "$WORK/dd" build >/dev/null
APP="$WORK/dd/Build/Products/Debug-iphonesimulator/Minigolf.app"

IPHONE_UDID="$(udid_for "$IPHONE_NAME")"
IPAD_UDID="$(udid_for "$IPAD_NAME")"
[ -n "$IPHONE_UDID" ] || { echo "no simulator named '$IPHONE_NAME'"; exit 1; }
[ -n "$IPAD_UDID" ]   || { echo "no simulator named '$IPAD_NAME'"; exit 1; }

# ---------------------------------------------------------------- screenshots

# name|launch arguments. Zoom is picked per hole so the whole layout fits:
# -zoom multiplies the level's own cameraZoom.
SHOTS=(
    "01-aim|-autostart garden 6 -aimdemo 0.7 -zoom 1.8"
    "02-neon|-autostart neon 12 -aimdemo 0.6 -zoom 1.35"
    "03-worlds|-courseselect -unlockall"
    "04-volcano|-autostart volcano 10 -aimdemo 0.55 -zoom 1.3"
    "05-cosmos|-autostart cosmos 6 -aimdemo 0.6 -zoom 1.35"
    "06-rating|-finalrating -unlockall"
    "07-clubhouse|-clubhouse -unlockall"
    "08-daily|-daily -aimdemo 0.6 -zoom 1.5"
)

shoot() { # shoot <udid> <locale> <device-dir> <settle>
    local udid="$1" loc="$2" dev="$3" settle="$4"
    local dir="$OUT_ROOT/screenshots/$loc/$dev"
    mkdir -p "$dir"
    for entry in "${SHOTS[@]}"; do
        local name="${entry%%|*}" args="${entry#*|}"
        # shellcheck disable=SC2086
        launch "$udid" "$loc" $args
        sleep "$settle"
        xcrun simctl io "$udid" screenshot "$dir/$name.png" >/dev/null 2>&1
        printf '  %-14s %s\n' "$name" \
            "$(sips -g pixelWidth -g pixelHeight "$dir/$name.png" | awk '/pixel/{printf "%s ", $2}')"
    done
    xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
}

if [ "$MODE" = all ] || [ "$MODE" = screenshots ]; then
    boot_and_install "$IPHONE_UDID"
    boot_and_install "$IPAD_UDID"
    for loc in cs en-US; do
        say "Screenshots — iPhone 6.9\" / $loc"
        shoot "$IPHONE_UDID" "$loc" iphone-6.9 7
        say "Screenshots — iPad 13\" / $loc"
        shoot "$IPAD_UDID" "$loc" ipad-13 8
    done

    if command -v magick >/dev/null; then
        # The simulator writes RGBA even though every pixel is opaque, and
        # App Store Connect wants screenshots without transparency. Dropping
        # the channel leaves the picture untouched and saves a third of the size.
        say "Squeezing PNGs (lossless — anything that differs is left alone)"
        while IFS= read -r f; do
            magick "$f" -alpha off -depth 8 -strip \
                        -define png:compression-level=9 \
                        -define png:compression-filter=5 "$f.opt"
            if [ "$(magick compare -metric AE "$f" "$f.opt" null: 2>&1 | awk '{print $1}')" = "0" ]; then
                mv "$f.opt" "$f"
            else
                rm -f "$f.opt"
                echo "  left as-is (not identical): $f"
            fi
        done < <(find "$OUT_ROOT/screenshots" -name '*.png')
        du -sh "$OUT_ROOT/screenshots"
    else
        echo "  (no ImageMagick — skipping the PNG squeeze)"
    fi
fi

# ---------------------------------------------------------------- previews

# name|pre-roll|seconds|launch arguments. The pre-roll skips the intro flyover
# so the clip opens on a shot, not on a camera move.
CLIPS=(
    "r1-garden|PREROLL|13|-autostart garden 1 -autoshot -autoadvance -zoom 1.4"
    "r2-neon|PREROLL|13|-autostart neon 3 -autoshot -autoadvance -zoom 1.45"
    "r3-volcano|PREROLL|13|-autostart volcano 10 -autoshot -autoadvance -zoom 1.3"
    "r4-cosmos|PREROLL|13|-autostart cosmos 6 -autoshot -autoadvance -zoom 1.35"
    "r5-ice|PREROLL|13|-autostart ice 10 -autoshot -autoadvance -zoom 1.3"
    "r6-rating|RATING_PREROLL|7|-finalrating -unlockall"
)

# The autoplay is deterministic, but the iPad reaches each hole at a slightly
# different moment, so the two devices get their own cut points.
IPHONE_CUTS=(r1-garden:0.2:6.4 r2-neon:4.0:8.2 r5-ice:4.6:10.2
             r3-volcano:2.5:6.5 r4-cosmos:0.8:4.8 r6-rating:0.8:3.3)
IPAD_CUTS=(r1-garden:0.2:5.8 r2-neon:4.0:8.2 r5-ice:6.0:11.8
           r3-volcano:2.5:7.0 r4-cosmos:0.8:4.8 r6-rating:0.8:3.3)

record() { # record <udid> <locale> <clipdir> <preroll> <rating-preroll>
    local udid="$1" loc="$2" dir="$3" preroll="$4" rating="$5"
    mkdir -p "$dir"
    for entry in "${CLIPS[@]}"; do
        IFS='|' read -r name pre secs args <<<"$entry"
        case "$pre" in PREROLL) pre="$preroll";; RATING_PREROLL) pre="$rating";; esac
        # shellcheck disable=SC2086
        launch "$udid" "$loc" $args
        sleep "$pre"
        xcrun simctl io "$udid" recordVideo --codec h264 --force "$dir/$name.mp4" >/dev/null 2>&1 &
        local pid=$!
        sleep "$secs"
        kill -INT $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
        sleep 1
        printf '  %-12s %s\n' "$name" "$(avmediainfo "$dir/$name.mp4" | awk '/^Duration:/{print $2 "s"}')"
    done
    xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
}

assemble() { # assemble <clipdir> <out.mp4> <W> <H> <cut...>
    local dir="$1" out="$2" w="$3" h="$4"; shift 4
    mkdir -p "$(dirname "$out")"
    local specs=()
    for cut in "$@"; do specs+=("$dir/${cut%%:*}.mp4:${cut#*:}"); done
    swift "$ROOT/Tools/appstore_video.swift" "$out" "$w" "$h" "${specs[@]}"
}

if [ "$MODE" = all ] || [ "$MODE" = video ]; then
    boot_and_install "$IPHONE_UDID"
    boot_and_install "$IPAD_UDID"
    for loc in cs en-US; do
        say "Preview — iPhone 6.9\" / $loc"
        record "$IPHONE_UDID" "$loc" "$WORK/clips/iphone-$loc" 4.5 4.0
        assemble "$WORK/clips/iphone-$loc" "$OUT_ROOT/preview/$loc/iphone-6.9.mp4" \
            "${IPHONE_VIDEO_SIZE[@]}" "${IPHONE_CUTS[@]}"

        say "Preview — iPad 13\" / $loc"
        record "$IPAD_UDID" "$loc" "$WORK/clips/ipad-$loc" 5.0 4.5
        assemble "$WORK/clips/ipad-$loc" "$OUT_ROOT/preview/$loc/ipad-13.mp4" \
            "${IPAD_VIDEO_SIZE[@]}" "${IPAD_CUTS[@]}"
    done
fi

say "Done. Working files in $WORK"
