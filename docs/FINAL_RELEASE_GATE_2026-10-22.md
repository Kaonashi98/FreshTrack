# FreshTrack — final release gate, 22 ottobre 2026

Questo rapporto prosegue [l'audit del 20 ottobre](RELEASE_AUDIT_2026-10-20.md). Distingue prove sui sorgenti, sull'artefatto Android, sugli emulatori e verifiche esterne. Con autorizzazione del proprietario è stata pubblicata **solo la pagina privacy** e poi il test CI strettamente necessario. Non sono stati caricati AAB o screenshot, né effettuate modifiche in Play Console, modifiche alle chiavi o cancellazioni di dati.

## A. Stato iniziale e provenienza

- Checkout `C:\dev\FreshTrack`, branch `main`, HEAD iniziale `aa13dfe1263b8a5ff916bc3839416d3bdfcd9eee` del 7 ottobre, all'inizio coincidente con `origin/main`. Checkout intenzionalmente sporco: 47 file tracciati modificati e 81 file non tracciati prima di questo rapporto. Nessuno è stato sovrascritto o rimosso. Sono poi stati inviati, con due autorizzazioni distinte, il solo HTML privacy (`9108b1a7b29df32b624c3ce118073c9a164a21d0`) e la sola correzione del test remoto (`f68af6a7d7b878b36173f74a1b86b35e4352a187`).
- Il proprietario conferma che `13` è il versionCode massimo in **tutti** i canali Play Console e che `14` non è mai stato caricato. È una dichiarazione diretta del proprietario, non una lettura autenticata in questa sessione. `pubspec.yaml` e il relativo test locale sono ora sincronizzati su `1.0.1+14`; queste modifiche restano locali.
- La firma release locale è configurata; `android/key.properties` è ignorato da Git e non è stato letto né modificato. L'AAB del 20 ottobre è stato preservato in `build/audit-2026-10-22/pre-version-sync-1.0.1+14.aab`, SHA-256 `7fbc9490b98354d8677d232142fa1366974c4a5177fc97b3bcbebdaecf2a9343`. Il manifest di 147 file `build/audit-2026-10-20/candidate-source-manifest.json` combaciava byte per byte prima della sincronizzazione; ora differiscono attesamente solo `pubspec.yaml` e il test della versione, senza modifica alla logica dell'app.
- L'AVD Pixel 8 preesistente `emulator-5554` è API 35/4096 byte. È stato creato un secondo AVD isolato `FreshTrack_16KB`, API 37/16384 byte, con dati in `build/audit-2026-10-22/Pixel_8_16KB.avd`; è stato chiuso dopo le prove. Nessuno smartphone fisico è comparso in `adb devices -l`.

## B. Problemi ancora aperti

| ID | Gravità | Evidenza e causa accertata o limite diagnostico |
| --- | --- | --- |
| GATE-02 | Risolto localmente, con limite Console | Il proprietario conferma massimo `13` in ogni canale e `14` mai caricato. Sorgente e test sono sincronizzati su `1.0.1+14`; la corrispondenza della upload key con Play App Signing resta **NON VERIFICATA IN CONSOLE**. |
| GATE-03 | P2, prestazioni | Su Pixel 8 emulato sono misurati avvii lenti e frame saltati. Nel nuovo AVD è ricomparso un ANR di `com.android.systemui`, insieme ad ANR di altri servizi Google. Non è stato trovato un evento `am_anr` attribuito a FreshTrack nei buffer consultati. Questo **non** identifica la causa dei frame saltati o dimostra fluidità dell'app su hardware. |
| GATE-04 | P1, collaudo di rilascio | Smartphone fisico, fotocamere reali, installazione da Play, aggiornamento Play con foto, riavvio/Doze/fuso delle notifiche, CSV aperto in Excel/Fogli Google e grande inventario reale non sono stati collaudati. Hardware e accesso autenticato alla Console non sono disponibili in questa sessione. |
| GATE-05 | P1, dichiarazioni e distribuzione | Data Safety, salute, permessi, classificazione, pubblico, paesi, firma, Pre-launch Report e Android Vitals non sono stati letti nella Console. Il proprietario dichiara completato il test chiuso e **approvato l'accesso alla produzione**; non è una verifica autenticata in questa sessione né implica l'approvazione di una release pubblica. Un tentativo di apertura read-only della Console è stato respinto dalla revisione automatica del browser per origine ambigua (`https://google.play` rispetto a `https://play.google.com`); non è stato aggirato. |
| GATE-06 | Risolto | Il primo workflow del commit privacy è fallito per un'aspettativa obsoleta (7 ottobre). Il secondo commit autorizzato ha cambiato solo le due aspettative del test e la [CI #39772634254](https://github.com/Kaonashi98/FreshTrack/actions/runs/39772634254) è terminata con `success`. La CI remota non include le altre modifiche locali del candidato. |

Nessun nuovo difetto P0/P1 del codice è stato riprodotto. Gravità e GO/NO-GO sopra riguardano la distribuzione, non sono una diagnosi di crash FreshTrack.

## C. Correzioni effettuate

Nessuna patch applicativa aggiunta: il manifest sorgente conferma che tutte le correzioni del 20 ottobre erano presenti prima della sincronizzazione della versione e nessun difetto nuovo è stato confermato. **GATE-01 risolto:** `docs/privacy-site/index.html` è l'unico file nel commit `9108b1a` (`12 insertions, 10 deletions`), inviato a `origin/main` dopo autorizzazione. Il workflow [GitHub Pages #39771993265](https://github.com/Kaonashi98/FreshTrack/actions/runs/39771993265) è terminato con `success` sullo stesso SHA. Il successivo commit autorizzato `f68af6a` contiene solo `test/release/global_release_content_test.dart`, con due aspettative di data aggiornate; le altre modifiche del test nel file di lavoro locale sono state preservate. Dopo conferma del versionCode, le sole nuove modifiche locali sono `pubspec.yaml` e il test di versione nello stesso file di test. Schema SQLite, formato backup ZIP v1, categorie legacy, design, asset e firma restano invariati. `git diff --check` termina con codice 0; gli avvisi CRLF di Git non sono errori di whitespace.

## D. Verifiche funzionali

| Funzione | Prove disponibili | Limite residuo |
| --- | --- | --- |
| Inventario e scadenze | 215 test complessivi includono nuovo inserimento con data obbligatoria, modifica, duplicazione, suggerimenti, inserimento consecutivo, filtri, stati archivio, contatori, date civili e bisestili. Il 20 ottobre CRUD e backup con un prodotto sintetico furono provati su `emulator-5554`; il 22 ottobre home e lista vuota sono state aperte sull'AVD 16 KB. | Nessuna prova Android con centinaia di prodotti, foto grandi o accessibilità fisica/TalkBack. |
| Barcode e OCR | Test di fallback manuale, permesso negato, rete/errori/risposte tardive, interpretazioni data e conferma obbligatoria; il percorso scanner negato/manuale fu riprovato sul candidato finale il 20 ottobre. | Scansione e OCR con fotocamera fisica non verificati. Una data di produzione richiede comunque distinzione umana da una scadenza. |
| Fotografie e backup | Test di storage, file parziale, EXIF/OCR temporanei, backup ZIP con e senza foto, limiti, traversal, preview, merge/replace e rollback. Sul 4 KB: ZIP senza foto, anteprima, Unisci e Sostituisci riusciti con un record dimostrativo il 20 ottobre. | Selettori, orientamento e backup con foto su dispositivo reale, interruzione brusca e ripristino Play non verificati. |
| CSV | Test di BOM UTF-8, `;`, date, quoting, multilinea e neutralizzazione formule; esportazione Android dimostrativa riuscita il 20 ottobre. | Apertura effettiva con Microsoft Excel e Fogli Google non eseguita. |
| Notifiche | Test del pianificatore e dei permessi. Ricezione reale in background su 4 KB del candidato intermedio 14 il 20 ottobre; codice notifiche invariato nell'AAB finale. | Tap verso il prodotto, reboot, Doze, cambio fuso e precisione dell'orario non certificati. Android può ritardare la consegna. |

I test Flutter verificano logica e widget; non sostituiscono sensori, servizi Android o una release distribuita tramite Play.

## E. Prestazioni e ANR

Senza compilazioni contemporanee, tre cicli `adb shell am force-stop` + `am start -W` su `emulator-5554` (app release derivata dal bundle) hanno dato `TotalTime` a freddo **10.633, 3.747 e 4.022 ms**; due ritorni HOT hanno dato **549 e 579 ms**. Il terzo ritorno ha `LaunchState: UNKNOWN`, `WaitTime: 1.568 ms`, quindi non è conteggiato come HOT. Il 20 ottobre erano già stati osservati avvii con timeout/oltre 11 s e 252/76 frame saltati. Sull'AVD 16 KB la prima apertura è durata 6.890 ms e il processo FreshTrack ha segnalato 77 frame saltati.

Gli eventi `am_anr` letti da entrambi gli emulatori includono System UI, Google Play Services, Chrome, Permission Controller e altri processi; nel buffer esaminato non compare FreshTrack. La schermata iniziale sul 16 KB ha mostrato il dialogo “System UI isn't responding”; scegliendo “Wait”, l'app è rimasta attiva e la navigazione ha funzionato. La simultanea instabilità di più processi è **indizio**, non prova conclusiva, di un problema ambientale. Nessuna ottimizzazione speculativa è stata apportata. Serve profiling senza ANR di sistema su uno smartphone fisico, con tracciato temporale app/Android se il ritardo si ripete.

## F. Privacy pubblica

`PRIVACY_POLICY.md`, `docs/privacy-site/index.html` e la schermata integrata in app sono datati 20 ottobre, in italiano e inglese. Descrivono inventario/foto/date/preferenze locali, ZIP/CSV, assenza di account e backend personale, lookup volontario nei quattro cataloghi Open Facts, IP/User-Agent, ML Kit, auto zoom, permessi e cancellazione. La [guida ufficiale ML Kit](https://developers.google.com/ml-kit/android-data-disclosure) conferma anche ID di sessione, variazioni zoom e coordinate del possibile codice. All'inizio la pagina [pubblica](https://kaonashi98.github.io/FreshTrack/) era ancora datata 7 ottobre; prova in `build/audit-2026-10-22/privacy-live-2026-10-22.html`, SHA-256 `2fc335d6724c3e00bf3f2a131693bc71fe6fb3d313e479c32889e0700aba36e5`.

La pubblicazione è configurata da `.github/workflows/github_pages.yml`: il push autorizzato su `main` ha caricato solo `docs/privacy-site/`. Staging verificato con **un unico file** e `git diff --cached --check` exit 0; nessun pattern comune di chiavi/token nell'HTML, favicon invariata. Dopo il workflow riuscito, il 22 ottobre la pagina pubblica ha HTTP 200, data 20 ottobre sia IT sia EN, `Open Products Facts` e i due paragrafi auto zoom; la data 7 ottobre è assente. Copia in `build/audit-2026-10-22/privacy-live-after-deploy.html`, SHA-256 `dec189266b6e9db756fac0517efc3d54b182c022b4d2f8f19c6bc259315fb259`. Il testo online coincide con il file locale; i byte differiscono solo per la normalizzazione CRLF→LF di Git. **Privacy pubblica AGGIORNATA e verificata.**

## G. Compatibilità Android

- Package `io.github.kaonashi98.freshtrack`; minSdk **24**, targetSdk e compileSdk **36**. Il [requisito Play per nuove app/aggiornamenti](https://support.google.com/googleplay/android-developer/answer/11926878) richiede API 36 dal 31 agosto 2026.
- Manifest release del 20 ottobre: CAMERA, INTERNET, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE e SCHEDULE_EXACT_ALARM facoltativo; nessun AD_ID, storage generico o USE_EXACT_ALARM. `allowBackup=false`, traffico in chiaro disabilitato. R8/resource shrinking della build precedente; Lint release corrente senza issue. ProGuard esistente invariato.
- Bundletool: `PAGE_ALIGNMENT_16K`; APK derivato già verificato con `zipalign -c -P 16`; 18 librerie ELF a 64 bit con LOAD adeguati, come registrato nell'audit precedente. Questa è prova **statica**.
- **Nuova prova runtime 16 KB:** `adb -s emulator-5556 shell getconf PAGE_SIZE` = `16384`; API 37 x86_64; installazione dell'APK non debuggable derivato dallo stesso AAB, avvio e navigazione home → prodotti riusciti, processo vivo. Screenshot `build/audit-2026-10-22/freshtrack-16k-home.png` e `freshtrack-16k-products.png`. L'APK QA usa firma debug per installazione locale, non la firma Play. L'ANR di System UI limita la conclusione di stabilità. Runtime ARM64 16 KB, Android minSdk 24 e dispositivo fisico restano non verificati.

## H. Test automatici e sicurezza

| Comando eseguito il 22 ottobre | Esito |
| --- | --- |
| `dart.exe flutter_tools.snapshot pub get` | PASS, dipendenze risolte; nessun aggiornamento indiscriminato. |
| `dart.exe format --output=none --set-exit-if-changed lib test` | PASS, 86 file, 0 modificati. |
| `dart.exe flutter_tools.snapshot analyze --no-pub` | PASS dopo versione `+14`, `No issues found!`, 64,2 s. Log in `build/audit-2026-10-22/analyze-final.log`. |
| `dart.exe flutter_tools.snapshot test --coverage --no-pub -v` | PASS dopo versione `+14`, **215 test**; `coverage/lcov.info`: **4.089/5.412 = 75,55%**. Log in `build/audit-2026-10-22/test-final.log`. |
| `android/gradlew.bat :app:lintRelease` | PASS anche dopo la sincronizzazione di versione: `BUILD SUCCESSFUL in 2m 57s`, 38 task eseguiti e 398 aggiornati. `build/app/reports/lint-results-release.txt`: `No issues found.`; 0 issue XML. Log `build/audit-2026-10-22/lint-final.log`. |

Il lock delle dipendenze è stato mantenuto. La configurazione `.github/workflows/flutter_ci.yml` prevede Flutter 3.44.6, pub get, format, analyze, test, lint e APK debug; le modifiche locali del candidato non sono sul remoto, quindi nessuna esecuzione GitHub Actions può validarle. Il push privacy ha avviato [CI #39771993347](https://github.com/Kaonashi98/FreshTrack/actions/runs/39771993347): **failure, 196 test passati e 1 fallito**. Nel checkout remoto il test `global_release_content_test.dart` si aspettava ancora “October 7, 2026” mentre l'HTML pubblicato dice correttamente “October 20, 2026”; lint e APK debug remoti sono stati saltati. La patch minima di due date in `build/audit-2026-10-22/ci-privacy-test-minimal.patch` è stata verificata con `git apply --check --cached`, committata da sola come `f68af6a` e inviata dopo autorizzazione. La nuova [CI #39772634254](https://github.com/Kaonashi98/FreshTrack/actions/runs/39772634254) è terminata con **success**. La suite locale risincronizzata a `+14` è passata ancora (215/215); la CI remota verde riguarda solo i file committati. Il controllo dei pattern comuni di chiavi/token in `lib`, `android`, `docs` e `.github` non ha trovato corrispondenze nei file inclusi; non è un audit di segreti esaustivo. Le verifiche ZIP/migrazione/concorrenza del 20 ottobre restano applicabili perché la logica del candidato è invariata.

## I. Bundle

| Proprietà | Verifica |
| --- | --- |
| AAB | `build/app/outputs/bundle/release/app-release.aab`, 92.223.539 byte. La build release del 22 ottobre è riuscita con sorgente `+14`; Gradle ha marcato `:app:packageReleaseBundle`, `:app:signReleaseBundle` e `:app:bundleRelease` `UP-TO-DATE`, quindi l'AAB è rimasto identico a quello conservato del 20 ottobre. Non si attribuisce una nuova compilazione di byte a questa esecuzione. |
| Versione / package | `1.0.1` / versionCode **14**, allineato a `pubspec.yaml` e `android/local.properties` / `io.github.kaonashi98.freshtrack`. Il proprietario conferma 14 libero in Console. |
| SHA-256 ricalcolato il 22 ottobre | `7fbc9490b98354d8677d232142fa1366974c4a5177fc97b3bcbebdaecf2a9343`, identico alla copia protettiva `build/audit-2026-10-22/pre-version-sync-1.0.1+14.aab`. |
| Firma | `jarsigner -verify` exit 0, con gli stessi warning su certificato autofirmato e ordine ZIP/JarInputStream documentati il 20 ottobre; verifica crittografica aggiuntiva delle 425 entry via JarFile già conservata in `build/audit-2026-10-20/`. Certificato SHA-256 `6832bdc0f1ae2876827fabfee57ae65ded344902e7b004cb0e06574c5348477c`. Corrispondenza alla upload key Console non verificata. |
| Struttura | `bundletool 1.18.3 validate` exit 0 dopo la build; manifest estratto: min 24/target 36/compile 36, versionCode 14. Firma `jarsigner -verify` exit 0. Allineamento/ELF e installazione locale 16 KB del 22 ottobre valgono esattamente per lo stesso hash AAB. |

Il precedente AAB del 7 ottobre rimane identificabile in `build/audit-2026-10-20/previous-app-release.aab`. Il candidato selezionato è l'AAB `1.0.1 (14)` con SHA-256 sopra: sorgente, versione manifest, firma e prova emulata 16 KB ora corrispondono. Non è stato caricato in Play Console.

## J. Google Play

Le bozze IT/EN in `docs/play_store_listing_it.md`, `docs/play_store_listing_en.md` e `docs/play_console_handoff.md` non promettono cloud/famiglia/barcode universali. In `docs/play-store/candidate-2026-10-20/` ci sono 8 PNG italiani e 8 inglesi, tutti 1080×2400: i 16 hash del manifest corrispondono e puntano all'AAB del 20 ottobre, che è **identico per SHA-256** al candidato rimasto dopo la build del 22 ottobre. Icona 512×512 e feature graphic 1024×500 hanno le dimensioni attese. Il set era stato ispezionato visivamente il 20 ottobre e non è stato rigenerato. Le composizioni storiche `screenshots-benefits*` non sono asset del candidato attuale. La selezione effettiva nella Console non è visibile qui.

Checklist Console da confrontare con i campi correnti prima dell'invio: Data Safety (ML Kit e auto zoom, Open Facts, esportazioni avviate dall'utente); dichiarazione salute dopo rimozione della vecchia categoria Farmaci in **tutti** i canali; CAMERA/notifiche/allarmi; accesso senza account; pubblico non infantile e classificazione; schede IT/EN e asset correnti; URL privacy ora aggiornato; paesi/territori supportati selezionati; upload key; Pre-launch Report, catalogo dispositivi e Android Vitals. Stato di questi campi: **NON VERIFICATO IN CONSOLE**. Il proprietario ha verificato e riferisce l'**accesso alla produzione approvato**, una release `1.0.1 (13) - Alpha`, `13` massimo in tutti i canali e `14` mai caricato; sono dati dichiarati dal proprietario, non osservati direttamente qui. L'audit tecnico non viene attribuito al feedback dei tester e l'approvazione dell'accesso non approva una release specifica. [Guida ufficiale al test chiuso](https://support.google.com/googleplay/android-developer/answer/14151465).

## K. Verifiche manuali necessarie

1. In Play Console verificare la upload key e confrontare Data Safety, salute, pubblico, paesi, schede, Pre-launch Report e Vitals con l'app e la pagina pubblica. Il proprietario ha già confermato l'accesso produzione e che `14` è libero; prima di un eventuale caricamento, ricontrollare che nessun altro upload lo abbia occupato.
2. Su uno smartphone fisico con dati dimostrativi protetti: installazione/aggiornamento via Play, apertura e fluidità, scansione reale trovato/non trovato/offline, OCR/foto orientate e grandi, backup ZIP **con foto** Unisci/Sostituisci, dati preservati e CSV aperto in Excel/Fogli Google.
3. Sullo stesso telefono: notifica in background, tap alla scheda corretta, permesso negato/revocato, reboot, orario/preavviso e cambio fuso; acquisire log/traccia se avvio o scrolling restano lenti. Verificare un inventario di dimensioni realistiche e TalkBack.
4. Prima di qualunque rilascio, allineare la selezione degli asset in Console al candidato, confrontare le 16 catture con la release finale e ottenere un'autorizzazione distinta per caricamento AAB e pubblicazione.

## L. Verdetto

| Ambito | Verdetto |
| --- | --- |
| Codice locale | **PRONTO** per i controlli di codice eseguiti; non è una certificazione del dispositivo. |
| Prestazioni | **NON VERIFICATE** su hardware; rallentamenti emulati e System UI instabile ancora aperti. |
| Collaudo fisico | **NON VERIFICATO**. |
| Compatibilità | **NON VERIFICATA** complessivamente; prova statica e avvio/navigazione x86_64 a 16 KB riusciti, minSdk/ARM64/hardware mancanti. |
| Privacy pubblica | **AGGIORNATA** e riletta online in IT/EN. |
| Bundle definitivo | **PRONTO** come artefatto locale `1.0.1 (14)`: sorgente e manifest coerenti, firma/struttura/hash verificati, prova x86_64 16 KB eseguita. Upload key Play e installazione da Play non verificate. |
| Idoneità richiesta accesso produzione | **NO-GO** secondo questo gate tecnico ancora incompleto. L'accesso risulta già **approvato secondo il proprietario**, non verificato direttamente nella Console; l'approvazione non certifica questa release. |
| Pubblicazione mondiale | **NO-GO**. |

### RISPOSTA ALLA DOMANDA DI GOOGLE PLAY CONSOLE

**NON INCOLLARE ANCORA.** L'accesso alla produzione risulta già approvato secondo il proprietario. Per una futura risposta sulla release mancano verifica della upload key, collaudo fisico di funzioni e notifiche, e confronto delle dichiarazioni/asset in Console. (258 caratteri, spazi inclusi.)
