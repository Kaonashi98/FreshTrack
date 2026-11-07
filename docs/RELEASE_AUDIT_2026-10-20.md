# FreshTrack — audit di rilascio del 20 ottobre 2026

Questo rapporto distingue controlli sui sorgenti, test automatici, render di widget, prove Android e verifiche esterne. Un test automatico non certifica fotocamera, consegna delle notifiche o distribuzione Google Play.

## A. Stato iniziale

- Checkout principale: `C:\dev\FreshTrack`; HEAD iniziale `aa13dfe` (Record verified privacy page deployment).
- 37 file tracciati già modificati e 24 voci non tracciate nel riepilogo iniziale, incluse cartelle di screenshot. Nessun reset, stash, pull, commit, push o deploy.
- Versione sorgente `1.0.1+13`; AAB preesistente del 7 ottobre, precedente alle modifiche locali. Conservato prima della nuova build in `build/audit-2026-10-20/previous-app-release.aab`.
- Stato iniziale: `initial-status.txt`, `initial-head.txt`, `preexisting.patch` e hash `initial-files.json`, nella cartella di audit. Sono esclusi chiavi e configurazioni locali di firma.
- Flutter 3.44.6 / Dart 3.12.2. Firma release locale presente; nessuna chiave creata o modificata.
- Baseline compilata: 203 test passati (`baseline-verbose.log`). Due primi tentativi senza diagnostica sono rimasti bloccati al caricamento; non vengono conteggiati come passaggi riusciti.
- Principali rischi: scadenze precompilate non confermate, OCR numerico ambiguo, privacy pubblica obsoleta, candidato precedente non rappresentativo, collaudo fisico/Play mancante.

Ordine seguito: preservazione dello stato; scadenze e integrità dei dati; OCR/foto; privacy; Android e accessibilità; test completi; candidato firmato e verifiche dell'artefatto.

## B. Problemi riscontrati

| ID | Gravità | Evidenza e causa | Stato |
| --- | --- | --- | --- |
| FT-01 | P1 | Il modulo nuovo impostava `now + 7 giorni`; suggerimenti/duplicazione ricalcolavano la durata del vecchio prodotto. Era possibile salvare una data non verificata. | Corretto: data inizialmente assente, richiesta esplicita per ogni nuova confezione e dopo “aggiungi un altro”. Modifica di un prodotto esistente conserva la sua data. |
| FT-02 | P1 | Il parser numerico interpretava solo giorno/mese/anno, senza offrire la variante mese/giorno; ad esempio 03/04 era univoco per il codice ma ambiguo per l'utente. | Corretto: entrambe le interpretazioni valide sono proposte, mai salvate automaticamente. Supportata anche 10/25/2026. |
| FT-03 | P2 | Cambiare l'acquisto in una data successiva spostava anche la scadenza senza conferma. | Corretto: la scadenza rimane quella scelta; la validazione segnala l'ordine incoerente. |
| FT-04 | P2 | Home “Tutto in ordine” con inventario vuoto e con soli scaduti; conteggio riepilogo escludeva gli scaduti. Confermato anche nella cattura Android iniziale. | Corretto: invito al primo inserimento, messaggio neutro per la sezione futura, scaduti inclusi nel conteggio da controllare. |
| FT-05 | P2 | Copia fotografica interrotta poteva lasciare un file parziale senza record; ritaglio OCR non rimosso. | Corretto: pulizia best effort che conserva l'errore originale; ritaglio rimosso anche su errore OCR. |
| FT-06 | P2 | Decodifica/ritaglio/ricodifica OCR eseguiti sul thread UI; orientamento EXIF non applicato prima del ritaglio. | Corretto: elaborazione in isolate e orientamento applicato. Fotocamera ed EXIF su hardware restano da collaudare. |
| FT-07 | P1 per pubblicazione | Privacy locale senza dati aggiuntivi auto zoom; pagina pubblica HTTP 200 del 7 ottobre senza cataloghi aggiuntivi e zoom. | Documenti/app/HTML locali aggiornati al 20 ottobre, IT/EN. Deploy non effettuato: blocco esterno aperto. |
| FT-08 | P2 | Lint: apertura impostazioni notifiche mediante costanti API 26 anche su minSdk 24. | Corretto con controllo versione e impostazioni dell'app come alternativa su API 24–25; Lint finale senza rilievi. |
| FT-09 | P2 | Render 320 dp/font 200%: parole delle destinazioni spezzate; icona decorativa restringeva il titolo home. | Corretto: etichette su una riga con ellissi e testo semantico completo; icona decorativa nascosta solo col testo grande. |
| FT-10 | P2 | Errore quantità, quando il campo facoltativo non era montato, mostrato in italiano anche con UI inglese. | Corretto il messaggio inglese; validazione numerica invariata. |
| FT-11 | P3 | Analisi senza argomenti includeva copie storiche Dart in `build/`, incompatibili col modello attuale; un test preesistente non formattato. | Esclusa solo la cartella generata `build/**`; nessuna esclusione di `lib` o `test`, nessuna regola disabilitata. File test formattato. |
| FT-12 | P2 | Su Android, negando la fotocamera, il riquadro scanner si sovrapponeva al messaggio di errore. Il nuovo test a 320 dp/font 200% riproduceva anche un overflow di 280 pixel. | Corretto: overlay solo sulla preview funzionante; errore scorrevole con accesso a galleria e codice manuale. Due regressioni a font 100%/200%. |
| FT-13 | P2 da diagnosticare | Avvii con timeout, fotogrammi saltati e blocco di System UI nell'emulatore; il log del processo finale riporta anche `Skipped 252 frames`. | Aperto: rallentamento osservato, causa app/engine/emulatore non isolata. Necessaria prova controllata e su hardware; nessuna correzione speculativa del renderer. |

