# Checklist di rilascio FreshTrack

## Verifiche automatiche

- [x] `dart format --output=none --set-exit-if-changed .`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `./gradlew :app:lintRelease`
- [x] Build APK debug universale completata.
- [x] Target SDK e min SDK verificati.
- [x] Backup Android e traffico HTTP non cifrato disabilitati.
- [x] Firma release bloccata se manca una upload key personale.
- [x] Chiavi, configurazione SDK, build e coverage esclusi da Git.

## Prima di pubblicare il repository

- [x] Package ID definitivo: `io.github.kaonashi98.freshtrack`.
- [x] Codice pubblicato senza licenza open-source, con tutti i diritti riservati.
- [x] Indirizzo di assistenza professionale: `freshtrack.help@outlook.com`.
- [ ] Pubblicare `PRIVACY_POLICY.md` con un URL HTTPS stabile.
- [ ] Controllare che nessun file `.jks`, `key.properties` o `local.properties` sia incluso nel commit.
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
- [ ] Caricare icona 512×512, feature graphic 1024×500 e screenshot telefono.
- [ ] Dichiarare che l'app non contiene pubblicità.
- [ ] Compilare target audience, classificazione dei contenuti e Data safety.
- [ ] Dichiarare correttamente fotocamera e notifiche.
- [ ] Eseguire prima un test interno su almeno un dispositivo fisico.
- [ ] Se l'account personale è nuovo, completare il closed test richiesto da Play Console prima di chiedere l'accesso alla produzione.
- [ ] Controllare Pre-launch report e Android Vitals prima del rollout.

## Smoke test su dispositivo fisico

- [ ] Installazione pulita e aggiornamento sopra una versione precedente.
- [ ] Creazione, modifica ed eliminazione prodotto.
- [ ] Foto da fotocamera, foto da galleria, apertura a schermo intero e rimozione foto.
- [ ] Ricerca con tastiera aperta senza overflow, filtro categoria e ordinamento.
- [ ] Dashboard: indicatori interattivi, massimo tre priorità in ordine e pannelli per scadenze/scaduti.
- [ ] Eliminazione singola e multipla degli scaduti, entrambe con conferma.
- [ ] Cambio dell'orario delle notifiche dalle Impostazioni.
- [ ] Notifica alle 09:00 nel giorno di scadenza e notifica con preavviso personalizzato.
- [ ] Tap sulla notifica verso i prodotti della data corretta.
- [ ] Ripristino notifiche dopo riavvio.
- [ ] Navigazione Dashboard/Prodotti/Impostazioni fluida, senza bagliori.
- [ ] Tema sistema, chiaro e scuro.
- [ ] Cancellazione completa dei dati.
- [ ] Layout con font di sistema al 100% e al 200%.
