# Asset Google Play

Asset pronti:

- `play-store-icon-512.png`: icona 512×512, PNG 32 bit, meno di 1 MB;
- `feature-graphic-1024x500.png`: feature graphic 1024×500, PNG 24 bit;
- `feature-background-source.png`: sfondo sorgente generato per la feature graphic.

La feature graphic viene ricostruita in modo deterministico con:

```powershell
python tool/generate_store_assets.py `
  --background docs/play-store/feature-background-source.png `
  --logo assets/images/logo_launcher_foreground.png `
  --icon-source assets/images/logo_launcher.png `
  --output docs/play-store
```

Gli screenshot in `docs/screenshots/` sono materiale di sviluppo e non vanno
caricati su Google Play. Prima della pubblicazione occorre acquisire almeno
quattro nuove schermate 1080×2400 dalla build release corrente, usando prodotti
realistici e senza funzioni assenti.
