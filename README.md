# ⛳️ Minigolf

Kompletní 3D minigolfová hra pro iPhone a iPad postavená na **SwiftUI + RealityKit**.
Žádné externí závislosti, žádné stažené assety — celá grafika je generovaná procedurálně,
zvuky jsou syntetizované WAVy přibalené v bundlu.

## Hra

- **9 světů × 12 jamek = 108 jamek** s postupným odemykáním:
  - 🌿 **Zelená zahrada** — sluneční klasika (začátečník, par 35)
  - ☀️ **Pouštní oáza** — písečné pasti, voda, rotory (snadné, par 38)
  - 🌳 **Chrám v džungli** — bahno, liány, portály, řeky (střední, par 42)
  - ❄️ **Zamrzlý fjord** — klouzavý led, kry, náklony (těžké, par 42)
  - ✨ **Neonové noci** — Tron atmosféra, pinball, warpy (velmi těžké, par 42)
  - 🌋 **Vulkanická výheň** — láva, gejzíry, železné brány (expert, par 46)
  - ⚙️ **Hodinový stroj** — otočné talíře, písty, děla (mistr, par 42)
  - 🌊 **Bouřlivé pobřeží** — poryvy větru, skoky přes příboj (brutální, par 42)
  - 🌌 **Orbitální stanice** — loopingy, magnety, prázdnota (legendární, par 44)
- **Překážky:** větrný mlýn, rotory, posuvné bloky, bumpery, kuželky, retardéry,
  rampy na vyvýšené greeny, tunely, **naklonené greeny**, **pásy/řeky**,
  **portály**, **časované brány**, **kyvadla**, **gejzírové odpaliště** a
  pokročilá sada: **looping**, **skokánek** (balistický skok přes propast),
  **dělo**, **otočný talíř**, **magnet / repulzor** a **pulzující větrák**.
  Mantinely se dají zakřivit (`arcWall`) do oblouků a bank.
- **Obyvatelé světů** — každý svět má dvojici postaviček, které si po greenu chodí
  po svém: ježek a krtek, stepní křoví a surikata, žába a želva, **sněhulák** a
  tučňák, dron a strážní věž, skřítek a magmová kaňka, natahovací robot a kukačka,
  krab a racek, mimozemšťan a rover. Nejsou to kulisy — mají kinematické tělo,
  takže se od nich míček odráží, pohybující se postavička šťouchne i do stojícího
  míčku a zásah je rozhoupe. Chodí sem a tam, krouží, skáčou (pod skákající se dá
  proputovat) nebo se vynořují z díry v trávníku. Dráha je funkcí herních hodin,
  takže načasovaná rána vyjde stejně i podruhé — a naváděcí čára je, stejně jako
  u mlýnů a bran, záměrně ignoruje.
- **Povrchy:** tráva, písek, **bahno/popel** (extrémní tlumení), **led** (téměř bez
  odporu), **voda** i **láva** jako trestné jamky.
- **Prostředí kolem jamky** — každá jamka stojí na vlastním **dlážděném lemu**
  s obrubníkem (v neonových světech svítícím), okolní terén se zvedá do **vln**,
  na obzoru stojí kulisy podle světa (kopce s hájem, stolové hory, chrámová
  pyramida, zasněžené štíty, mrakodrapy, kouřící sopky, tovární komíny, maják,
  plynný obr s prstencem) a ve vzduchu se pohybuje **počasí**: pyl, písek
  v poryvu, světlušky, sníh, jiskry, uhlíky, pára, déšť a prach ve vakuu.
- **Bonusová hvězda na každé jamce** — schovaná mimo hlavní linii, sbírá se
  projetím míčku a započítá se po dokončení jamky (108 celkem).
- **Trénink:** u každého světa lze otevřít mřížku jamek a hrát jednotlivé jamky
  bez životů, s vlastním rekordem a hvězdičkami (1–3 podle par) na jamku.
- **Denní výzva** — jedna jamka na den, stejná pro všechny, losovaná ze všech
  devíti světů (i z těch dosud nezamčených, takže je i ochutnávkou toho, co
  hráče čeká). Drží **denní sérii**, počítá medaili podle par a jde opakovat.
- **Klubovna** — 14 odemykatelných míčků (barva, kov, záře i barva stopy),
  kariérní statistiky a **18 trofejí** s průběžným postupem.
