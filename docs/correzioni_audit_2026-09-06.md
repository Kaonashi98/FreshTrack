# FreshTrack — resoconto delle correzioni del 6 settembre 2026

I 15 difetti riprodotti nell'audit sono stati corretti e i relativi scenari
sono ora inclusi nella suite del progetto. Durante la build finale è stato
individuato e corretto anche un blocco R8 relativo alle dipendenze OCR.
Questa evidenza chiude i problemi identificati nel codice; non costituisce
una garanzia di assenza di qualsiasi altro difetto né un'approvazione Play.

## Candidato e provenienza

- Versione: **1.0.0+4**, package `io.github.kaonashi98.freshtrack`.
- Branch `main`, HEAD `a9490bbd05f5ee25721e540d986c0c30c30d7a8e`.
- Il working tree conteneva già numerose modifiche, conservate. Il candidato
  deriva dai file locali, non dal solo HEAD. Nessun commit, push o deploy.
- Una copia dei file precedenti alle correzioni è conservata in
  `C:\Users\dutch\AppData\Local\Temp\freshtrack-before-fixes-20260906`.
- Gli input principali della build sono registrati con SHA-256 in
  `build/release-audit/source-manifest.json`. Impronta del documento
  normalizzato: `7ed46c6a915ea753b1f467e3cdd14eaa462885bd9f48d98d9fd1887e45095b40`.
  Il controllo successivo alla compilazione non ha trovato modifiche a tali input.

## Chiusura dei 15 difetti

| # | Problema riprodotto | Correzione e verifica |
| --- | --- | --- |
| 1 | Backup esportato ma non reimportabile | Limiti simmetrici, manifest fino a 32 MB entro il massimo totale di 250 MB. Regressione con inventario voluminoso. |
| 2 | Scritture perse durante il ripristino | Lock condiviso da repository, form, importazione e cancellazione; snapshot e sostituzione coordinati. Test di concorrenza e verifica del repository SQLite reale. |
| 3 | Unisci sovrascrive il prodotto più recente | Conflitti risolti tramite `updatedAt`: vince la versione più recente, a parità resta quella attuale. La conferma spiega la regola. |
| 4 | Quantità arrotondata modificando solo il nome | Precisione conservata nel form, nei suggerimenti e nelle esportazioni; regressione con 0,25. |
| 5 | Prodotto in scadenza oggi rifiutato | Confronto delle date civili senza confronto dell'ora di acquisto. |
| 6 | Doppio tocco su Salva crea duplicati | Guard all'ingresso e pulsante protetto fino al completamento dell'intera operazione, incluse notifiche e consenso. |
| 7 | Quantità invalida quando Altri dettagli è chiuso | Validazione di dominio prima di ogni scrittura, indipendente dai campi montati; controllo anche nel repository e nei backup. |
| 8 | Barcode tardivo sovrascrive il prodotto successivo | Risultati legati alla generazione del form; reset/salvataggio invalidano le richieste precedenti e i campi modificati manualmente sono protetti. |
| 9 | Sincronizzazioni lasciano promemoria obsoleti | Un unico servizio legge lo stato corrente e lo scheduler serializza l'intera sincronizzazione. |
| 10 | Notifiche cancellate prima del caricamento iniziale | Il coordinatore distingue inventario vuoto da inventario non ancora caricato. |
| 11 | Primo errore notifiche impedisce ogni tentativo successivo | Inizializzazione fallita liberata, con tentativi successivi consentiti. |
| 12 | Preferenze concorrenti si annullano | Trasformazioni serializzate sullo stato persistito più recente; salvataggio atomico di un singolo documento e compatibilità con i vecchi valori. |
| 13 | Cancellazione incompleta uscendo dalla schermata | Operazione spostata in un servizio con dipendenze già acquisite, che completa il lavoro oltre la vita della pagina. |
| 14 | Tutte le categorie non azzera il filtro | Valore esplicito del menu distinto dall'annullamento. |
| 15 | CSV usa Consumato per i farmaci | Etichettatura di stato condivisa con l'interfaccia: Utilizzato per i prodotti non alimentari. |

