# FreshTrack — Play Console handoff

Prepared for candidate `1.0.0+11` (`io.github.kaonashi98.freshtrack`). This file
contains the repository-backed answers to copy into Play Console. Console labels
can change; read each displayed question before confirming it.

## Cosa fare in Play Console

Il codice, l'informativa, l'AAB e gli screenshot sono preparati fuori dalla
Console. In Play Console resta solo questo:

1. Crea l'app: gratuita, categoria Produttività, senza pubblicità.
2. Lingua predefinita `en-US`, traduzione `it-IT`.
3. Email `freshtrack.help@outlook.com`.
4. URL privacy `https://kaonashi98.github.io/FreshTrack/` dopo aver aperto
   la pagina e verificato la data 15 settembre 2026 e le sezioni Open Food
   Facts / ML Kit.
5. Carica `build/app/outputs/bundle/release/app-release.aab` e lascia attivo
   Play App Signing.
6. Icona `docs/play-store/play-store-icon-512.png` e feature graphic
   `docs/play-store/feature-graphic-1024x500.png`.
7. Screenshot telefono: `docs/play-store/screenshots-benefits-en/` in `en-US`
   e `docs/play-store/screenshots-benefits/` in `it-IT`.
8. Testi da `docs/play_store_listing_en.md` e `docs/play_store_listing_it.md`.
9. Data Safety, classificazione, pubblico non infantile e dichiarazione salute
   come nelle sezioni sotto.
10. Test interno o closed test se Console lo chiede, poi Pre-launch report.

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
`play_store_listing_it.md`. Phone screenshots for upload are in
`docs/play-store/screenshots-benefits-en/` and
`docs/play-store/screenshots-benefits/`.

## Permissions and core behavior

- Camera: barcode scanning, product photos and expiration-date OCR, only after
  an explicit user action. The camera is not a required hardware feature.
- Notifications: local expiration reminders. Users can use the inventory
  without granting notification permission.
- Completed boot: restores locally scheduled reminders after device restart.
- Internet: optional Open Food Facts lookups and technical traffic produced by
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

### Open Food Facts

Only after a user requests a barcode lookup, FreshTrack sends:

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

FreshTrack includes an optional Medicines category and expiration reminders. It
does not provide diagnoses, dosage advice, treatment recommendations or medical
device functionality.

Conservative declaration:

- declare the applicable medication/care-management feature if the Console
  offers it for medicine reminders;
- state that FreshTrack is not a medical device;
- use this disclaimer: “FreshTrack is a personal organization tool. It is not a
  medical device and does not diagnose, treat, cure or prevent any disease. For
  medical advice, diagnosis or treatment, consult a qualified healthcare
  professional.”

The disclaimer is present in the app, both store listings and the public privacy
policy.

## Content and distribution

- Complete content rating using the actual app behavior: no violence, gambling,
  sexual content, social features or user-to-user communication.
- Select all Google Play-supported countries/regions for worldwide availability.
- Leave Play App Signing enabled and upload the `1.0.0+11` AAB.
- If Play Console reports that version code 11 has already been used, increase
  the build number and regenerate every release artifact.
- If production access is locked for this app/account, complete the closed test
  shown by Play Console before requesting production access.
- Review the Pre-launch Report, device catalog exclusions and Android Vitals
  before starting the production rollout.

## Files to upload or copy

- AAB: `build/app/outputs/bundle/release/app-release.aab`.
- Icon: `docs/play-store/play-store-icon-512.png`.
- Feature graphic: `docs/play-store/feature-graphic-1024x500.png`.
- English phone screenshots: `docs/play-store/screenshots-benefits-en/`.
- Italian phone screenshots: `docs/play-store/screenshots-benefits/`.
- English copy: `docs/play_store_listing_en.md`.
- Italian copy: `docs/play_store_listing_it.md`.
- Privacy URL: `https://kaonashi98.github.io/FreshTrack/`.