- **Ovládání prakem:** táhni prstem od cíle, délka tahu = síla, pusť = odpal.
  Pinch = zoom kamery. Kamera plynule sleduje míček, každou jamku uvádí přelet.
- **Naváděcí čára** — tečkovaná předpověď dráhy včetně odrazů od mantinelů;
  když rána padne do jamky, čára zezlátne a telefon cvakne. Přepínatelná
  v nastavení (vypnuto / krátká / plná).
- **Pravidla jako na opravdovém minigolfu:** limit úderů = par + 3, voda/láva/aut
  = +1 úder a návrat míčku. Vyčerpání limitu = ztráta života (♥×4 na kurz).
  Bez životů = **Game Over** (s možností jamku si natrénovat), dokončení kurzu =
  **Success** se scorecard, hvězdami a rekordem.
- **Golfové skórování:** Hole-in-one, Eagle, Birdie, Par, Bogey… Po dokončení všech
  108 jamek se zobrazí **celkové golfové hodnocení** (od Víkendového golfisty po
  Golfovou legendu).
- Persistentní postup (UserDefaults), zvukové efekty, hudební smyčka, haptika,
  konfety při zásahu, stopa za kutálejícím se míčkem, lokalizace
  **čeština + angličtina**.

## Struktura kódu

```
Minigolf/
├── MinigolfApp.swift            vstupní bod
├── ContentView.swift            root přepínač obrazovek
├── Models/
│   ├── CourseType.swift         9 světů + pořadí odemykání (bez UIKitu)
│   ├── CourseTheme.swift        9 vizuálních témat (barvy, světla)
│   ├── LevelDefinition.swift    datový popis jamky (podlahy, zdi, překážky)
│   ├── LevelLibrary.swift       index nad světy
│   ├── Levels/*.swift           ručně navržených 108 jamek (1 soubor = 1 svět)
│   ├── Scoring.swift            golfová hodnocení, hvězdy za jamku i kurz
│   ├── GameProgress.swift       persistentní postup (rekordy jamek, bonusy)
│   ├── PlayerStats.swift        kariérní čísla, denní série, odemčené odměny
│   ├── Achievements.swift       18 trofejí s měřítkem postupu
│   ├── BallSkin.swift           14 míčků + jejich podmínky odemčení
│   └── DailyChallenge.swift     deterministický výběr jamky dne
├── Game/
│   ├── GameController.swift     stavový automat hry (životy, skóre, trénink,
│   │                            denní výzva, statistiky, trofeje)
│   ├── GameSceneCoordinator.swift  živá scéna: míření, fyzika, kamera, jamka,
│   │                               povrchy, silová pole, portály, loopingy, děla
│   ├── SceneBuilder.swift       stavba RealityKit scény z definice levelu
│   ├── Scenery.swift            prostředí mimo green: obloha, terén s vlnami,
│   │                            dlážděný lem jamky, obzor a počasí ve vzduchu
│   ├── Obstacles.swift          stavitelé překážek + animace kinematiky
│   ├── Primitives.swift         sdílené meshe kulisy (jeden tvar, škálovaný)
│   ├── Critters.swift           postavičky světů: modely + chůze po greenu
│   ├── AimGuide.swift           předpověď dráhy putu ze statické geometrie
│   ├── AimGuideRenderer.swift   tečkovaná čára + značka dopadu
│   ├── BallTrail.swift          mizející stopa za míčkem
│   ├── GameSettings.swift       naváděcí čára a stopa (uživatelské volby)
│   ├── TextureFactory.swift     procedurální textury (pruhy, písek, led, mřížka)
│   ├── SoundManager.swift       AVAudioPlayer efekty + hudba
│   └── Haptics.swift
├── Views/                       menu, výběr kurzu, výběr jamky, HUD, overlaye
└── Resources/
    ├── Sounds/*.wav             generované zvuky (viz níže)
    ├── Localizable.xcstrings    en + cs
    └── PrivacyInfo.xcprivacy    privacy manifest (UserDefaults CA92.1)

MinigolfTests/                   jednotkové testy nad čistou logikou (viz níže)
```

## Build & spuštění

Otevři `Minigolf.xcodeproj` v Xcode 26+ a spusť na iPhone/iPad (iOS 18.0+),
nebo z terminálu:

```bash
xcodebuild -project Minigolf.xcodeproj -scheme Minigolf \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Deployment target je 18.0, protože právě tam leží podlaha: `RealityViewCameraContent`,
`EventSubscription` a `MeshResource.generateCone`/`generateCylinder` jsou iOS 18 API.
Vyšší číslo by jen ukrojilo zařízení, na kterých hra běží.

Jazykový režim je **Swift 6** s `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: hra je
z drtivé většiny main-actor kód a je správně, že to tak kompilátor předpokládá.
Výjimky jsou tři a všechny jsou zvukové — `SoundManager`, `MusicPlayer` a datové
enumy, ke kterým sahají. Ty jsou `nonisolated` a `@unchecked Sendable`, protože je
nechrání aktor, ale sériová fronta: spustit je na main threadu je přesně to, čemu
se celý ten návrh vyhýbá. V režimu Swift 5 se tenhle rozpor nikde neprojevil,
Swift 6 ho kontroluje za běhu a `preload()` volaný z fronty na něm padal.

### Debug argumenty (jen DEBUG buildy)

Pro rychlé testování konkrétních jamek a obrazovek:

- `-autostart <garden|desert|jungle|ice|neon|volcano|clockwork|storm|cosmos> <1–12>` —
  skočí rovnou do jamky
- `-autoshot` — bot střílí sám směrem k jamce
- `-autowin` — okamžitě potopí míček (test overlayů, projde celý svět)
- `-autoadvance` — automaticky pokračuje na další jamku
- `-courseselect` / `-holeselect <course>` / `-clubhouse` — otevře danou obrazovku
- `-daily` — spustí dnešní denní výzvu
- `-unlockall` — dočasně (jen v paměti) doplní postup pro screenshoty menu
- `-finalrating` — zobrazí obrazovku celkového hodnocení
- `-aimdemo [0–1]` — podrží míření na jamku, aby šla naváděcí čára vyfotit
- `-zoom <0,7–1,8>` — zafixuje přiblížení kamery (násobí `cameraZoom` jamky), aby
  se na screenshot vešlo celé hřiště
- `-calibrate <0–1>` — každou ránu odpálí danou silou a vypíše skutečný dojezd;
  podle toho je nastavená délka naváděcí čáry v `AimGuideLevel.length(power:)`

### Testy