## Ulteriori interventi

- **Backup:** ZIP/JSON elaborati fuori dal thread dell'interfaccia; compressione
  delle foto una alla volta. Limite applicato durante la decompressione effettiva,
  rifiuto di duplicati, link simbolici, cifratura, intestazioni incoerenti e foto
  mancanti. Test con dimensioni dichiarate false. Pulizia dei file temporanei e
  protezione delle immagini ancora referenziate se il rollback fallisce.
- **Dati e preferenze:** limite totale dei prodotti rispettato anche nel merge;
  incrementi rapidi del preavviso preservati; dettaglio prodotto aggiornato dalle
  variazioni del repository. Nessuna modifica manuale dell'inventario dell'utente.
- **Flussi asincroni:** salvataggio, aggiornamento stato e operazioni sui dati
  acquisiscono le dipendenze prima delle attese; risposte OCR obsolete invalidate.
- **Notifiche:** nuova sincronizzazione dopo il primo consenso; indicatori delle
  scadenze aggiornati a mezzanotte e alla ripresa dopo una sospensione.
- **Interfaccia e CSV:** gestione degli errori della torcia e dell'arresto della
  fotocamera, feedback sugli errori delle preferenze, protezione dalle formule
  anche quando precedute da spazi. Verifica di cinque schermate Impostazioni a
  320×568 con scala testo 200%.
- **Build Android:** `google_mlkit_text_recognition` riferisce quattro alfabeti
  opzionali tramite dipendenze `compileOnly`. FreshTrack seleziona solo il latino.
  Aggiunte otto regole `-dontwarn` specifiche per quelle classi assenti, senza
  disattivare R8 o sopprimere globalmente gli errori di classi mancanti.
- **Documentazione:** README, changelog e checklist aggiornati; versione portata
  dalla build 3 alla build 4 per distinguere il nuovo candidato.

## Verifiche automatiche

| Controllo | Risultato |
| --- | --- |
| Formattazione Dart | Sorgenti e test formattati |
| `flutter analyze --no-pub` | Nessun problema |
| `flutter test --coverage --no-pub` | **164/164 test superati**, prima 135 |
| Copertura linee | **2962/3972 = 74,57%**, prima 71,91% |
| `git diff --check` | Nessun errore di spaziatura |
| `:app:lintRelease --offline` | Riuscito, report rigenerato: No issues found |
| Build AAB release | Riuscita, `1.0.0+4` |
| Build APK release | Riuscita, `1.0.0+4` |
| Bundletool validate | Riuscito |
| Firma AAB | `jarsigner`: `jar verified`, con avvisi descritti sotto |
| Firma APK | `apksigner verify`: riuscito, firma v2 con upload key |
| Allineamento APK | `zipalign -c -P 16 -v 4`: riuscito |
| Manifest del bundle | Min SDK 24, target/compile SDK 36, versionCode 4 |
| Pagine da 16 KB, controllo statico | `PAGE_ALIGNMENT_16K`; tutte le 18 librerie arm64-v8a/x86_64 con allineamento LOAD di almeno 16 KB |

Le prove che simulano plugin, errori e concorrenza controllano la logica dell'app.
Non sostituiscono i test di fotocamera, OCR, consegna notifiche e filesystem su
Android reale. La copertura complessiva non indica copertura completa dei wrapper
hardware.

## Artefatti generati

La successiva revisione [UI/UX build 5](ui_ux_2026-09-06.md) ha aggiornato il
percorso dell'APK principale. L'APK build 4 descritto qui è ora conservato in
`build/ui-ux-review/app-release-v4.apk`; le impronte seguenti restano riferite
alla build 4. L'AAB build 4 è conservato in
`build/ui-redesign-v6/app-release-v4.aab`. I percorsi principali ora contengono
gli artefatti della [build 6](ui_redesign_2026-09-07.md).

