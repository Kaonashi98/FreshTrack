# FreshTrack — Grafite e petrolio, build 9

Data: 8 settembre 2026. Versione: `1.0.0+9`.

## Modifiche

Applicata all’app Flutter la palette Grafite e petrolio consigliata nel confronto
interattivo e approvata dall’utente. Le superfici hanno toni neutri; il petrolio
identifica le azioni e la navigazione selezionata. Ambra e rosso distinguono le
scadenze di oggi e i prodotti scaduti, insieme alle etichette testuali.

| Ruolo | Chiaro | Scuro |
| --- | --- | --- |
| Sfondo | `#F3F5F4` | `#161B1C` |
| Schede e campi | `#FFFFFF` | `#22282A` |
| Testo principale | `#20282A` | `#F1F5F4` |
| Testo secondario | `#626E70` | `#ADBABC` |
| Azione primaria | `#096E75` | `#8FD4D3` |
| Testo su azione primaria | `#FFFFFF` | `#163F41` |
| Icone delle categorie | `#536866` su `#EDF1F0` | `#B3C5C2` su `#2D3537` |

Coordinati i ruoli Material usati da finestre, selettori, menu e messaggi,
oltre allo sfondo di avvio Android e del visualizzatore foto. Le icone delle
categorie mantengono simboli diversi e usano la stessa coppia di colori neutri.
Le superfici Material più scure del tema chiaro sono state schiarite quanto
necessario per mantenere il contrasto del testo secondario almeno a 4,5:1.

La disposizione approvata resta quella della build 8: contenuto in alto, nessun
blocco logo/nome nella testata, impostazioni in alto a destra e DM Sans offline.
Questo intervento riguarda colori e versione; non modifica la logica di inventario,
salvataggio, backup, scansione o notifiche.

## Verifiche locali

- `flutter analyze --no-pub lib test` sui sorgenti finali: **nessun problema**.
- Suite completa: **178/178 test superati**, compresi layout stretti/orizzontali
  e testo al 200%, percorsi di aggiunta, Annulla, foto e trasferimento dati.
- Acquisizione di 12 schermate dai widget reali: home, inventario, scelta di
  aggiunta, modulo, impostazioni e dettaglio, in entrambi i temi. Due prove
  di rendering superate senza eccezioni.
- 50 coppie testo/sfondo misurate sui colori Flutter: **tutte almeno 4,5:1**.
  Comprendono testi principali e secondari sulle diverse superfici, pulsanti,
  avvisi e colori dei messaggi con azione. Questo controllo non è una
  certificazione completa di accessibilità.

| Contrasto | Chiaro | Scuro |
| --- | ---: | ---: |
| Testo principale sullo sfondo | 13,71:1 | 15,82:1 |
| Testo secondario sullo sfondo | 4,81:1 | 8,72:1 |
| Pulsante primario | 6,00:1 | 6,88:1 |
| Minimo fra le coppie verificate | 4,54:1 | 5,19:1 |

Log, misure e copie antecedenti sono in `build/ui-petrolio/`. I sorgenti di riserva
hanno estensione `.snapshot`. Conservati anche APK e AAB della build 8.
Il repository era già modificato all’inizio dell’attività; base Git
`a9490bbd05f5ee25721e540d986c0c30c30d7a8e`. Nessun commit o invio remoto.

## Anteprime

Immagini ottenute dai widget Flutter con dati dimostrativi, separate dalle
acquisizioni Android:

- [Home scura](screenshots/ui-petrolio-v9/dark-dashboard.png)
- [Home chiara](screenshots/ui-petrolio-v9/light-dashboard.png)
- [Prodotti scuri](screenshots/ui-petrolio-v9/dark-products.png)
- [Inserimento manuale](screenshots/ui-petrolio-v9/light-products-new.png)
- [Impostazioni](screenshots/ui-petrolio-v9/light-settings.png)

## Collaudo sul Pixel aperto

Verifiche concluse alle 11:42, ora del computer, sul Pixel originale
`emulator-5554`: Android API 35, 1080×2400, densità 420, pagine di memoria da
4096 byte e renderer standard Impeller/OpenGLES.

