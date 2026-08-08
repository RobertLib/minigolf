#!/usr/bin/env python3
"""Sync Localizable.xcstrings with the strings Xcode extracted from the build.

Xcode writes one <file>.stringsdata per compiled Swift file into the build
intermediates. This script reads them, adds every key that is missing from the
catalog together with its Czech translation, drops keys nothing references any
more, and keeps the file sorted the way Xcode writes it.

    xcodebuild ... -derivedDataPath <dd> build
    python3 Tools/sync_strings.py <dd>
"""
import glob
import json
import os
import sys

CATALOG = os.path.join(os.path.dirname(__file__), "..", "Minigolf", "Resources",
                       "Localizable.xcstrings")

# Czech for every key the app can show. Keys that read the same in both
# languages (numbers, proper names) are listed too, so nothing is left in the
# "needs translation" state.
CS = {
    # Worlds
    "Green Garden": "Zelená zahrada",
    "Desert Oasis": "Pouštní oáza",
    "Jungle Temple": "Chrám v džungli",
    "Frozen Fjord": "Zamrzlý fjord",
    "Neon Nights": "Neonové noci",
    "Volcano Forge": "Vulkanická výheň",
    "Clockwork Works": "Hodinový stroj",
    "Storm Coast": "Bouřlivé pobřeží",
    "Orbital Station": "Orbitální stanice",
    "A sunny classic among the trees": "Slunná klasika mezi stromy",
    "Hot sand and tricky dunes": "Horký písek a zrádné duny",
    "Swinging vines and ancient portals": "Houpavé liány a dávné portály",
    "Slick ice and drifting floes": "Klouzavý led a plující kry",
    "Glowing challenge after dark": "Zářivá výzva po setmění",
    "Lava, geysers and iron gates": "Láva, gejzíry a železné brány",
    "Brass gears, turntables and cannons": "Mosazná soukolí, otočné talíře a děla",
    "Gale winds and long jumps over the surf": "Vichr a dlouhé skoky přes příboj",
    "Loops, tractor beams and the void": "Loopingy, vlečné paprsky a prázdnota",
    # Difficulty
    "Beginner": "Začátečník",
    "Easy": "Snadné",
    "Medium": "Střední",
    "Hard": "Těžké",
    "Very hard": "Velmi těžké",
    "Expert": "Expert",
    "Master": "Mistr",
    "Brutal": "Brutální",
    "Legendary": "Legendární",
    # Garden holes
    "First Steps": "První kroky",
    "Slalom": "Slalom",
    "Dogleg Right": "Zatáčka vpravo",
    "Sand Trap": "Písečná past",
    "Over the Hill": "Přes kopec",
    "The Windmill": "Větrný mlýn",
    "King of the Hill": "Král kopce",
    "Garden Path": "Zahradní cestička",
    "The Pond": "Rybníček",
    "Sloping Lawn": "Šikmý trávník",
    "Hedge Tunnel": "Tunel v živém plotě",
    "Grand Garden": "Velká zahrada",
    # Desert holes
    "Warm Sands": "Teplé písky",
    "Canyon Turn": "Kaňonová zatáčka",
    "The Gatekeeper": "Strážce brány",
    "Bazaar Bumpers": "Bazarové odrazníky",
    "The Funnel": "Nálevka",
    "Rolling Dunes": "Vlnící se duny",
    "The Sweeper": "Zametač",
    "Mesa": "Mesa",
    "The Oasis": "Oáza",
    "Scarab Gates": "Skarabeovy brány",
    "Geyser Run": "Gejzírová dráha",
    "The Gauntlet": "Poslední zkouška",
    # Jungle holes
    "Temple Steps": "Schody k chrámu",
    "Muddy Banks": "Bahnité břehy",
    "Swinging Vines": "Houpavé liány",
    "Ancient Portal": "Dávný portál",
    "Jungle River": "Řeka v džungli",
    "Ruined Arch": "Zbořený oblouk",
    "Vine Bridge": "Liánový most",
    "Twin Portals": "Dvojice portálů",
    "Cascade": "Kaskáda",
    "Temple Guardian": "Strážce chrámu",
    "Portal Rapids": "Portálové proudy",
    "Lost City": "Ztracené město",
    # Ice holes
    "First Frost": "První mráz",
    "Slippery Slalom": "Klouzavý slalom",
    "Iceberg Alley": "Ulička krů",
    "The Crevasse": "Ledová trhlina",
    "Blue Drift": "Modrý smyk",
    "Frozen Gates": "Zmrzlé brány",
    "Snow Bank": "Sněhová závěj",
    "Glacier Ramp": "Rampa na ledovec",
    "Twin Floes": "Dvě kry",
    "Avalanche": "Lavina",
    "Frostbite Bank": "Mrazivý svah",
    "Northern Lights": "Polární záře",
    # Neon holes
    "Night Shift": "Noční směna",
    "Laser Corner": "Laserová zatáčka",
    "Pinball Palace": "Pinballový palác",
    "Night Sweeper": "Noční zametač",
    "Circuit Board": "Deska s obvody",
    "Turbo Mill": "Turbo mlýn",
    "Sky Platform": "Plošina v nebi",
    "The Void": "Prázdnota",
    "Twin Turbines": "Dvojité turbíny",
    "Warp Zone": "Zóna skoku",
    "Strobe Gates": "Stroboskopické brány",
    "Grand Finale": "Velké finále",
    # Volcano holes
    "Cinder Path": "Škvárová stezka",
    "Ash Field": "Popelové pole",
    "Geyser Gate": "Gejzírová brána",
    "Molten Rotor": "Žhavý rotor",
    "Iron Pistons": "Železné písty",
    "Lava Falls": "Lávové vodopády",
    "Wrecking Ball": "Demoliční koule",
    "Forge Ramp": "Rampa výhně",
    "Twin Geysers": "Dvojité gejzíry",
    "Magma Rapids": "Magmatické proudy",
    "The Crucible": "Tavicí kelímek",
    "Heart of the Volcano": "Srdce vulkánu",
    # Clockwork holes
    "First Cog": "První kolečko",
    "Brass Alley": "Mosazná ulička",
    "The Piston": "Píst",
    "Big Wheel": "Velké kolo",
    "Powder Keg": "Sud prachu",
    "Gear Train": "Převodovka",
    "The Escapement": "Krokový mechanismus",
    "Oil Bath": "Olejová lázeň",
    "Clock Tower": "Hodinová věž",
    "The Mainspring": "Hlavní pružina",
    "Double Barrel": "Dvojhlaveň",
    "The Great Machine": "Velký stroj",
    # Storm holes
    "Sea Breeze": "Mořský vánek",
    "Low Tide": "Odliv",
    "The Jetty": "Molo",
    "Crosswind": "Boční vítr",
    "Breakwater": "Vlnolam",
    "Gale Force": "Vichřice",
    "Skerry Hop": "Skok přes útesy",
    "Kelp Beds": "Chaluhové pole",
    "Squall Line": "Čára bouřek",
    "The Lighthouse": "Maják",
    "Storm Surge": "Bouřlivý příboj",
    "Cape Fury": "Mys zuřivosti",
    # Cosmos holes
    "Docking Bay": "Dokovací modul",
    "First Loop": "První looping",
    "Tractor Beam": "Vlečný paprsek",
    "Airlock": "Přechodová komora",
    "Repulsor": "Repulzor",
    "Centrifuge": "Centrifuga",
    "Mass Driver": "Hmotový urychlovač",
    "Zero-G Deck": "Paluba beztíže",
    "Asteroid Gap": "Asteroidová průrva",
    "Wormhole": "Červí díra",
    "Reactor Core": "Jádro reaktoru",
    "Event Horizon": "Horizont událostí",
    # Menus, HUD and overlays
    "Audio": "Zvuk",
    "Beat Your Score": "Překonej svůj rekord",
    "Best %lld (%@)": "Rekord %lld (%@)",
    "Best %lld · Par %lld · %@": "Rekord %lld · Par %lld · %@",
    "Choose Your Course": "Vyber si kurz",
    "Continue": "Pokračovat",
    "Course Complete!": "Kurz dokončen!",
    "Course Select": "Výběr kurzu",
    "Done": "Hotovo",
    "Drag anywhere on the course to aim, release to shoot. Finish every hole within the stroke limit!":
        "Tažením kdekoli po hřišti zamiř, puštěním odpal. Dokonči každou jamku v limitu úderů!",
    "Drag back to aim · release to shoot": "Táhni dozadu pro zamíření · pusť pro odpal",
    "Feedback": "Odezva",
    "Finish Course": "Dokončit kurz",
    "Finish the previous course to unlock": "Odemkneš dokončením předchozího kurzu",
    "Game Over": "Konec hry",
    "Got It!": "Jasně!",
    "Haptics": "Haptika",
    "Hole %lld": "Jamka %lld",
    "How to Play": "Jak hrát",
    "Main Menu": "Hlavní menu",
    "Music": "Hudba",
    "My Golf Rating": "Moje golfové hodnocení",
    "New personal best!": "Nový osobní rekord!",
    "Next Hole": "Další jamka",
    "Out of bounds! +1 stroke": "Mimo dráhu! +1 úder",
    "Par %lld": "Par %lld",
    "Paused": "Pauza",
    "Play": "Hrát",
    "Play Again": "Hrát znovu",
    "Quit Course": "Opustit kurz",
    "Restart Hole (−1 ❤️)": "Restart jamky (−1 ❤️)",
    "Resume": "Pokračovat",
    "See Your Rating": "Zobrazit hodnocení",
    "Settings": "Nastavení",
    "Sound Effects": "Zvukové efekty",
    "Splash! +1 stroke": "Žbluňk! +1 úder",
    "Stroke %lld/%lld": "Úder %lld/%lld",
    "Stroke limit reached! Try this hole again.":
        "Limit úderů vyčerpán! Zkus jamku znovu.",
    "Strokes %lld": "Údery: %lld",
    "Total %@": "Celkem %@",
    "Total %lld": "Celkem %lld",
    "Touch anywhere and drag away from your target — like pulling back a slingshot. The further you drag, the harder the shot. Release to putt!":
        "Dotkni se obrazovky a táhni směrem od cíle — jako když natahuješ prak. Čím dál táhneš, tím silnější rána. Puštěním odpálíš!",
    "Try Again": "Zkusit znovu",
    "Version": "Verze",
    "View Your Golf Rating": "Zobrazit golfové hodnocení",
    "You ran out of lives on hole %lld. Practice makes perfect — give it another shot!":
        "Na jamce %lld ti došly životy. Cvik dělá mistra — zkus to znovu!",
    "%lld holes · Par %lld": "%lld jamek · Par %lld",
    "%lld/%lld": "%lld/%lld",
    "%lld/%lld holes": "%lld/%lld jamek",
    "/%lld": "/%lld",
    "–": "–",
    "Back to Holes": "Zpět na jamky",
    "Bonus star collected!": "Bonusová hvězda získána!",
    "Burned up! +1 stroke": "Spáleno! +1 úder",
    "Hole List": "Seznam jamek",
    "Holes": "Jamky",
    "New best on this hole!": "Nový rekord na této jamce!",
    "Play Full Course": "Zahrát celý kurz",
    "Practice": "Trénink",
    "Practice This Hole": "Trénovat tuto jamku",
    "Practice a single hole as often as you like — no lives, no pressure.":
        "Trénuj jedinou jamku, jak dlouho chceš — bez životů a bez stresu.",
    "Reached hole %lld": "Nejdál jamka %lld",
    "Restart Hole": "Restartovat jamku",
    "%lld worlds. %lld holes. One champion.":
        "%1$lld světů. %2$lld jamek. Jeden šampion.",
    "You finished all %lld holes!": "Dokončil jsi všech %lld jamek!",
    # Settings
    "Gameplay": "Hratelnost",
    "Aim Guide": "Naváděcí čára",
    "Ball Trail": "Stopa míčku",
    "Off": "Vypnuto",
    "Short": "Krátká",
    "Full": "Plná",
    "Just the direction arrow.": "Jen šipka směru.",
    "A short line, no bank shots.": "Krátká čára bez odrazů.",
    "Full line with two bounces.": "Plná čára se dvěma odrazy.",
    # Daily challenge
    "Daily": "Denní",
    "Daily Challenge": "Denní výzva",
    "Play Today's Hole": "Zahrát dnešní jamku",
    "Back to Menu": "Zpět do menu",
    "Daily streak: %lld": "Denní série: %lld",
    "New hole in %lldh %lldm": "Nová jamka za %lld h %lld m",
    "New hole in %lldm": "Nová jamka za %lld m",
    "%@ · Hole %lld · Par %lld": "%@ · Jamka %lld · Par %lld",
    "Under par": "Pod par",
    "Par": "Par",
    # Clubhouse
    "Clubhouse": "Klubovna",
    "Career": "Kariéra",
    "Trophies": "Trofeje",
    "Trophy unlocked": "Trofej odemčena",
    "Your Ball": "Tvůj míček",
    "%lld/%lld trophies": "%lld/%lld trofejí",
    "Holes played": "Odehrané jamky",
    "Holes cleared": "Zvládnuté jamky",
    "Hole-in-ones": "Jamky na jednu",
    "Best par run": "Nejdelší série par",
    "Day streak": "Série dní",
    "Dailies done": "Denních výzev",
    "Stars": "Hvězdy",
    "Every ball is yours. Show off.": "Všechny míčky jsou tvoje. Chlub se.",
    "Next up — %@: %@": "Další na řadě — %@: %@",
    "New ball unlocked: %@": "Nový míček odemčen: %@",
    # Ball skins
    "Classic": "Klasika",
    "Tangerine": "Mandarinka",
    "Bubblegum": "Žvýkačka",
    "Emerald": "Smaragd",
    "Golden Ace": "Zlaté eso",
    "Chrome": "Chrom",
    "Glacier": "Ledovec",
    "Neon Pulse": "Neonový puls",
    "Magma": "Magma",
    "Sunburst": "Sluneční záře",
    "Legend": "Legenda",
    "Brass": "Mosaz",
    "Tempest": "Uragán",
    "Nebula": "Mlhovina",
    "Always yours": "Máš od začátku",
    "Finish 10 holes": "Dohraj 10 jamek",
    "Collect 5 bonus stars": "Posbírej 5 bonusových hvězd",
    "Earn 30 stars": "Získej 30 hvězd",
    "Score a hole-in-one": "Trefit jamku na jednu ránu",
    "Finish 2 worlds": "Dohraj 2 světy",
    "Finish the Frozen Fjord": "Dohraj Zamrzlý fjord",
    "Finish the Neon Nights": "Dohraj Neonové noci",
    "Finish the Volcano Forge": "Dohraj Vulkanickou výheň",
    "Finish the Clockwork Works": "Dokonči Hodinový stroj",
    "Finish the Storm Coast": "Dokonči Bouřlivé pobřeží",
    "Finish the Orbital Station": "Dokonči Orbitální stanici",
    "Reach a 7-day daily streak": "Dosáhni denní série 7 dní",
    "Finish all %lld holes": "Dohraj všech %lld jamek",
    # Ratings
    "HOLE-IN-ONE!": "HOLE-IN-ONE!",
    "EAGLE!": "EAGLE!",
    "BIRDIE!": "BIRDIE!",
    "PAR": "PAR",
    "BOGEY": "BOGEY",
    "DOUBLE BOGEY": "DOUBLE BOGEY",
    "Absolutely incredible!": "Naprosto neuvěřitelné!",
    "Outstanding shot!": "Vynikající rána!",
    "One under par — great job!": "Jedna pod par — skvělá práce!",
    "Right on target.": "Přesně podle plánu.",
    "Almost there.": "Skoro to vyšlo.",
    "That was a tough one.": "Tohle byla fuška.",
    "Better luck on the next hole.": "Na další jamce to vyjde.",
    "Golf Legend": "Golfová legenda",
    "The greens whisper your name. A flawless performance!":
        "Greeny šeptají tvé jméno. Bezchybný výkon!",
    "Master of the Greens": "Mistr greenů",
    "Precision, patience, perfection. Almost legendary!":
        "Přesnost, trpělivost, dokonalost. Téměř legendární!",
    "Pro Golfer": "Profesionální golfista",
    "Playing at or under par across every course. Impressive!":
        "Všechny kurzy zahrané na par nebo lépe. Působivé!",
    "Skilled Player": "Zkušený hráč",
    "A steady swing and a sharp eye. Keep it up!":
        "Jistý švih a přesné oko. Jen tak dál!",
    "Promising Talent": "Nadějný talent",
    "You have the touch — now polish it to a shine.":
        "Máš cit v ruce — teď ho vypiluj k dokonalosti.",
    "Weekend Golfer": "Víkendový golfista",
    "Every legend started somewhere. Another round?":
        "Každá legenda někde začínala. Ještě jedno kolo?",
    "+%lld OVER PAR": "+%lld NAD PAR",
    "Tee Off": "První odpal",
    # Achievements
    "Finish your first hole.": "Dohraj svou první jamku.",
    "Warmed Up": "Rozehřátý",
    "Finish 25 holes.": "Dohraj 25 jamek.",
    "Course Regular": "Stálý host",
    "Finish 150 holes.": "Dohraj 150 jamek.",
    "Ace!": "Eso!",
    "Sink a hole-in-one.": "Tref jamku na jednu ránu.",
    "Sharpshooter": "Ostrostřelec",
    "Sink 10 hole-in-ones.": "Tref 10 jamek na jednu ránu.",
    "Birdwatcher": "Pozorovatel ptáků",
    "Finish 25 holes under par.": "Dohraj 25 jamek pod par.",
    "In the Zone": "V ráži",
    "Play 8 holes in a row at or under par.":
        "Zahraj 8 jamek v řadě na par nebo lépe.",
    "Clean Round": "Čisté kolo",
    "Finish a world without a single penalty.":
        "Dohraj svět bez jediné penalizace.",
    "Under Par": "Pod par",
    "Finish a world 5 shots under par.": "Dohraj svět 5 úderů pod par.",
    "Star Collector": "Sběratel hvězd",
    "Earn 50 stars.": "Získej 50 hvězd.",
    "Perfectionist": "Perfekcionista",
    "Earn every star in the game.": "Získej všechny hvězdy ve hře.",
    "Treasure Hunter": "Lovec pokladů",
    "Collect 12 bonus stars.": "Posbírej 12 bonusových hvězd.",
    "Nothing Left Behind": "Nic nezůstalo",
    "Collect every bonus star.": "Posbírej všechny bonusové hvězdy.",
    "Every Green": "Každý green",
    "Finish all %lld holes at least once.":
        "Dohraj všech %lld jamek aspoň jednou.",
    "World Tour": "Cesta kolem světa",
    "Finish all %lld worlds.": "Dohraj všech %lld světů.",
    "Daily Habit": "Denní návyk",
    "Finish your first daily challenge.": "Dohraj svou první denní výzvu.",
    "Seven-Day Swing": "Sedm dní v kuse",
    "Keep a 7-day daily streak.": "Udrž denní sérii 7 dní.",
    "Month of Golf": "Měsíc golfu",
    "Keep a 30-day daily streak.": "Udrž denní sérii 30 dní.",
    # VoiceOver. Never shown on screen — these are what the icon-only buttons,
    # the star rows and the number chips say out loud, since read aloud a row
    # of stars is silence and "252/324" is a pair of numbers.
    "Pause": "Pauza",
    "Back to menu": "Zpět do menu",
    "Back to course select": "Zpět na výběr kurzu",
    "Shot power": "Síla úderu",
    "%lld percent": "%lld procent",
    "%@, hole %lld of %lld": "%@, jamka %lld z %lld",
    "Total %lld against par": "Celkem %lld proti paru",
    "Bonus star collected": "Bonusová hvězda sebrána",
    "Bonus star not collected yet": "Bonusová hvězda zatím nesebrána",
    # One music credit read as one row: title, author, licence. The author is
    # only written in the section header, which nobody swiping row by row ever
    # hears, so the row says it — an attribution without the name is not one.
    "%@ by %@, %@": "%@ od %@, %@",
    "Opens the track's page": "Otevře stránku skladby",
    "%lld of %lld lives left": "Zbývají životy: %lld ze %lld",
    "%lld out of %lld stars": "%lld z %lld hvězd",
    "%lld out of 3 stars": "%lld ze 3 hvězd",
    "%lld of %lld stars": "%lld z %lld hvězd",
    "%lld of %lld bonus stars": "%lld z %lld bonusových hvězd",
    "%lld of %lld": "%lld z %lld",
    "%lld strokes": "Úderů: %lld",
    "Hole %lld, par %lld": "Jamka %lld, par %lld",
    "Hole %lld, %@": "Jamka %lld, %@",
    "best %lld, par %lld": "rekord %lld, par %lld",
    "not played yet, par %lld": "zatím nehráno, par %lld",
    "bonus star collected": "bonusová hvězda sebrána",
    "bonus star still hidden": "bonusová hvězda je stále schovaná",
    "Locked": "Zamčeno",
    "Locked. %@": "Zamčeno. %@",
    "Unlocked": "Odemčeno",
    "Earned": "Získáno",
    "%@. %@": "%@. %@",
    "Clubhouse, %lld new balls": "Klubovna, nové míčky: %lld",
    "Play %@": "Hrát %@",
    "Holes in %@": "Jamky – %@",
    "Restart hole": "Restartovat jamku",
    "Restart hole, costs one life": "Restartovat jamku, stojí jeden život",
    "%lld day streak": "Denní série %lld",
    "Today's score %lld, %@": "Dnešní skóre %lld, %@",
    "Trophy unlocked: %@": "Odemčena trofej: %@",
}

