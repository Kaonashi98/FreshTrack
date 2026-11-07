# FreshTrack — Play Console handoff

Working draft for `io.github.kaonashi98.freshtrack`. A signed provisional
`1.0.1+14` candidate was built locally on October 20; see
[the current audit](RELEASE_AUDIT_2026-10-20.md) for its hash and verification
boundaries. Version code availability and Play signing still need confirmation.
Check the live privacy page before copying these answers into Play Console.
Console labels can change; read each displayed question before confirming it.

## Cosa fare in Play Console

Il candidato locale è verificato nei limiti dell'audit; pagina privacy pubblica,
collaudo fisico, disponibilità versionCode e asset approvati richiedono ancora
verifica prima dell'invio in Console.
Poi completare questi passaggi:

1. Nell'app già esistente verifica: gratuita, categoria Produttività, senza pubblicità.
2. Lingua predefinita `en-US`, traduzione `it-IT`.
3. Email `freshtrack.help@outlook.com`.
4. URL privacy `https://kaonashi98.github.io/FreshTrack/` dopo aver aperto
   la pagina e verificato il testo del 20 ottobre 2026: quattro cataloghi
   Open Facts, metadati di rete, ML Kit e dati aggiuntivi dell'auto zoom in IT/EN.
5. Carica `build/app/outputs/bundle/release/app-release.aab` e lascia attivo
   Play App Signing.
6. Icona `docs/play-store/play-store-icon-512.png` e feature graphic
   `docs/play-store/feature-graphic-1024x500.png`.
7. Screenshot telefono: rimuovi dalla Console il vecchio screenshot della
   lista prodotti che mostra Ibuprofene. Carica gli otto PNG numerati delle
   rispettive cartelle, in ordine 01–08, dopo il controllo finale rispetto al
   bundle da pubblicare.
8. Testi da `docs/play_store_listing_en.md` e `docs/play_store_listing_it.md`.
9. Data Safety, classificazione, pubblico non infantile e dichiarazione salute
   come nelle sezioni sotto.
10. Controlla il test chiuso esistente e il Pre-launch report; verifica
    l'effettiva approvazione della produzione senza modificare automaticamente
    i canali o presumere completato il requisito dei tester.

## Store configuration

- App or game: App.
- Pricing: Free.
- Category: Productivity.
- Contains ads: No.
- Default language: English (United States), `en-US`.
- Italian translation: `it-IT`.
- Support email: `freshtrack.help@outlook.com`.
- Privacy URL: `https://kaonashi98.github.io/FreshTrack/`.
- App access: all functionality is available without an account or login.
- Target audience: not designed for children; select only the age groups that
  match the intended adult/general audience.

The English and Italian copy is in `play_store_listing_en.md` and
`play_store_listing_it.md`. Upload phone screenshots 01–08, in order, from
`docs/play-store/candidate-2026-10-20/en/` and
`docs/play-store/candidate-2026-10-20/it/`, after editorial approval and
comparison with the exact release selected in Console. These are real,
uncomposited candidate captures. The previous `screenshots-benefits*` sets
and any screenshot showing a medicine product remain obsolete for this release.

## Permissions and core behavior

- Camera: barcode scanning, product photos and expiration-date OCR, only after
  an explicit user action. The camera is not a required hardware feature.
- Notifications: local expiration reminders. Users can use the inventory
  without granting notification permission. Missed reminders are recovered when
  the app is opened.
- Exact alarms (`SCHEDULE_EXACT_ALARM`): optional, only if the user enables a
  more precise reminder time. If denied, reminders stay around the chosen hour.
  Do not declare `USE_EXACT_ALARM`.
- Completed boot: restores locally scheduled reminders after device restart.
- Internet: optional Open Facts catalog lookups and technical traffic produced by
  Google ML Kit components.
- No location, contacts, microphone, broad storage or advertising permission.
- Android automatic backup and device transfer are disabled.
- Cleartext HTTP traffic is disabled.

## Data Safety — repository-backed inventory