```bash
xcodebuild test -project Minigolf.xcodeproj -scheme Minigolf \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`MinigolfTests/` pokrývá to, co se dá tiše rozbít a co si toho nikdo nevšimne:
golfové prahy (`Scoring`), streaky a denní historii (`PlayerStats`), odemykání
světů a rekordy jamek (`GameProgress`), determinismus denní výzvy
(`DailyChallenge`), dosažitelnost trofejí i míčků a **naváděcí čáru**
(`AimGuide`) — kde se zastaví, jak se odrazí, kdy zezlátne a co všechno
schválně ignoruje. Jsou to čisté hodnoty — nic nesahá na `UserDefaults` ani na
RealityKit, takže sada doběhne pod vteřinu. Fyzika samotná testy nemá: běží
v solveru RealityKitu a mimo něj nedává smysl. Kontroluje ji `validate_levels`
níže (geometrie) a hraní (chování).

### Kontrola jamek

Geometrie všech 108 jamek se dá zkontrolovat offline — data levelů jsou čisté
Foundation + simd, takže se přeloží i pro macOS:

```bash
swiftc -O -o /tmp/validate Tools/validate_levels.swift \
    Minigolf/Support/MathHelpers.swift Minigolf/Models/CourseType.swift \
    Minigolf/Models/LevelDefinition.swift Minigolf/Models/LevelLibrary.swift \
    Minigolf/Models/Levels/*.swift && /tmp/validate
```

Hlásí jamku v mantinelu, green s otevřenou hranou, plochu nepřipojenou k odpališti,
překážku mimo hřiště, nedosažitelnou bonusovou hvězdu, rampu bez navazujícího
greenu, skokánek mířící do prázdna a podobně. Nakonec projde hrací plochu po buňkách (2 cm) včetně mantinelů,
sloupků a pevných bloků a ověří, že se míček z odpaliště opravdu dokutálí k jamce
i k bonusové hvězdě — tím se odhalí i kapsy uzavřené prkny uvnitř jednoho greenu.

### Lokalizace

Xcode při buildu vypisuje extrahované klíče do `*.stringsdata`. Skript je porovná
s katalogem, doplní chybějící (včetně češtiny) a smaže nepoužívané:

```bash
python3 Tools/sync_strings.py <cesta k derivedDataPath>
```

## Checklist pro App Store

Hotové v projektu:

- [x] Ikona 1024×1024 (single-size, `AppIcon.appiconset`)
- [x] `ITSAppUsesNonExemptEncryption = NO` (bez exportních otázek)
- [x] `PrivacyInfo.xcprivacy` — žádný sběr dat, deklarace UserDefaults (CA92.1)
- [x] Kategorie `public.app-category.sports-games`
- [x] Lokalizace en + cs, žádná nepoužitá oprávnění (kamera odstraněna)
- [x] Podpora iPhone i iPad, portrét i landscape
- [x] Přístupnost — VoiceOver popisky u ikonových tlačítek, hvězdiček, životů
      a číselných chipů; Dynamic Type přes `scaledFont` (v HUD zastropovaný na
      `.accessibility1`, aby text nepřekryl hřiště)
- [x] Texty pro App Store (cs + en) ve složce `AppStore/` — viz [AppStore/README.md](AppStore/README.md)

Zbývá udělat ručně v App Store Connect:

1. **Apple Developer účet** — projekt má nastavený team `K6GM85X5D7`, automatic signing.
2. Vytvořit App ID / záznam aplikace pro `cz.rob.Minigolf`.
3. **Archiv:** Xcode → Product → Archive → Distribute App → App Store Connect.
4. **Screenshoty** (6.9" iPhone + 13" iPad) — plán, rozlišení a popisky
   v [AppStore/screenshots.md](AppStore/screenshots.md).
5. Texty: zkopírovat z `AppStore/cs/` a `AppStore/en-US/` do příslušných polí.
6. Privacy v App Store Connect: „Data Not Collected" + URL se zásadami
   (hotový text v `AppStore/privacy-policy/`, stačí vystavit).
7. Věkové hodnocení: 4+.

## Poznámky k návrhu

- Fyzika: RealityKit dynamické těleso (koule r 3,4 cm, m 45 g), lineární tlumení 0,14,
  CCD zapnuté; písek = tlumení 3,2, bahno 6,5, led 0,02; jamka má „magnet" pro
  dochytávání pomalých míčků.
- Naklonené greeny, pásy, magnety, otočné talíře i vítr nejsou skutečná geometrie:
  jsou to silová pole, která na kutálející se míček tlačí. Tlačí jen v pohybu —
  míček stojící na pásu by se nikdy neuklidnil a limit úderů se vyhodnocuje až v klidu.
  Magnet přitahuje či odpuzuje se slábnoucí silou k okraji a vítr sinusově pulzuje —
  vrtule se točí přesně podle téže křivky, takže co hráč vidí, to míček cítí. Vítr
  jako jediný působí i na míček ve vzduchu.
- **Looping** neřeší solver: 3 cm kulička v putovací rychlosti by se buď zachytila
  o spoj mezi segmenty trati a vystřelila do nebe, nebo by se přilepila k plsti.
  Míček proto obíhá kružnici ručně, s energetickou bilancí valící se koule
  (podél dráhy ho brzdí jen 5/7 gravitace). Kdo nemá rychlost, vyjede kus nahoru
  a skutálí se pusou zpátky; komu chybí málo, tomu se u vrcholu ztratí kontakt
  s tratí a spadne dovnitř kruhu. Kamera přitom zůstává dole u plsti.
- **Otočný talíř** má dva režimy kontaktu a ty se nesčítají:
  - *valení* (rychlý míček) dráhu **zatáčí** — zrychlení je `ω × v`, kolmé na
    směr jízdy, poloměr zatáčky vychází `|v| / (0,9·ω)`. Postrkovat míček
    rychlostí povrchu je sice nasnadě, ale nefunguje: povrch běží před nábojem
    na jednu stranu a za ním na druhou, takže se oba strky vyruší a zbude jen
    brzdění.
  - *prokluz* (míček pomalejší než 0,18 m/s) už není o síle vůbec: talíř si míček
    převezme a **veze** ho po spirále ven, dokud ho na okraji zase nepustí i s
    rychlostí, kterou mu jízda dala. Stejný princip jako looping a dělo.
  Míchat je nelze: na míčku, který už jede dokola s talířem, míří zatáčecí člen
  přesně do náboje (je to dostředivá síla) a pomalu by ho navinul doprostřed.
- Míček, který **doopravdy zastavil**, solver zaparkuje a od té chvíle ignoruje
  jak `addForce`, tak `applyLinearImpulse` — proto silová pole ve hře působí jen
  za jízdy. Probouzet ho novým tělesem při každé detekci klidu nestačí: solver ho
  za chvíli uspí znovu a míček po talíři popolézá v půlvteřinových skocích.
  Cokoli, co má hýbat stojícím míčkem, ho proto musí vzít ze solveru úplně a
  vodit si ho samo.
- **Skokánek** dává míčku pevnou rychlost a pevný výskok, ať přijel jakkoli, takže
  délka skoku je vždy stejná (≈ 2·rychlost·výskok/g) a propast se dá navrhnout na
  centimetry; příliš pomalý míček se přes klín jen převalí. **Dělo** míček spolkne,
  chvíli nabíjí a vystřelí ho pevným směrem bez ohledu na to, odkud přijel.
- Portály vystřelí míček z druhého prstence se zachovanou rychlostí a pak se
  „odjistí", dokud míček neopustí oba prstence, takže nemůže pingpongovat.
- Míček, který přeskočí mantinel nebo spadne do vody či lávy, chytá záchranná síť
  (kontrola půdorysu hřiště + výšky) → penalizace a návrat na místo posledního odpalu.
- Naváděcí čára se počítá čistě geometricky ze **statické** části levelu (mantinely,
  bloky, sloupky, bumpery, tunely) a odráží se se stejnou restitucí jako opravdový
  míček. Mlýny, brány, rotory a kyvadla se do ní schválně nepočítají — čára, která by
  tvrdila, kde budou za vteřinu, by lhala a načasovací hádanky by ztratily smysl.
- Denní jamka je odvozená jen z data (FNV-1a hash dne → SplitMix64), takže je stejná
  na každém zařízení bez jakéhokoli serveru, a nikdy se neopakuje dva dny po sobě.
  To druhé stojí víc práce, než se zdá: srovnávat dnešní los s včerejším *losem*
  nestačí, protože včerejšek mohl být sám přelosovaný a pak se dnešek vrátí k tomu,
  co včera opravdu padlo. Rozhoduje se proto proti tomu, co včerejšek skutečně
  vydal — a to znamená vyřešit i předevčírem. Řetěz se rozplétá čtyři dny zpět;
  hloub by záleželo jen tehdy, kdyby kolidovaly všechny dny mezi tím.
- Scéna se staví znovu pro každou jamku (`sceneToken`), takže restart je vždy čistý.
  Aby to nezaseklo obraz, staví se ze sdílených dílů: kulisy (kopce, stromy, komíny,
  kolejnice loopingu) mají jeden mesh na tvar a liší se jen škálou (`Prim`), materiály
  se cachují podle barvy a sada materiálů světa se drží od první jamky. Jamka se pak
  postaví za zlomek času, který stálo generovat pár set meshů a materiálů znovu.
- Každý svět má vlastní playlist (`Resources/Music/*.m4a`) a menu má svůj; `ContentView`
  podle fáze hry a aktuálního světa vybere svět a `MusicPlayer` mezi nimi přechází
  křížovým prolnutím. Svět není jedna smyčka, ale tři až čtyři celé skladby — hrají se
  po jedné, zamíchaně, a další nastupuje dřív, než ta předchozí dojde, protože jedna
  smyčka se během jednoho patování slyší šestkrát a přestane být hudbou. Prolínají se
  dva `AVAudioPlayerNode` krmené dekódovaným PCM bufferem: `AVAudioPlayer` neumí dvě
  stopy překrýt a u AAC by na každém spoji udělal slyšitelnou díru, protože priming
  a padding rámce enkodéru se do něj započítají.
- Assety lze přegenerovat skripty ve složce `Tools/`:
  `python3 Tools/gen_sounds.py` (zvukové efekty, čistá sinusová syntéza),
  `python3 Tools/import_music.py` (hudba — nic se nesyntetizuje: stažené CC0/CC-BY
  skladby se podle `Tools/music_sources.json` sestříhají, srovnají hlasitostí,
  zaenkódují přes `afconvert` do AAC a přepíše se z nich atribuce, kterou hra
  ukazuje v Nastavení),
  `swift Tools/gen_icon.swift <cesta k PNG>` (ikona aplikace),
  `Tools/appstore_media.sh` (screenshoty a App Preview do `AppStore/`, hraje si
  to samo v simulátoru přes DEBUG přepínače) a `Tools/appstore_captions.sh`
  (varianta screenshotů s popisky) — viz `AppStore/screenshots.md`.
