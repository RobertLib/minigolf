# Screenshoty a App Preview

Média se **negenerují ručně a nejsou v gitu** — vyrobí je skripty níž. Nahrávání
je pak ruční: v App Store Connect je vytáhni myší do sekce *App Preview and
Screenshots* (přepínač jazyka nahoře, každá lokalizace zvlášť).

## Co skripty vyrobí

| Co | Kam | Rozlišení | Kusů |
|---|---|---|---|
| Screenshoty iPhone 6.9" | `screenshots/<jazyk>/iphone-6.9/` | 1320 × 2868 | 8 |
| Screenshoty iPad 13" | `screenshots/<jazyk>/ipad-13/` | 2064 × 2752 | 8 |
| Totéž s popisky | `screenshots-captioned/<jazyk>/<zařízení>/` | stejné | 8 + 8 |
| App Preview iPhone 6.9" | `preview/<jazyk>/iphone-6.9.mp4` | 1290 × 2796, 30 fps, 26,5 s | 1 |
| App Preview iPad 13" | `preview/<jazyk>/ipad-13.mp4` | 1200 × 1600, 30 fps, 26,6 s | 1 |

Dohromady 85 MB screenshotů, 78 MB varianty s popisky a 134 MB videí.

```bash
Tools/appstore_media.sh              # screenshoty i videa (~20 min)
Tools/appstore_media.sh screenshots  # jen screenshoty (~8 min)
Tools/appstore_media.sh video        # jen videa (~12 min)
Tools/appstore_captions.sh           # dorazí popisky do hotových screenshotů (~2 min)
```

Jazyky jsou `cs` a `en-US`, všechno v portrétu. **Nahraj buď sadu s popisky, nebo
bez nich** — obě mají stejná jména souborů i pořadí, liší se jen tím pruhem
nahoře. Popisky nejsou povinné, ale zvedají konverzi.

Screenshoty jsou 8bitové PNG bez alfa kanálu (simulátor ho zapisuje, i když je
celý neprůhledný, a App Store Connect průhlednost nechce) a prošly bezztrátovou
rekompresí — ověřeno `magick compare -metric AE` = 0.

`appstore_media.sh` potřebuje Xcode, simulátory *iPhone 17 Pro Max* a
*iPad Pro 13-inch (M5)* a ImageMagick (`brew install imagemagick`). Staví Debug —
všechny přepínače níže jsou pod `#if DEBUG` a do App Store buildu se nedostanou.
`appstore_captions.sh` jen přemaluje už hotové PNG, simulátor nepotřebuje.

### Proč to není v gitu

Skoro 300 MB obrázků a videa jsou výstup, ne zdroj — zdroj je tenhle popis
a skripty v `Tools/`. PNG už je komprimovaný, takže se v gitu nezmenší
a v historii by zůstal navždy; a protože se mlýny a kyvadla točí dál, není
sada bajtově reprodukovatelná — každé přegenerování by přidalo dalších 85 MB
nových blobů, ne diff.

Záznam o tom, co se opravdu vydalo, drží App Store Connect u každé verze.
Kdyby ses k přesným souborům potřeboval vracet i lokálně, přibal je jako ZIP
k releasu u příslušného tagu — do historie repa se tím nedostanou.

## Co Apple vyžaduje

Aplikace cílí na iPhone i iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), takže jsou
povinné **dvě sady** screenshotů. Menší velikosti si Apple dopočítá sám.

| Sada | Rozlišení (portrét) | Rozlišení (landscape) | Počet |
|---|---|---|---|
| iPhone 6.9" | 1290 × 2796 nebo 1320 × 2868 | 2796 × 1290 nebo 2868 × 1320 | 3–10 |
| iPad 13" | 2048 × 2732 nebo 2064 × 2752 | 2732 × 2048 nebo 2752 × 2064 | 3–10 |