Nessun P0 confermato nei casi eseguiti. Non equivale a escludere difetti nei percorsi non collaudati. Il timeout della vecchia app sull'emulatore non viene automaticamente classificato come ANR né attribuito a una causa certa.

## C. Correzioni e verifiche associate

- `product_form_screen.dart`: scadenza nullable prima della scelta, nessuna durata ereditata da suggerimenti/template, nessuno spostamento automatico modificando l'acquisto; quantità localizzata. Regressioni per nuovo inserimento senza data, duplicazione, suggerimenti, inserimento consecutivo e salvataggio ripetuto durante sincronizzazione.
- `expiration_date_parser.dart`: interpretazioni numeriche internazionali, rifiuto date impossibili; test di data americana, ambiguità e bisestile.
- `product_image_storage.dart`: rimozione della copia parziale; test che simula effettivamente un file scritto prima dell'errore di spazio.
- `expiration_date_ocr_service.dart` e `expiration_date_image_preprocessor.dart`: pulizia del derivato, isolate, EXIF; nuovi test di successo/errore che verificano la conservazione dell'originale.
- `dashboard_screen.dart`, `main_shell.dart`: testi veritieri e aggiustamenti limitati per font grandi; test home vuota/scaduti, test responsive e render.
- `MainActivity.java`: compatibilità impostazioni notifiche API 24–25; verifica Android Lint.
- `PRIVACY_POLICY.md`, `privacy_policy_screen.dart`, `docs/privacy-site/index.html`, `docs/play_console_handoff.md`: informative coerenti in italiano/inglese e nota Data Safety sullo zoom; test contenuto/privacy aggiornati.
- `analysis_options.yaml`: esclude artefatti storici di build. Modifiche ai test pertinenti; nessun test eliminato.
- `barcode_scanner_screen.dart`: riquadro/istruzioni nel callback overlay della
  preview; messaggio errore scorrevole. `barcode_scanner_screen_test.dart`
  simula permesso negato e verifica apertura manuale senza sovrapposizioni o
  overflow, anche a 320 dp/font 200%.

Database/schema, migrazioni e formato ZIP v1 non modificati. Aggiunti test che rifiutano percorsi ZIP con traversal/assoluti conservando il repository e che ripristinano la vecchia categoria `medicines` come `personalCare`, preservando identificativo e data.

