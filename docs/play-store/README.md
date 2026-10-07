# Asset Google Play

Asset pronti (lo screenshot n. 2 è obsoleto e non va caricato):

- `play-store-icon-512.png`: icona 512×512, PNG 32 bit, meno di 1 MB;
- `feature-graphic-1024x500.png`: feature graphic 1024×500, PNG 24 bit;
- `feature-background-source.png`: sfondo sorgente generato per la feature graphic;
- `screenshots-benefits/`: tre composizioni telefono 1080×2400 in italiano,
  da schermate reali sul Pixel 8;
- `screenshots-benefits-en/`: lo stesso set in inglese;
- `benefit-background-source-v1.png`: sfondo senza testo usato per le
  composizioni degli screenshot.

La feature graphic viene ricostruita in modo deterministico con:

```powershell
python tool/generate_store_assets.py `
  --background docs/play-store/feature-background-source.png `
  --logo assets/images/logo_launcher_foreground.png `
  --icon-source assets/images/logo_launcher.png `
  --output docs/play-store
```

Le composizioni orientate ai benefici si rigenerano in modo deterministico con:

```powershell
python tool/generate_benefit_screenshots.py `
  --background docs/play-store/benefit-background-source-v1.png `
  --output docs/play-store/screenshots-benefits `
  --root . `
  --language it
```

Per l'inglese, acquisire dal candidato release le tre schermate
`dashboard.png`, `quick-add.png` e `data-backup.png` dentro
`docs/screenshots/source-release-en/`, quindi eseguire lo stesso comando con
`--language en` e `--output docs/play-store/screenshots-benefits-en`.

Il set comunica tre risultati concreti: sapere cosa usare prima, aggiungere
rapidamente i prodotti e proteggere l'inventario con un backup. Le sei
composizioni del 19 settembre 2026 usano schermate della build 11 sul Pixel 8,
tema chiaro, italiano e inglese. Caricare in Console
soltanto gli screenshot 01, 03 e 04 di `screenshots-benefits/` per `it-IT` e di
`screenshots-benefits-en/` per `en-US`. Il vecchio n. 02 è stato rimosso.