- AAB build 4: `build/ui-redesign-v6/app-release-v4.aab`.
  SHA-256: `3f93a06a7d0c0c226671df5cac754cacfe7f2475b2760a224786160229befc0c`.
- APK build 4: `build/ui-ux-review/app-release-v4.apk`.
  SHA-256: `75aa8840dcdc73517fba5262a696d20c17f6e5e2cff44349d96328e4c6030a04`.
- Certificato upload SHA-256:
  `6832bdc0f1ae2876827fabfee57ae65ded344902e7b004cb0e06574c5348477c`.

L'emulatore Pixel_8 API 35 usa pagine da 4 KB e aveva la build 3 firmata con la
chiave Android Debug. Il tentativo di aggiornamento con l'APK upload è stato
rifiutato per firma diversa, prima di modificare i dati. Per la prova del codice
release è stata preparata una copia QA con la chiave di sviluppo corrispondente:
`build/release-audit/freshtrack-qa-release-debugsigned.apk`. Questa copia è solo
per i test locali e non è un artefatto da caricare su Play.

L'aggiornamento QA alla build 4 è riuscito e la dashboard ha caricato l'inventario
esistente. Le 324 voci del payload della copia QA sono identiche a quelle
dell'APK release, escludendo i metadati di firma. Il primo comando di avvio ha
superato il tempo di attesa mentre l'emulatore era lento; l'interfaccia è stata
poi acquisita e ispezionata correttamente. Questa prova non certifica i tempi
di avvio su dispositivi reali.

Il tentativo OCR con una foto di test non è conclusivo: durante l'apertura del
selettore, l'emulatore condiviso è passato a WeatherApp e l'acquisizione UI ha
restituito una radice nulla. Le interazioni sono state interrotte per evitare
interferenze; nessun prodotto di test è stato salvato. Non viene dichiarato
superato il test del riconoscitore nativo. Restano necessarie una sessione
dedicata e prove con immagini/camera reali.

## Limiti e verifiche esterne

- Pubblicare e ricontrollare l'informativa già aggiornata localmente: durante
  l'audit la pagina pubblica presentava ancora il testo precedente.
- Completare Data Safety e dichiarazioni Play Console sugli SDK effettivi;
  verificare la corrispondenza dell'upload key con la Console.
- Eseguire installazione pulita, aggiornamento, fotocamera/barcode/OCR, notifiche
  a schermo spento e dopo riavvio, backup dopo reinstallazione e test su Android
  con pagine da 16 KB. L'allineamento statico non prova l'esecuzione su quel sistema.
- Misurare memoria e reattività dei backup massimi su un dispositivo reale.
  I test di rollback simulano errori; non certificano atomicità rispetto alla
  chiusura forzata del processo, spegnimento o esaurimento dello spazio Android.
- Riacquisire gli screenshot finali e completare test richiesti all'account,
  Pre-launch report e controlli di distribuzione. La CI remota non è stata eseguita.
- Il verificatore Java segnala certificato autofirmato, assenza di timestamp,
  attributi ZIP non coperti dalla firma e differenze di lettura JarInputStream
  dovute al manifest non iniziale. La firma via JarFile e Bundletool risultano
  verificati; la validazione della Console resta distinta.
- La build segnala una futura migrazione del Kotlin Gradle Plugin usato da
  `mobile_scanner` e avvisi di accesso nativo Java. Non hanno bloccato la build
  con gli strumenti attuali; sono da ricontrollare aggiornando Flutter/Gradle.

Log e manifest delle verifiche locali sono in `build/release-audit/`, cartella
esclusa da Git. Il vecchio AAB è stato conservato come
`build/release-audit/previous-app-release.aab`, evitando di confonderlo con il
candidato corretto.