- Aggiornamento riuscito conservando i dati e verifica SHA-256 dell’APK QA
  effettivamente installato.
- Home scura, scelta Aggiungi e apertura dell’inserimento manuale.
- Digitazione con tastiera aperta e pulsante di salvataggio visibile.
- Apertura/annullamento del calendario nei due temi e apertura del menu categoria.
- Impostazioni Aspetto, passaggio al tema chiaro, home, inventario e filtro categoria.
- Riapertura di Aggiungi dopo Indietro, ritorno al tema scuro e riavvio del processo.
- Il riavvio finale è riuscito (`LaunchState: COLD`, `TotalTime: 3346 ms`);
  home visibile, preferenza scura conservata e inventario ancora vuoto.
- Nessuna schermata nera osservata nei percorsi controllati e nessun errore
  critico rilevato nei log dei due processi prima e dopo il riavvio.

Il nome temporaneo «Prova palette» è stato solo digitato e poi abbandonato:
nessun prodotto creato o eliminato. L’app resta aperta sul Pixel in tema scuro.
Questa è una verifica mirata della revisione visiva; OCR, fotocamera, notifiche,
backup e importazione non sono stati riprovati manualmente in questo intervento.

Acquisizioni Android:

- [Home finale sul Pixel](screenshots/ui-petrolio-v9/pixel-final-dark-home.png)
- [Tastiera nel modulo scuro](screenshots/ui-petrolio-v9/pixel-dark-keyboard.png)
- [Calendario scuro](screenshots/ui-petrolio-v9/pixel-dark-calendar.png)
- [Calendario chiaro](screenshots/ui-petrolio-v9/pixel-light-calendar.png)
- [Impostazioni chiare](screenshots/ui-petrolio-v9/pixel-light-settings.png)
- [Menu categorie chiaro](screenshots/ui-petrolio-v9/pixel-light-filter.png)

## Pacchetti

APK e AAB release generati; firme verificate con apksigner/jarsigner e bundle
validato con bundletool. Versione `1.0.0`, versionCode `9`, min SDK 24 e target /
compile SDK 36. Font DM Sans, licenza e codice compilato delle tre ABI coincidono
fra APK e AAB.

| Pacchetto | Byte | SHA-256 |
| --- | ---: | --- |
| APK release | 114658858 | `6a14014bcd49cdd930cb08b81b1c87c0209f673608508c4bf970b9763b776eb3` |
| AAB release | 88631103 | `825f745fb09f6d1bcdae041018e7390f89a118c05d1a5570b80c9d0d66dd8186` |
| Copia APK per il Pixel | — | `79a748b064c8a7672a5595f870dc2aa6386145bcf4e48034e661ff00a79d50d1` |

Percorsi release: `build/app/outputs/flutter-apk/app-release.apk` e
`build/app/outputs/bundle/release/app-release.aab`.

Il Pixel aveva una build 8 firmata Android Debug. Android ha quindi rifiutato
il primo tentativo di aggiornamento con la firma release (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
Per conservare i dati è stata installata una copia del nuovo APK rifirmata con
la stessa chiave di sviluppo, in `build/ui-petrolio/app-pixel-qa.apk`.
Le 326 voci ZIP esterne a `META-INF/` sono identiche all’APK release, inclusi
manifest, risorse e librerie. La firma dei pacchetti store non è stata modificata.
La prova sul Pixel riguarda dunque il contenuto release con firma QA; non è
una prova di installazione dell’APK con la firma destinata allo store.

La compilazione riporta il precedente avviso di futura incompatibilità KGP di
`mobile_scanner`; i build attuali sono riusciti. Android lint e verifiche strutturali
a 16 KB documentati nella checklist restano riferiti alla build 7.

## Ambito del rilascio

Questa revisione visiva non chiude le verifiche esterne della
[checklist di rilascio](release_checklist.md): dispositivo fisico, runtime a
16 KB, privacy pubblicata e controlli Play Console restano distinti dalle prove
locali. Il collaudo funzionale approfondito precedente è documentato nella
[riprova Pixel della build 8](pixel_recheck_build8_2026-09-08.md).
