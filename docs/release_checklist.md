# Checklist di rilascio FreshTrack

## Verifiche automatiche

- [x] File Dart modificati formattati con `dart format`.
- [x] `flutter analyze --no-pub lib test` sulla build 11: nessun problema.
- [x] Suite completa build 11: 191 test superati, inclusi lingua automatica e
      manuale, notifiche inglesi, Open Food Facts localizzato, privacy bilingue,
      CSV, backup, scanner, layout e controlli dei contenuti Play.
- [x] Interfaccia completa italiano/inglese: italiano quando la prima lingua del
      telefono è italiana, inglese per tutte le altre lingue; selezione manuale
      Sistema/Italiano/English nelle Impostazioni.
- [x] Palette azzurra/verde e home vuota più leggibile: 14 anteprime Flutter e
      50 coppie di contrasto nei due temi, tutte almeno 5,41:1.
      [Resoconto build 10](ui_leggibilita_build10_2026-09-08.md).
- [x] Build 10 sul Pixel originale: home vuota, temi, tastiera e riavvio verificati
      con copia del contenuto release firmata QA, conservando i dati della precedente
      installazione con firma di sviluppo. [Dettagli](ui_leggibilita_build10_2026-09-08.md).
- [x] Riprova build 8 sul Pixel originale riaperto: nessuna schermata nera nei
      percorsi verificati, tastiera, salvataggio/modifica, riavvio, Annulla,
      scanner, temi, filtri ed eliminazione. [Evidenze e limiti](pixel_recheck_build8_2026-09-08.md).
- [x] Regressioni per i 15 problemi dell'audit, sicurezza ZIP, rollback,
      serializzazione delle scritture e cambio del giorno.
- [x] `./gradlew :app:lintRelease` rieseguito sulla build 11: `BUILD SUCCESSFUL`.
- [x] APK e AAB release `1.0.0+11` generati e firmati. AAB del 19 settembre
      2026: 89.189.621 byte, SHA-256
      `86644BE292E8AF4898350EA1DCAAB2F05AC503C48A436E5AEAD54DF286620386`,
      `jarsigner` verificato, percorso
      `build/app/outputs/bundle/release/app-release.aab`.
- [x] Firma APK v2 verificata con `apksigner`; firma AAB verificata con
      `jarsigner`; AAB convalidato da bundletool 1.18.3.
- [x] APK allineato con `zipalign -c -P 16`; configurazione AAB confermata come
      `PAGE_ALIGNMENT_16K` da bundletool.
- [x] Min SDK 24, target/compile SDK 36 verificati.
- [ ] Verificare il bundle release build 11 su un dispositivo o emulatore con
      pagine da 16 KB; le prove sui vecchi artefatti non valgono per questo
      candidato.
- [x] Backup Android e traffico HTTP non cifrato disabilitati.
- [x] Firma release bloccata se manca una upload key personale.
- [x] Chiavi, configurazione SDK, build e coverage esclusi da Git.

Dettagli, impronte dei pacchetti e limiti delle prove sono nel
[resoconto del 6 settembre 2026](correzioni_audit_2026-09-06.md).
La base grafica del candidato è descritta nella
[revisione di colori e leggibilità build 10](ui_leggibilita_build10_2026-09-08.md);
le differenze globali della build 11 sono riepilogate nel `CHANGELOG.md`.
Il collaudo approfondito precedente è documentato nel
[collaudo Pixel 8 build 7](emulator_qa_build7_2026-09-07.md), ripreso dopo la
riapertura dell'emulatore. Le prove hanno verificato inventario, immagini,
OCR, ricerca, CSV, backup e notifiche con copie del codice release firmate
per QA e hanno portato a cinque correzioni. I limiti residui e lo stato finale
del Pixel sono nel resoconto. La prova non sostituisce il collaudo dei
pacchetti store su dispositivo fisico; i relativi punti restano aperti sotto.

## Prima di pubblicare il repository

- [x] Package ID definitivo: `io.github.kaonashi98.freshtrack`.
- [x] Codice pubblicato senza licenza open-source, con tutti i diritti riservati.
- [x] Indirizzo di assistenza professionale: `freshtrack.help@outlook.com`.
- [x] Preparare l'informativa bilingue aggiornata del 15 settembre 2026 con
      Open Food Facts, dati tecnici ML Kit, backup, permessi e disclaimer medico.
- [ ] Pubblicare su GitHub Pages l'informativa aggiornata del 15 settembre 2026 e
      verificare `https://kaonashi98.github.io/FreshTrack/` dopo il deploy.