# Keys that are pure symbols/format and carry no translatable text.
NO_TRANSLATION_NEEDED = {"%lld", "⛳️", "🏆", "😢", "%@", "%lld%%", "✓", "v1.1",
                         "MINIGOLF"}


def extracted_keys(derived_data):
    pattern = os.path.join(derived_data, "Build", "Intermediates.noindex",
                           "Minigolf.build", "*", "Minigolf.build",
                           "Objects-normal", "*", "*.stringsdata")
    files = glob.glob(pattern)
    if not files:
        sys.exit("no .stringsdata under %s — build the app first" % derived_data)
    keys = {}
    for path in files:
        with open(path) as handle:
            data = json.load(handle)
        for entries in data.get("tables", {}).values():
            for entry in entries:
                keys.setdefault(entry["key"], os.path.basename(data["source"]))
    return keys


def main():
    derived_data = sys.argv[1] if len(sys.argv) > 1 else "build"
    keys = extracted_keys(derived_data)

    with open(CATALOG) as handle:
        catalog = json.load(handle)
    strings = catalog["strings"]

    added, filled, dropped, untranslated = [], [], [], []

    for key in keys:
        if key not in strings:
            strings[key] = {}
            added.append(key)

        # Backfilled on every run rather than only on the run that adds the
        # key. A key extracted from a build before its translation was written
        # here lands in the catalog bare, and skipping anything already present
        # would leave it that way for good — which is exactly how a string ends
        # up shipping in English inside the Czech build.
        if "cs" in strings[key].get("localizations", {}):
            continue
        if key in CS:
            strings[key].setdefault("localizations", {})["cs"] = {
                "stringUnit": {"state": "translated", "value": CS[key]}
            }
            if key not in added:
                filled.append(key)
        elif key not in NO_TRANSLATION_NEEDED:
            untranslated.append(key)

    for key in list(strings):
        if key not in keys:
            del strings[key]
            dropped.append(key)

    catalog["strings"] = {key: strings[key] for key in sorted(strings)}
    with open(CATALOG, "w") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print("catalog: %d keys (+%d, -%d, %d translated)"
          % (len(strings), len(added), len(dropped), len(filled)))
    for key in sorted(dropped):
        print("  removed  %r" % key)
    for key in sorted(filled):
        print("  translated  %r" % key)
    if untranslated:
        print("\nMISSING CZECH (%d):" % len(untranslated))
        for key in sorted(untranslated):
            print("  %r" % key)
        sys.exit(1)


if __name__ == "__main__":
    main()