## D. Interfaccia grafica

Palette, font, componenti arrotondati, struttura delle schermate e navigazione approvati conservati. I cambiamenti visivi derivano dai problemi elencati.

Render di widget correnti: 88 immagini, 8 configurazioni (IT/EN × chiaro/scuro × 412 dp/100% e 320 dp/200%). Coprono home vuota/popolata, inventario, scelta aggiunta, modulo, dettaglio, impostazioni, aspetto, notifiche, dati e privacy. Nessuna eccezione di layout nelle configurazioni generate. Sono render con repository/notifiche simulati, NON screenshot Android e NON asset Store da caricare.

Le catture del 19 ottobre sono materiale storico: sono state ispezionate per confrontare l'identità visiva, senza presentarle come prove del candidato odierno. TalkBack reale, tastiera dei diversi produttori, fotocamera e animazioni non sono certificabili dai render.

Il nuovo set reale IT/EN è in `docs/play-store/candidate-2026-10-20/`: 16 PNG
1080×2400, otto per lingua, con manifest degli hash e provenienza. Le immagini
sono integrali, senza ritocchi o prodotti medici. Icona 512×512 e feature graphic
1024×500 conservano l'identità esistente. Le vecchie composizioni e anteprime
rimangono disponibili come storico; la documentazione non le indica più come
asset correnti. Approvazione editoriale e confronto con il bundle selezionato
in Console rimangono necessari.

### Prove Android eseguite e limiti

Provenienza delle prove: CRUD, notifica ricevuta, CSV, cambio tema e testo al
200% sono stati collaudati sul candidato intermedio 14 con SHA AAB
`f99c361c8b9df1358d5bf64f92e0b937e7b40984c932be9857e5fe695f4226ab`.
Dopo la sola correzione Dart dello scanner è stato installato il candidato
finale `7fbc9490…`: nuovamente verificati scanner negato/manuale, ripristino del
backup dimostrativo, eliminazione, inventario vuoto, lingua/preferenze e
corrispondenza SHA dell'APK. Tutte le 16 catture Store consegnate provengono
da questo ultimo APK. La ricezione della notifica non è stata ripetuta dopo
la patch scanner; codice e risorse delle notifiche sono rimasti invariati.

- Pixel 8 emulato `emulator-5554`, API 35, pagine 4096 byte. Non è uno
  smartphone fisico né un ambiente 16 KB.
- Copia locale protettiva autorizzata (`device-before.tar`); database iniziale
  schema 4 e **0 prodotti**. Inserito un record sintetico nella build 13;
  aggiornamento con `adb install -r` alla 14 riuscito, identificativo e date
  conservati. Nome poi cambiato da AQA a Yogurt attraverso l'interfaccia.
- APK derivato dal bundle release con bundletool, firmato con la stessa chiave
  debug dell'installazione precedente. Manifest non debuggable: prova di codice
  release, ma NON prova della firma Play né dell'installazione tramite Store.
- Nuovo modulo senza data; salvataggio con solo nome rifiutato con messaggio
  esplicito. Modifica conserva la data scelta. Home e inventario si aggiornano.
- Archiviazione “consumato”, ritorno “disponibile” ed eliminazione con conferma
  riusciti sul record sintetico.
- Backup creato attraverso il selettore Android e acquisito localmente:
  formato v1, versione 1.0.1+14, un prodotto, zero foto. Anteprima e Unisci
  riusciti senza duplicati. Dopo eliminazione del record, Sostituisci lo
  recupera correttamente. Nessun test distruttivo su dati personali.
- CSV esportato attraverso il selettore Android, BOM `EF BB BF`, separatore
  `;`, intestazioni italiane, quantità 1 e date civili 2026-10-20 corrette.
  Apertura manuale in Excel/Fogli Google ancora non eseguita.
- Cambio chiaro/scuro e italiano/inglese verificato. Lingua inglese e prodotto
  persistono dopo force-stop della sola app e riapertura. Testo al 200% provato
  su home/dettaglio, quindi riportato al valore iniziale 1.0; tema e lingua
  dell'app riportati a Sistema.