FreshTrack has no developer backend, account, advertising SDK or analytics SDK.
Product records, dates, notes, quantities, photographs and preferences are held
in private app storage and are not sent to the developer.

### Google ML Kit

The app uses ML Kit for bundled on-device text recognition; `mobile_scanner`
also uses bundled ML Kit barcode scanning on Android. According to Google's ML
Kit disclosure guide, the SDK can collect the following for diagnostics and
usage analytics:

- device information;
- app/package information and app version;
- per-installation identifiers not intended to identify a person or physical
  device;
- performance metrics;
- API configuration;
- feature input/output size and feature version;
- feature events and error codes.

Use the closest current Play Console categories, normally including:

- **App info and performance** — diagnostics/performance-related data;
- **App activity** — feature interaction/event information, when requested by
  the current form;
- **Device or other IDs** — ML Kit per-installation identifiers.

For these entries:

- purpose: Analytics and/or App functionality as the current Console wording
  requires for SDK diagnostics and operation;
- encrypted in transit: Yes (HTTPS);
- shared with third parties: No, according to Google's ML Kit disclosure;
- images, recognized text, product inventory and expiration dates: not sent to
  Google by FreshTrack's OCR flow.

Before submission, compare the form against the current official source:
https://developers.google.com/ml-kit/android-data-disclosure. Google explicitly
states that the developer remains responsible for the final declaration.

Auto zoom is enabled in the barcode scanner. Include its generated scanning-session ID, zoom level changes and predicted barcode bounding-box coordinates in the assessment, as specified in the official ML Kit disclosure. The local privacy documents dated October 20, 2026 describe this in both languages; the public page checked during this audit still serves October 7 and requires an authorized deployment.

### Cataloghi Open Facts

Only after a user requests a barcode lookup, FreshTrack sends the request to
Open Food Facts, which may redirect it to Open Beauty Facts, Open Pet Food Facts
or Open Products Facts according to the product type:

- the barcode;
- the requested language;
- an app User-Agent containing app name/version and support contact;
- ordinary HTTPS connection metadata, including the IP address received by the
  remote service.

FreshTrack does not send the inventory, photographs or expiration dates. The
barcode identifies a product rather than the user and does not naturally map to
a personal-data category in the Data Safety taxonomy; nevertheless, the
transfer is disclosed in both privacy-policy languages. Re-evaluate this answer
if the implementation or Google's form changes.

### User-directed export

ZIP backups and CSV exports are created only after an explicit user action and
saved through the Android system picker. FreshTrack does not automatically
upload them. If the user chooses a cloud document provider, that transfer is
user-directed and governed by the selected provider.

## Health apps declaration

Build 13 removes the dedicated Medicines category and related reminders.
The app is for pantry, drinks and personal care expiry dates. After replacing
the rejected build 12 and updating both store listings and screenshots, select
"My app doesn't provide any health features" in the Health apps declaration.
Do not submit that declaration while build 12 remains the only active build in
a test track.

## Content and distribution

- Complete content rating using the actual app behavior: no violence, gambling,
  sexual content, social features or user-to-user communication.
- Select all Google Play-supported countries/regions for worldwide availability.
- Leave Play App Signing enabled and upload only the newly verified AAB.
- Version code 12 is already used. Do not re-upload the rejected build.
- If production access is locked for this app/account, complete the closed test
  shown by Play Console before requesting production access.
- Review the Pre-launch Report, device catalog exclusions and Android Vitals
  before starting the production rollout.

## Files to upload or copy

- AAB: `build/app/outputs/bundle/release/app-release.aab`.
- Icon: `docs/play-store/play-store-icon-512.png`.
- Feature graphic: `docs/play-store/feature-graphic-1024x500.png`.
- English phone screenshots: files 01–08 in
  `docs/play-store/screenshots-benefits-en/`.
- Italian phone screenshots: files 01–08 in
  `docs/play-store/screenshots-benefits/`.
- English copy: `docs/play_store_listing_en.md`.
- Italian copy: `docs/play_store_listing_it.md`.
- Privacy URL: `https://kaonashi98.github.io/FreshTrack/`.