Formát PNG nebo JPEG, bez průhlednosti, bez zaoblených rohů, bez rámečku
zařízení (rámeček je povolený, ale musí být součástí obrázku a nesmí zakrývat
obsah). Řadí se v pořadí, v jakém je nahraješ — **první dva jsou to jediné, co
většina lidí uvidí** ve výsledcích vyhledávání.

App Preview je volitelný, 15–30 s, H.264 nebo ProRes 422 HQ, 30 fps. Zvuk není
povinný a hotová videa ho nemají — simulátor audio nenahrává a komentář by stejně
musel být lokalizovaný.

## Sada (8 obrázků)

Pořadí je zároveň pořadím nahrávání. Argumenty se dají zadat i ručně v Xcode:
**Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch**.

| # | Soubor | Obrazovka | Argumenty |
|---|---|---|---|
| 1 | `01-aim` | Zelená zahrada, jamka 6 — větrník a naváděcí čára | `-autostart garden 6 -aimdemo 0.7 -zoom 1.8` |
| 2 | `02-neon` | Neonové noci, jamka 12 — rotor | `-autostart neon 12 -aimdemo 0.6 -zoom 1.35` |
| 3 | `03-worlds` | Výběr kurzu se všemi devíti světy | `-courseselect -unlockall` |
| 4 | `04-volcano` | Vulkanická výheň, jamka 10 — láva a pásy | `-autostart volcano 10 -aimdemo 0.55 -zoom 1.3` |
| 5 | `05-cosmos` | Orbitální stanice, jamka 6 — centrifuga a looping | `-autostart cosmos 6 -aimdemo 0.6 -zoom 1.35` |
| 6 | `06-rating` | Závěrečné hodnocení a výsledková listina | `-finalrating -unlockall` |
| 7 | `07-clubhouse` | Klubovna — míčky, kariéra, trofeje | `-clubhouse -unlockall` |
| 8 | `08-daily` | Denní výzva | `-daily -aimdemo 0.6 -zoom 1.5` |

### Debug přepínače

| Přepínač | Co dělá |
|---|---|
| `-autostart <svět> <jamka>` | skočí rovnou do jamky |
| `-aimdemo [0…1]` | drží míření na jamku, aby šla naváděcí čára vyfotit |
| `-zoom <0,7…1,8>` | zafixuje pinch zoom kamery, aby se do záběru vešla celá dráha |
| `-unlockall` | dosadí věrohodný postup pro záběry menu (na disk se nezapisuje) |
| `-courseselect`, `-clubhouse`, `-daily`, `-finalrating`, `-holeselect <svět>` | otevře danou obrazovku |
| `-autoshot`, `-autowin`, `-autoadvance` | hraje samo — použité pro video |

`-zoom` násobí `cameraZoom` dané jamky, takže hodnoty v tabulce se mezi jamkami
liší; cíl je vždy dostat do záběru míček i jamku. Jsou zvolené tak, aby výsledný
zoom vyšel kolem 1,8 — tam jsou stíny ještě v pořádku. Při hodně odzoomované
kameře začnou vypadávat, protože kaskáda stínové mapy je kratší než dohled kamery.

Přegenerování nedá pixelově shodné soubory: mlýny, rotory a kyvadla se točí dál
a zaměřovací kroužek pulzuje, takže je pokaždé zastihneš v jiné fázi. Kompozice
i rozlišení ale sedí — statické obrazovky (`03-worlds`, `06-rating`) vyjdou
shodně.

## Popisky do obrázků

Vyrobí je [`Tools/appstore_captions.sh`](../Tools/appstore_captions.sh) z čisté
sady do `screenshots-captioned/`.

Layout: pruh s textem nahoře, pod ním zmenšený screenshot na tmavě zelené
(odvozené z gradientu hlavního menu) s tenkým rámečkem a měkkým stínem. Herní
záběr se nikde neořezává, jen zmenšuje — HUD nahoře ani ukazatel síly dole tak
o nic nepřijdou. Text je Arial Bold; je to jediný tučný řez v systému
s kompletní českou diakritikou (Arial Rounded Bold nemá `ť` ani `ě`
a SF se přes ImageMagick vykreslí jen v regular).