- Promemoria di prova programmato, app in background, notifica realmente
  ricevuta con icona e testo. Non è una prova di reboot, Doze, cambio fuso,
  esattezza dell'orario o apertura del prodotto da notifica.
- Il tocco sulla notifica è stato interferito dal dialogo Android
  **“L'app UI sistema non risponde”**, documentato in screenshot. L'avvio a
  freddo ha riportato `Status: timeout`, WaitTime 11676 ms; sul candidato
  finale anche 11234 ms, con home poi comparsa e dati corretti. Nel log
  limitato al PID FreshTrack finale compaiono avvisi EGL e 252/76 frame
  saltati (`final-app-process.log`). La causa non è stabilita: nessuna promessa
  di fluidità o assenza di ANR deriva da questo audit.
- Fotocamera negata: messaggio e alternative manuali disponibili; dialogo
  codice manuale aperto senza inviare dati. La correzione finale è confermata
  da `device/final-scanner-denied.png` e `final-scanner-manual.png`.
  Lettura di un codice reale,
  torcia/auto zoom, foto/OCR con sensori fisici rimangono non verificati.
- Al termine eliminato soltanto il prodotto di audit, inventario nuovamente
  vuoto. ZIP e CSV dimostrativi restano in Download dell'emulatore e nella
  cartella audit, distinti dalla copia protettiva originale.

## E. Test e comandi

Il launcher batch Flutter/Dart ha mostrato blocchi intermittenti in questo ambiente. I comandi equivalenti sono stati eseguiti usando `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe` e `C:\src\flutter\bin\cache\flutter_tools.snapshot`; log ed exit code sono conservati. Non sono stati modificati SDK o servizi condivisi.

| Controllo | Esito / prova |
| --- | --- |
| `flutter pub get` | PASS, dipendenze risolte; nessun upgrade generalizzato. |
| `dart format --output=none --set-exit-if-changed lib test` | PASS finale, 0 modifiche richieste. |
| `flutter analyze` | PASS finale sull'intero progetto, esclusi soli artefatti `build/**`. |
| `flutter test --coverage` | 215 test passati; vedere `final-tests.log`. |
| Test render separati | 8 passati; `visual-review.log`, directory `rendered/`. |
| `android/gradlew.bat :app:lintRelease` | PASS finale, nessun rilievo. Primo run: 0 errori, 2 warning poi corretti. |
| CI GitHub Actions | Configurazione letta: Flutter 3.44.6, pub get, format, analyze, test coverage, lint e APK debug. Esecuzione remota corrente NON VERIFICATA. |
| Test di integrazione dedicati | Non presenti in `integration_test/`. |

Sono stati mantenuti nei log anche i tentativi falliti: import Dart collocato erroneamente durante una prima patch (corretto), test di navigazione che non selezionava la nuova data obbligatoria (aggiornato senza rimuovere verifiche), errori dei sorgenti storici di build e due lint Dart poi risolti. Non si conteggiano come passaggi verdi.

Copertura finale: 4089/5412 righe, **75,55%** (`coverage/lcov.info`).
La copertura di righe non misura affidabilità di sensori, sistema Android o Play.

### Integrità e funzionalità controllate

