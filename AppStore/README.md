# App Store metadata

Texty pro App Store Connect verzované v projektu. Nic se nenahrává automaticky —
otevři soubor, zkopíruj obsah, vlož do příslušného pole v App Store Connect.

Složky se jmenují podle konvence fastlane (`cs`, `en-US`), takže kdyby ses někdy
rozhodl přejít na `fastlane deliver`, stačí složku `AppStore/` přejmenovat na
`fastlane/metadata/` a funguje to bez přepisování.

## Kam co patří

App Store Connect → **Apps → Minigolf → iOS App → 1.0 Prepare for Submission**.
Nahoře je přepínač jazyka (**Czech** / **English (U.S.)**) — každé pole se
vyplňuje pro oba jazyky zvlášť.

| Pole v App Store Connect | Soubor | Limit | Aktuálně |
|---|---|---|---|
| App Name | `<jazyk>/name.txt` | 30 znaků | 22 |
| Subtitle | `<jazyk>/subtitle.txt` | 30 znaků | 29 / 28 |
| Promotional Text | `<jazyk>/promotional_text.txt` | 170 znaků | 130 / 124 |
| Description | `<jazyk>/description.txt` | 4000 znaků | ~2030 |
| Keywords | `<jazyk>/keywords.txt` | 100 znaků | 92 / 91 |
| What's New in This Version | `<jazyk>/release_notes.txt` | 4000 znaků | 260 / 248 |
| App Preview and Screenshots | generují skripty, viz [screenshots.md](screenshots.md) | 3–10 obrázků | 8 + video |

Varianty názvu, podtitulu a klíčových slov (kdyby název byl zabraný nebo chtěl
zkusit jiné ASO) jsou v [alternatives.md](alternatives.md).

Kontrola limitů:

```bash
python3 - <<'PY'
import os
lim={'name.txt':30,'subtitle.txt':30,'keywords.txt':100,
     'promotional_text.txt':170,'description.txt':4000,'release_notes.txt':4000}
for loc in ('cs','en-US'):
    for f,m in lim.items():
        n=len(open(os.path.join('AppStore',loc,f)).read().rstrip('\n'))
        print(f'{loc:6}{f:22}{n:5}/{m}', 'OK' if n<=m else 'PŘESAH!')
PY
```

## Poznámky k jednotlivým polím

- **App Name** — musí být globálně unikátní. Samotné „Minigolf" je skoro jistě
  zabrané, proto `Minigolf 3D: 108 jamek`. V aplikaci zůstává na ploše jen
  „Minigolf" (`INFOPLIST_KEY_CFBundleDisplayName`), to je v pořádku a Apple to
  nevadí — jen se název na ploše nesmí lišit *významově*.
- **Keywords** — oddělovat čárkou **bez mezer** (mezera se počítá do limitu).
  Neopakuj slova, která už jsou v názvu nebo podtitulu, Apple je indexuje zvlášť;
  proto v seznamu chybí „minigolf", „3D", „jamek", „holes".
- **Promotional Text** — jediné pole, které jde měnit bez nového buildu a bez
  review. Hodí se na sezónní/aktuální sdělení.
- **What's New** — u prvního vydání se pole často neukazuje; pokud ho App Store
  Connect nenabídne, prostě ho přeskoč a použij až u verze 1.1.

## Nastavení, které se nevyplňuje textem

**App Information** (společné pro všechny jazyky):

- Primary Category: **Games → Sports**
  (odpovídá `LSApplicationCategoryType = public.app-category.sports-games`)
- Secondary Category: **Games → Casual**
- Content Rights: neobsahuje obsah třetích stran
- Age Rating: **4+** — v dotazníku všechno „None". Pozor na položku *Contests* a
  *Unrestricted Web Access* → obojí Ne. Hra nemá násilí, chat, ani odkazy ven.

**Pricing and Availability:** Free, všechny země.

**App Privacy:** klikni *Get Started* → **„No, we do not collect data from this app"**.
Hra nemá síťový kód, žádné SDK třetích stran a všechno ukládá do UserDefaults na
zařízení (deklarováno v `Minigolf/Resources/PrivacyInfo.xcprivacy`, důvod CA92.1).
Přesto je **povinná URL se zásadami ochrany osobních údajů** — hotový text je
v [privacy-policy/](privacy-policy/), stačí ho někam vystavit (GitHub Pages,
gist, vlastní web) a URL vložit do pole *Privacy Policy URL*.

**Support URL:** povinné pole. Stačí stránka projektu na GitHubu nebo jednoduchá
stránka s e-mailem.

**Marketing URL:** volitelné, klidně nech prázdné.

**Encryption:** `ITSAppUsesNonExemptEncryption = NO` je v projektu, takže se
export compliance otázka při nahrání buildu vůbec nezobrazí.

**App Review Information** → poznámka pro recenzenta je v [review-notes.txt](review-notes.txt).
Účet ani demo přihlášení hra nepotřebuje — pole *Sign-in required* nech vypnuté.

## Postup vydání

1. Xcode → Signing & Capabilities zkontrolovat team `K6GM85X5D7`, bundle ID `cz.rob.Minigolf`.
2. App Store Connect → **Apps → +** → nový záznam, bundle ID `cz.rob.Minigolf`,
   primární jazyk **Czech** (nebo English, podle toho, který má být výchozí pro
   neznámé lokalizace — doporučuju **English (U.S.)** kvůli dosahu), SKU např. `minigolf-001`.
3. Přidat druhou lokalizaci (App Information → vpravo nahoře přepínač jazyka).
4. Vyplnit texty z tohoto adresáře. Screenshoty a App Preview v repu nejsou —
   vyrob si je `Tools/appstore_media.sh` a nahraj, podrobnosti
   v [screenshots.md](screenshots.md).
5. Xcode → Product → Archive → Distribute App → App Store Connect → Upload.
6. Počkat na zpracování buildu (10–60 min), pak ho vybrat v sekci *Build*.
7. Vyplnit App Privacy, Age Rating, Pricing.
8. **Add for Review** → *Submit*.