- [x] Controllare che nessun file `.jks`, `key.properties` o `local.properties`
      sia tracciato da Git.
- [ ] Attivare GitHub Actions e verificare che la workflow `Flutter CI` sia verde.

## Firma e bundle Play Store

1. Creare e conservare in modo sicuro una upload key:

   ```powershell
   keytool -genkeypair -v `
     -keystore android/keystore/freshtrack-upload.jks `
     -alias freshtrack-upload `
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Copiare `android/key.properties.example` in `android/key.properties` e sostituire i valori di esempio.
3. Salvare keystore e password in due backup sicuri separati dal repository.
4. Generare il bundle:

   ```powershell
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   flutter build appbundle --release
   ```

5. Caricare `build/app/outputs/bundle/release/app-release.aab` in Play Console e lasciare attivo Play App Signing.

## Play Console

- [ ] Creare l'app come applicazione gratuita, categoria Produttività.
- [ ] Compilare scheda dello store, email di assistenza e URL privacy.
- [x] Preparare icona 512×512 e feature graphic 1024×500 in
      `docs/play-store/`.
- [x] Preparare il generatore di composizioni 1080×2400 separato per italiano e
      inglese e i testi localizzati.
- [x] Riacquisite le schermate build 11 in italiano e inglese sul Pixel 8
      (tema chiaro, inventario dimostrativo) e rigenerate le composizioni
      `docs/play-store/screenshots-benefits/` e
      `docs/play-store/screenshots-benefits-en/`.
- [ ] Caricare in Play Console le composizioni, l'icona e la feature graphic.
- [ ] Dichiarare che l'app non contiene pubblicità.
- [ ] Compilare target audience, classificazione dei contenuti e Data safety.
- [ ] Dichiarare correttamente Notifiche, Fotocamera e la connessione opzionale
      a Open Food Facts per la ricerca barcode.
- [ ] Dichiarare nella Data Safety i dati tecnici trasmessi da Google ML Kit,
      verificando categorie, finalità e trattamento contro la documentazione
      corrente dell'SDK.
- [ ] Verificare che l'attribuzione Open Food Facts/ODbL sia visibile e che la
      ricerca usi l'API v3.6 nel bundle definitivo.
- [ ] Compilare la dichiarazione app per la salute selezionando «Gestione di
      farmaci e cure» e riportare il disclaimer non-medical-device.
- [ ] Eseguire prima un test interno su almeno un dispositivo fisico.
- [ ] Se l'account personale è nuovo, completare il closed test richiesto da Play Console prima di chiedere l'accesso alla produzione.
- [ ] Controllare Pre-launch report e Android Vitals prima del rollout.

## Smoke test su dispositivo fisico

- [ ] Installazione pulita e aggiornamento sopra una versione precedente.
- [ ] Creazione, modifica ed eliminazione prodotto.
- [ ] Aggiunta rapida, suggerimenti, duplicazione e “Salva e aggiungi un altro”.
- [ ] Scansione barcode con prodotto trovato, non trovato e assenza di rete.
- [ ] OCR della scadenza con una o più date, conferma e foto illeggibile.
- [ ] Foto da fotocamera, foto da galleria, apertura a schermo intero e rimozione foto.
- [ ] Backup con e senza immagini; ripristino Unisci e Sostituisci dopo una
      reinstallazione; rifiuto di un file non valido.
- [ ] CSV aperto in Excel/Fogli Google con accenti, descrizioni su più righe e
      celle che iniziano con `=`, `+`, `-` o `@`.
- [ ] Ricerca con tastiera aperta senza overflow, filtro categoria e ordinamento.
- [ ] Dashboard: indicatori interattivi, massimo tre priorità in ordine e pannelli per scadenze/scaduti.
- [ ] Eliminazione singola e multipla degli scaduti, entrambe con conferma.
- [ ] Navigazione delle quattro aree Impostazioni e cambio dell'orario delle notifiche.
- [ ] Notifica verso l’orario scelto nel giorno di scadenza e notifica con preavviso.
- [ ] Tap sulla notifica verso i prodotti della data corretta.
- [ ] Ripristino notifiche dopo riavvio.
- [ ] Navigazione Dashboard/Prodotti/Impostazioni fluida, senza bagliori.
- [ ] Tema sistema, chiaro e scuro.
- [ ] Cancellazione completa dei dati.
- [ ] Layout con font di sistema al 100% e al 200%.