- Drift: lettura/scrittura/ordinamento, transazioni in replaceAll, migrazione legacy e date civili, mutex condiviso fra mutazioni e trasferimenti.
- Scadenze: calendario civile, oggi/domani/sette giorni, cambio data/resume, bisestili e fusi nei test; dashboard e filtri coerenti.
- ZIP: limiti 250 MB complessivi, 32 MB manifest, 20 MB foto, 5000 prodotti; limiti durante decompressione, CRC, nomi duplicati, traversal, immagini mancanti, conflitti merge, rollback e conservazione foto anche se il rollback fallisce. Test con repository/database temporanei, nessuna cancellazione di dati personali.
- Il rollback è una gestione degli errori operativi: non è una prova di ripristino atomico dell'insieme SQLite/preferenze/foto dopo spegnimento forzato o guasto disco. Questi scenari restano da collaudare.
- CSV: UTF-8 con BOM, campi quotati, separatore `;`, escape virgolette, multilinea e protezione dei prefissi formula. Apertura manuale in Excel/Fogli Google NON VERIFICATA in questo audit.
- Scanner: fallback manuale e gestione errori/timeout/risposte tardive verificati in codice e test. Formati EAN/UPC/ITF; non copertura universale di ogni simbologia o catalogo.
- OCR: scelta obbligatoria tra candidati; le date di produzione non sono automaticamente distinte semanticamente dalle scadenze. Il testo rilevato e la conferma dell'utente restano essenziali. Formati non riconosciuti richiedono inserimento manuale.
- Notifiche: pianificatore, lingua, sincronizzazione, permessi negati, fallback allarmi inesatti e navigazione testati con plugin simulato. Ricezione fisica/reboot/Doze non deducibili dai test. Il fuso viene riallineato all'avvio/resume; cambio di fuso con app chiusa va provato separatamente.
- Foto: storage privato, validazione formato/dimensioni, sostituzione e cleanup; rendering di file mancanti gestito. File temporanei del selettore Android e terminazione forzata durante la selezione richiedono ancora collaudo reale.

## F. Sicurezza, privacy e servizi

Privacy online acquisita realmente via HTTPS: HTTP 200, contenuto datato **7 ottobre 2026**, non soltanto controllo dello status HTTP. Copia in `privacy-live.html`. Manca la descrizione estesa Open Facts e auto zoom; non è stata pubblicata alcuna modifica.

