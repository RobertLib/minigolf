#!/bin/bash
#
# appstore_captions.sh — vypálí popisky do hotových screenshotů.
#
#     Tools/appstore_captions.sh
#
# Čte AppStore/screenshots/<jazyk>/<zařízení>/NN-*.png a zapisuje stejně
# pojmenované soubory do AppStore/screenshots-captioned/. Původní sada zůstává
# nedotčená — nahraj do App Store Connect jednu, nebo druhou.
#
# Layout: pruh s textem nahoře, pod ním zmenšený screenshot na tmavě zeleném
# pozadí. Screenshot se nikde neořezává, jen zmenšuje, takže HUD ani ukazatel
# síly o nic nepřijdou.
#
# Potřebuje ImageMagick (`brew install imagemagick`).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="${SRC_ROOT:-$ROOT/AppStore/screenshots}"
OUT_ROOT="${OUT_ROOT:-$ROOT/AppStore/screenshots-captioned}"

# ImageMagick tady nemá zaregistrované žádné fonty, musí se dát cesta k souboru.
# Arial Bold je jediný tučný řez v systému, který má kompletní českou diakritiku
# (Arial Rounded Bold nemá ť ani ě, SF se přes IM vykreslí jen v regular).
FONT="${FONT:-/System/Library/Fonts/Supplemental/Arial Bold.ttf}"

BG_TOP='#123d2b'      # tmavší varianta zelené z hlavního menu
BG_BOTTOM='#061410'

# Popisky podle AppStore/screenshots.md. Číslo odpovídá prefixu souboru.
# Kde se text nevejde na řádek, je zalomení napsané ručně — automatické by
# nechalo na druhém řádku viset jediné slovo.
cs_caption() {
    case "$1" in
        01) echo "Táhni, pusť, trefa." ;;
        02) echo "9 světů, 108 jamek" ;;
        03) echo "Od zahrady po orbit" ;;
        04) echo "Láva, led, vítr i magnety" ;;
        05) echo "Loopingy a děla" ;;
        06) echo "Par, Birdie, Eagle…"$'\n'"nebo Bogey" ;;
        07) echo "14 míčků, 18 trofejí" ;;
        08) echo "Nová jamka každý den" ;;
    esac
}

en_caption() {
    case "$1" in
        01) echo "Drag, release, sink it." ;;
        02) echo "9 worlds, 108 holes" ;;
        03) echo "From garden to orbit" ;;
        04) echo "Lava, ice, wind"$'\n'"and magnets" ;;
        05) echo "Loops and cannons" ;;
        06) echo "Par, Birdie, Eagle…"$'\n'"or Bogey" ;;
        07) echo "14 balls, 18 trophies" ;;
        08) echo "A new hole every day" ;;
    esac
}

# Rozměry na zařízení: plátno, výška textového pruhu, šířka textového bloku,
# velikost písma. Screenshot se dopočítá tak, aby vyplnil zbytek pod pruhem.
geometry_for() {
    case "$1" in
        iphone-6.9) echo "1320 2868 480 1150 96" ;;
        ipad-13)    echo "2064 2752 450 1760 132" ;;
        *)          echo "" ;;
    esac
}

[ -f "$FONT" ] || { echo "font not found: $FONT"; exit 1; }
command -v magick >/dev/null || { echo "needs ImageMagick (brew install imagemagick)"; exit 1; }

for locale_dir in "$SRC_ROOT"/*; do
    [ -d "$locale_dir" ] || continue
    locale="$(basename "$locale_dir")"
    for device_dir in "$locale_dir"/*; do
        [ -d "$device_dir" ] || continue
        device="$(basename "$device_dir")"

        read -r W H BAND BOX PT <<<"$(geometry_for "$device")"
        [ -n "${W:-}" ] || { echo "  skipping unknown device: $device"; continue; }

        # Karta se screenshotem: 3px rámeček plus měkký stín, 22px nad spodní
        # hranou. Zbytek výšky nad ní patří textu.
        margin=22
        border=3
        card_h=$(( H - BAND - margin ))
        card_w=$(( W * card_h / H ))
        band_h=$(( H - card_h - margin - 2 * border ))

        out="$OUT_ROOT/$locale/$device"
        mkdir -p "$out"
        printf '\n\033[1m%s / %s\033[0m  (karta %dx%d, pruh %d)\n' "$locale" "$device" "$card_w" "$card_h" "$band_h"

        for src in "$device_dir"/*.png; do
            name="$(basename "$src")"
            num="${name%%-*}"
            case "$locale" in
                cs) caption="$(cs_caption "$num")" ;;
                *)  caption="$(en_caption "$num")" ;;
            esac
            [ -n "$caption" ] || { echo "  no caption for $name — skipped"; continue; }

            magick -size "${W}x${H}" gradient:"$BG_TOP-$BG_BOTTOM" \
                \( "$src" -resize "${card_w}x${card_h}" \
                   -bordercolor '#ffffff28' -border "$border" \
                   \( +clone -background black -shadow 55x28+0+10 \) \
                   +swap -background none -layers merge +repage \) \
                -gravity south -geometry "+0+$margin" -composite \
                \( -size "${BOX}x" -background none -fill white -font "$FONT" \
                   -pointsize "$PT" -gravity center caption:"$caption" \
                   -gravity center -extent "${W}x${band_h}" \) \
                -gravity north -geometry +0+0 -composite \
                -alpha off -depth 8 \
                "$out/$name"
            printf '  %-16s %s\n' "$name" "$caption"
        done
    done
done

printf '\n\033[1mBezztrátová rekomprese\033[0m\n'
while IFS= read -r f; do
    magick "$f" -strip -define png:compression-level=9 \
                -define png:compression-filter=5 "$f.opt"
    if [ "$(magick compare -metric AE "$f" "$f.opt" null: 2>&1 | awk '{print $1}')" = "0" ]; then
        mv "$f.opt" "$f"
    else
        rm -f "$f.opt"
        echo "  ponecháno beze změny (nevyšlo shodně): $f"
    fi
done < <(find "$OUT_ROOT" -name '*.png')

printf '\n\033[1mHotovo:\033[0m %s\n' "$OUT_ROOT"
du -sh "$OUT_ROOT"
