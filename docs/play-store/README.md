# Asset Google Play

## Candidato corrente — 20 ottobre 2026

Il set corrente di catture reali è in
[`candidate-2026-10-20/`](candidate-2026-10-20/README.md): otto PNG per lingua,
1080×2400, provenienza e hash documentati. Non contiene nuove composizioni
promozionali: conserva le schermate integrali del candidato locale `1.0.1+14`.
Va approvato e confrontato con la release effettivamente scelta prima dell'upload.

Le composizioni `screenshots-benefits/` e `screenshots-benefits-en/`, insieme
alle anteprime `preview-it.png` e `preview-en.png`, sono **storiche**: tutte le
immagini 01–08 vanno sostituite nella selezione destinata al nuovo rilascio.
In particolare 03 mostra il vecchio modulo e 04 usa ancora la build 11.
Non rigenerarle con le vecchie sorgenti per rappresentare la build 14.

## Inventario degli asset preesistenti

Asset locali per la scheda telefono in italiano e inglese:

- `play-store-icon-512.png`: icona 512×512, PNG 32 bit, meno di 1 MB;
- `feature-graphic-1024x500.png`: feature graphic 1024×500, PNG 24 bit;
- `feature-background-source.png`: sfondo sorgente generato per la feature graphic;
- `screenshots-benefits/`: otto composizioni telefono 1080×2400 in italiano;
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

Per l'inglese, eseguire lo stesso comando con `--language en` e
`--output docs/play-store/screenshots-benefits-en`. Le sorgenti di entrambe le
lingue sono indicate nel generatore.

Ordine delle otto immagini: dashboard, inventario, aggiunta rapida, backup,
scelta tra scansione e inserimento manuale, dettaglio prodotto, promemoria,
tema e lingua. Le nuove catture 01, 02, 03 e 05–08 provengono dalla build
`1.0.1+13` sull'emulatore Android nel tema chiaro, con tre prodotti dimostrativi
non medici; la schermata 04 conserva la cattura della build 11, che mostra
ancora le funzioni di creazione, ripristino ed esportazione del backup. Prima
del rilascio finale ricontrollare ogni immagine rispetto al bundle pubblicato.
Caricare gli otto PNG in ordine numerico nella scheda `it-IT` e gli otto PNG
inglesi nella scheda `en-US`. Il vecchio screenshot dei prodotti con
Ibuprofene resta escluso.