La [guida ufficiale ML Kit](https://developers.google.com/ml-kit/android-data-disclosure) descrive metriche tecniche e, con auto zoom, identificatore di sessione, variazioni zoom e coordinate previste del riquadro barcode. Questi aspetti sono ora riportati localmente in entrambe le lingue. Le risposte finali Data Safety devono essere verificate nella Console; nessun modulo è stato inviato.

Ricerca OSV (`osv-pub.json`): 169 dipendenze Pub/versioni interrogate, nessun advisory restituito. È una ricerca puntuale di vulnerabilità note nel database [OSV](https://osv.dev/), non una garanzia di assenza di vulnerabilità e non un audit completo delle transitive Maven/native. `pub get` segnala versioni più recenti: non sono state aggiornate indiscriminatamente.

Ricerca di pattern comuni di chiavi private/token nei file tracciati: nessun risultato. Keystore e configurazioni locali non tracciati e non modificati; non esposte password. Nessun SDK pubblicitario, account o backend introdotto.

API reali, richieste con codici dimostrativi pubblici (`open-facts-live.json`):

- `3017620422003`: HTTP 200, food, nome disponibile.
- `3560070791460`: HTTP 200 e redirect Open Beauty Facts, beauty, nome disponibile.
- `3760044183738`: HTTP 200 e redirect Open Products Facts, product, ma nome richiesto assente: il fallback manuale è necessario.
- Pet food: logica e test presenti; nessun prodotto pet food live validato in questo audit.

La [documentazione Open Facts](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/scanning-cosmetics-pet-food-and-other-products/) conferma `product_type=all` e i redirect fra i quattro cataloghi. I dati recuperati identificano il prodotto e non la scadenza della singola confezione.

## G. Bundle Google Play

Candidato locale provvisorio `1.0.1+14`, con package `io.github.kaonashi98.freshtrack`. `pubspec.yaml` resta `1.0.1+13`: il numero 14 è passato esplicitamente alla build, non dichiarato libero in Console. Firma locale esistente, nessun upload.

| Campo | Candidato finale |
| --- | --- |
| Percorso | `C:\dev\FreshTrack\build\app\outputs\bundle\release\app-release.aab` |
| Versione | `1.0.1`, versionCode `14` provvisorio |
| Package | `io.github.kaonashi98.freshtrack` |
| Dimensione | 92.223.539 byte (87,95 MiB) |
| SHA-256 | `7fbc9490b98354d8677d232142fa1366974c4a5177fc97b3bcbebdaecf2a9343` |
| Certificato SHA-256 | `6832bdc0f1ae2876827fabfee57ae65ded344902e7b004cb0e06574c5348477c` |
| SDK | min 24, target/compile 36 |
| ABI | armeabi-v7a, arm64-v8a, x86_64 |
| Build | Release, R8 e resource shrinking; non debuggable |
| Validazione bundletool | PASS, versione 1.18.3 |
| Firma | `jar verified`; verifica aggiuntiva JarFile: 425 entry firmate, 0 payload non firmati |
| Allineamento packaging | `PAGE_ALIGNMENT_16K`; APK derivato: `zipalign -c -P 16 -v 4` riuscito |
| ELF a 64 bit | 18 librerie, tutti i LOAD almeno 16 KB; RELRO allineato o isolato da dati scrivibili successivi |
| Runtime 16 KB | NON VERIFICATO: emulatore disponibile con pagine 4096 byte |

Gli AAB intermedi sono conservati come `intermediate-before-visual-fixes.aab`
e `intermediate-before-scanner-fix.aab`; non sono candidati da pubblicare.
Il manifest di 147 file sorgente/configurazione/asset
`candidate-source-manifest.json` coincide con il codice finale, senza differenze.
Hash e metadati sono anche in `final-artifact.json`.
L'hash dell'APK installato è stato riletto dal dispositivo e coincide con
l'APK derivato finale (`installed-artifact.json`):
`4ec45f353f0f4bec5a46d8562a4dcd7b4c476e22a492b80118bec81e2b2df25d`.

`jarsigner` segnala certificato autofirmato/catena non pubblica, assenza di
timestamp e ordine ZIP che produce differenze fra JarFile e JarInputStream.
I warning sono conservati integralmente in `signature-verify-final.log`; non sono
stati occultati né “corretti” riscrivendo il bundle. La verifica aggiuntiva legge
tutte le entry attraverso JarFile con verifica crittografica attiva; bundletool
valida ed estrae correttamente l'artefatto. L'accettazione e la corrispondenza
con la upload key in Console restano esterne.

Il controllo RELRO applica anche l'eccezione documentata per segmenti LOAD
isolati: una semplice verifica del resto modulo 16384 avrebbe segnalato falsi
positivi su Flutter, SQLite e altre librerie. Header e risultati completi in
`elf/` e `elf-alignment-final.json`. Le librerie a 32 bit sono inventariate,
ma non vengono usate per attestare il runtime 16 KB a 64 bit.

Manifest finale: CAMERA, INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED,
SCHEDULE_EXACT_ALARM facoltativo, VIBRATE, ACCESS_NETWORK_STATE e permesso interno
signature per receiver non esportati. Assenti AD_ID, accesso generico allo storage
e USE_EXACT_ALARM. `allowBackup=false`, regole di esclusione dati,
`usesCleartextTraffic=false`, FileProvider non esportato. Manifest completo in
`final-manifest.xml`; allarmi esatti non obbligatori per l'uso dell'app.

La [regola target API verificata](https://support.google.com/googleplay/android-developer/answer/11926878) richiede API 36 per nuove app/aggiornamenti Android generali dal 31 agosto 2026. Per i [16 KB](https://developer.android.com/guide/practices/page-sizes), controlli ELF/packaging e test runtime sono livelli distinti.

## H. Verifiche aperte e condizioni per il rilascio

1. Autorizzare e pubblicare l'HTML privacy preparato; rileggere online entrambe le lingue dopo deploy. Non basta una risposta HTTP 200.
2. Verificare in Play Console il prossimo versionCode disponibile, firma Play App Signing/upload, canali esistenti, schede Store, classificazione, pubblico, Data Safety e dichiarazioni salute.
3. Confermare i 12 tester continuativi per 14 giorni e l'effettiva approvazione dell'accesso alla produzione. Il 21 ottobre riferito dal proprietario è una previsione, non un esito verificato. [Regola ufficiale](https://support.google.com/googleplay/android-developer/answer/14151465).
4. Collaudare una release distribuita da Play su almeno uno smartphone fisico: scansione reale (trovato/non trovato/offline), OCR con date multiple/produzione/scadenza, fotocamera/galleria/rotazione e foto grandi.
5. Provare notifiche ricevute in background, permessi negati/revocati, preavviso/orario, tap, reboot, Doze, cambio fuso/ora. Non promettere puntualità assoluta.
6. Provare installazione pulita e aggiornamento Play mantenendo un inventario controllato con foto, backup Unisci/Sostituisci, errori/interruzioni e conservazione dati. Validare CSV in Excel/Fogli Google.
7. Eseguire runtime su Android minSdk 24 e su dispositivo/emulatore con pagine 16 KB; leggere Pre-launch Report, catalogo dispositivi e Vitals. TalkBack e fluidità fisica restano da verificare.
8. Approvare il nuovo set di otto catture reali per lingua e confrontarlo con
   l'esatto bundle scelto in Console. Escludere le vecchie composizioni
   `screenshots-benefits/*.png`, `screenshots-benefits-en/*.png` e anteprime
   `preview-it.png`/`preview-en.png`: la vecchia 04 proviene dalla build 11 e
   la 03 mostra il precedente modulo con scadenza precompilata.
9. Nessun risultato di questo audit autorizza automaticamente upload, richiesta produzione o pubblicazione mondiale.
10. Ripetere avvio a freddo e tap delle notifiche in un ambiente stabile,
    senza compilazioni contemporanee. Se il problema persiste su hardware,
    acquisire log del solo processo FreshTrack e traccia di sistema per
    distinguere app, rendering e sistema operativo. I timeout e l'ANR di
    System UI osservati non costituiscono una diagnosi della causa.
11. Completare stress con centinaia di prodotti e foto grandi, orientamento,
    TalkBack, contrasto misurato sistematicamente, installazione pulita e
    interruzioni forzate durante backup/ripristino. I render di nomi lunghi
    e i test di limiti/rollback non equivalgono a questi collaudi.

## I. Verdetto

| Ambito | Verdetto | Motivazione |
| --- | --- | --- |
| Qualità del codice locale | **PRONTO** | Per i controlli di codice eseguiti: correzioni mirate, 215 test, format, analisi statica e Android Lint senza rilievi. Non significa che tutti i comportamenti Android siano certificati. |
| Bundle Android di rilascio | **NON PRONTO** | Candidato tecnico locale firmato e validato, ma ancora provvisorio: versionCode/upload key non confermati in Console, runtime 16 KB/minSdk e collaudo fisico incompleti. |
| Google Play Console e test chiuso | **NON VERIFICATO** | Nessuna verifica autenticata di canali, 12 tester/14 giorni, approvazione produzione, Data Safety o versionCode disponibile. |
| Pubblicazione mondiale | **NO-GO** | Privacy pubblica non allineata (P1) e verifiche fondamentali di distribuzione, compatibilità e runtime ancora aperte. |

FreshTrack dispone di un candidato locale più affidabile, con difetti
riprodotti e corretti e prove tracciabili. Non è autorizzabile un GO mondiale
sulla sola base della suite verde o della compilazione riuscita.

### Consegna ed evidenze

- Sorgenti e documenti modificati nel checkout originale; modifiche pregresse
  preservate. Nessun commit, push, deploy o operazione in Play Console.
- Log, snapshot iniziali, manifest sorgente/artefatto, risultati ELF e catture
  diagnostiche: `C:\dev\FreshTrack\build\audit-2026-10-20`.
- Catture Store locali: `C:\dev\FreshTrack\docs\play-store\candidate-2026-10-20`.
- Informativa pubblicabile: `docs/privacy-site/index.html`; testo/app IT/EN
  aggiornati, pagina online ancora da pubblicare con autorizzazione.
- La copia protettiva dei dati è privata e locale: non fa parte degli asset
  Store e non deve essere caricata con il materiale promozionale.