| # | Česky | English |
|---|---|---|
| 1 | Táhni, pusť, trefa. | Drag, release, sink it. |
| 2 | 9 světů, 108 jamek | 9 worlds, 108 holes |
| 3 | Od zahrady po orbit | From garden to orbit |
| 4 | Láva, led, vítr i magnety | Lava, ice, wind and magnets |
| 5 | Loopingy a děla | Loops and cannons |
| 6 | Par, Birdie, Eagle… nebo Bogey | Par, Birdie, Eagle… or Bogey |
| 7 | 14 míčků, 18 trofejí | 14 balls, 18 trophies |
| 8 | Nová jamka každý den | A new hole every day |

U šestky je použitá delší varianta z tabulky níž — původní „Hole-in-one? Zkus
to." mířila na hlášení po dokončení jamky, jenže záběr je nakonec závěrečná
výsledková listina, kam se hodí spíš výčet skóre. Texty se mění v obou funkcích
`cs_caption` / `en_caption` ve skriptu; zalomení delších popisků je tam napsané
ručně, aby na druhém řádku neviselo jediné slovo.

Delší varianty, kdyby byl na obrázku prostor na dva řádky:

| # | Česky | English |
|---|---|---|
| 1 | Naváděcí čára ukáže i odrazy od mantinelů | The aim line shows your bank shots |
| 2 | 108 ručně navržených jamek v devíti světech | 108 hand-designed holes, nine worlds |
| 3 | Každý svět má vlastní pravidla | Every world plays by its own rules |
| 4 | Voda a láva stojí trestný úder | Water and lava cost you a stroke |
| 5 | Fyzika, která se chová, jak čekáš | Physics that behaves the way you expect |
| 6 | Par, Birdie, Eagle… nebo Bogey | Par, Birdie, Eagle… or Bogey |
| 7 | Odemykej míčky, sbírej trofeje | Unlock balls, collect trophies |
| 8 | Jedna jamka denně, stejná pro všechny | One hole a day, same for everyone |

## App Preview (video)

Video je čistě záznam hry, bez loga a bez titulků — začíná odpalem, protože
prvních pár sekund rozhoduje. Skládá se ze šesti střihů:

| # | Záběr | Co je vidět |
|---|---|---|
| 1 | Zelená zahrada, jamka 1 | odpal, míček padá do jamky, hlášení PAR |
| 2 | Neonové noci, jamka 3 | odrazy mezi pinballovými bumpery |
| 3 | Zamrzlý fjord, jamka 10 | ledové pásy, proměna na BIRDIE |
| 4 | Vulkanická výheň, jamka 10 | jízda kolem lávy |
| 5 | Orbitální stanice, jamka 6 | roztočená centrifuga |
| 6 | Závěrečné hodnocení | „Profesionální golfista" a výsledky |

Hraje to samo (`-autoshot -autoadvance`) a fyzika je deterministická, takže
stejné argumenty dají pokaždé stejný záznam — střihové body v
`Tools/appstore_media.sh` (`IPHONE_CUTS`, `IPAD_CUTS`) proto sedí i po
přegenerování. iPad má vlastní body, protože se k jednotlivým jamkám dostane
o kus dřív než iPhone.

Simulátor nahrává ~72 fps, což App Store Connect odmítne;
[`Tools/appstore_video.swift`](../Tools/appstore_video.swift) záznam přestříhá,
zmenší na cílové rozlišení a vyexportuje H.264 na 30 fps.

iPhone video je 1290 × 2796 — záznam ze simulátoru (1320 × 2868) má o chlup jiný
poměr stran, takže se zmenší na šířku a pár řádků nahoře a dole se ořízne, aby se
obraz nedeformoval. Kdyby App Store Connect na tomhle rozlišení trval na jiném,
přegeneruje se natvrdo:

```bash
swift Tools/appstore_video.swift out.mp4 1320 2868 <klip>:<od>:<do> …
```
