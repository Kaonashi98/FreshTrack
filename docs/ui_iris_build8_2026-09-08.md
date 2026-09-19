# FreshTrack — design Iris, build 8

Data: 8 settembre 2026. Versione: `1.0.0+8`.

Aggiornamento successivo: nel [nuovo collaudo sul Pixel originale](pixel_recheck_build8_2026-09-08.md)
la schermata nera non si è ripresentata. Verificati i percorsi principali con
lo stesso APK, alla risoluzione originale e con il renderer standard.

## Richiesta applicata

Implementato nell’app Flutter lo stile del prototipo approvato. Il blocco con
logo e scritta FreshTrack è stato rimosso dalla testata: data e titolo iniziano
nello spazio liberato. Le impostazioni rimangono in alto a destra.

- Palette Iris e superfici chiare/scure coordinate, bordi discreti e schede compatte.
- DM Sans incluso nel pacchetto: nessun caricamento di font dalla rete durante
  l’uso. Licenza OFL inclusa e registrata tra le licenze dell’app.
- Home con avviso per gli scaduti, prodotti in scadenza oggi e prossimi sette
  giorni. Conservati i pannelli per consultare e rimuovere gli scaduti.
- Azione rapida Consumato/Utilizzato con Annulla. Il ripristino confronta lo stato
  effettivamente salvato, gestisce la precisione dei timestamp SQLite e non
  sovrascrive modifiche successive. Aggiorna anche i promemoria.
- Barra inferiore Oggi / Aggiungi / Prodotti, senza sovrapposizione al contenuto.
  L’accesso alle impostazioni resta disponibile anche durante caricamento/errore.
- Aggiunta con scelta tra codice a barre e inserimento manuale. Conservati OCR,
  suggerimenti, duplicazione, fotografia, quantità esatta e salvataggio ripetuto.
- Corretto il blocco del pulsante Aggiungi dopo il primo salvataggio, emerso nel
  collaudo Android e riprodotto con un test di regressione. Verificata anche la
  riapertura dopo Indietro; resta la protezione dai doppi tocchi simultanei.
- Modulo senza grandi riquadri numerati; dettagli facoltativi separati e un solo
  pulsante principale fisso. Le azioni non si sovrappongono alla tastiera.
- Ricerca con filtri rapidi Tutti / In scadenza / Scaduti / Archivio, insieme a
  categoria, ordinamento e filtro data proveniente dalle notifiche.
- Dettagli prodotto e impostazioni coordinati con il nuovo tema.

## Verifiche locali

- `flutter test --no-pub --reporter expanded`: **178/178**.
- La suite finale comprende disponibilità delle impostazioni durante
  caricamento/errore e riapertura di Aggiungi dopo salvataggio/Indietro.
- `flutter analyze --no-pub lib test`: **nessun problema**, anche sui sorgenti finali.
- Layout reali dell’app verificati da 320×568 a 915×412, testo 100/150/200%,
  con navigazione, scelta di aggiunta, modulo, dettagli e impostazioni.
- Due prove di acquisizione delle schermate Flutter finali, con font effettivi
  e dati di esempio: entrambe superate.
- APK e AAB release generati; firme APK e AAB verificate, bundletool validate
  superato, package/versionCode confermati. Font, licenza e codice `libapp.so`
  delle tre ABI coincidono tra APK e bundle.
- SHA-256 dell'APK installato su entrambi i Pixel uguale al pacchetto finale.

Evidenze operative in `build/ui-iris/`: log dei test e dell’analisi, metadati,
firme, manifest delle modifiche rispetto all’inizio di questa attività e
impronte dei pacchetti. Le copie antecedenti sono in `build/ui-iris/before/`;
i sorgenti di riserva hanno estensione `.snapshot` per non essere analizzati.
Il repository conteneva già modifiche precedenti; non è stato eseguito alcun
commit, push o rilascio pubblico.

## Schermate

Le immagini in [ui-iris-v8](screenshots/ui-iris-v8/) mostrano i widget reali
dell’app con dati di esempio; non sono schermate del prototipo HTML.

- [Home scura](screenshots/ui-iris-v8/dark-dashboard.png)
- [Home chiara](screenshots/ui-iris-v8/light-dashboard.png)
- [Prodotti](screenshots/ui-iris-v8/light-products.png)
- [Scelta di aggiunta](screenshots/ui-iris-v8/dark-products-add.png)
- [Modulo](screenshots/ui-iris-v8/dark-products-new.png)
- [Impostazioni](screenshots/ui-iris-v8/dark-settings.png)

Acquisizioni Android dall'AVD isolato, con prodotti di prova nel suo database:

- [Home chiara dopo aggiornamento](screenshots/ui-iris-v8/device-home-light.png)
- [Home dopo il secondo inserimento](screenshots/ui-iris-v8/device-final-home.png)
- [Fotocamera virtuale aperta](screenshots/ui-iris-v8/device-scanner.png)
- [Ritorno al modulo dopo annullamento](screenshots/ui-iris-v8/device-scanner-cancelled.png)

## Pacchetti

| Pacchetto | Dimensione | SHA-256 |
|---|---:|---|
| APK | 114658858 byte | `e1a918cb2f4e7508be6c5bf5fb814b4f919d534484a81eb4465c0e701bbe1609` |
| AAB | 88629173 byte | `43a64bbc6a6da227bc59cd863cf0de76e4dd1f833dbb7629686bbc50ae5c94af` |

Percorsi: `build/app/outputs/flutter-apk/app-release.apk` e
`build/app/outputs/bundle/release/app-release.aab`.
Le copie dei precedenti pacchetti build 7 sono conservate nella cartella di riserva.

## Collaudo Android e limiti

L’APK finale è stato installato come aggiornamento sul Pixel 8 esistente
(`emulator-5554`), senza cancellare i dati. Inventario iniziale vuoto.
Verificata la testata senza marchio e con impostazioni in alto a destra.

Durante la prova della tastiera si è verificato un blocco di rendering sul
Pixel esistente, con backend Impeller/OpenGLES e GPU host. È stato creato un
AVD di prova separato (Pixel, API 35, `emulator-5556`), con rendering software.
Durante il suo avvio è comparso anche un errore Android «System UI isn't
responding». La risoluzione dell’AVD isolato è stata quindi ridotta a 540×1200
con densità 210, mantenendo circa 411 dp di larghezza. In questa configurazione
la digitazione completa e la chiusura della tastiera sono state verificate.
Verificati anche scelta di inserimento manuale, data rapida Oggi, salvataggio,
rifiuto facoltativo del promemoria, ritorno alla home, azione Consumato e Annulla
sul database SQLite reale (il prodotto torna disponibile e visibile nella home).
Sull'APK finale verificati il secondo inserimento, la riapertura di Aggiungi dopo
salvataggio e Indietro, la persistenza dei dati al riavvio e del tema chiaro.
Verificati inoltre richiesta del permesso fotocamera, anteprima della camera
virtuale, annullamento dello scanner, ritorno al modulo e poi alla home. Non è
stata decodificata un'etichetta reale in questa prova.
Queste osservazioni non dimostrano, da sole, una causa unica dei blocchi.

Il Pixel esistente ha mostrato anche uno splash persistente o un'area nera,
mentre l'albero di accessibilità descriveva già la home. Un avvio diagnostico
con rendering software e Impeller disattivato non è sufficiente a dichiarare
risolto questo comportamento. Non sono state modificate le impostazioni del
renderer nel codice o nel manifest del pacchetto.
Al termine è stato chiuso soltanto l'AVD isolato FreshTrackUiQA. Il Pixel
esistente resta aperto, con APK aggiornato e inventario ancora vuoto; avvio
standard ripristinato dopo la diagnosi. I prodotti YogurtQA e PaneQA sono stati
creati soltanto nel database dell'AVD di prova, conservato in `build/ui-iris/avd/`.

Le prove approfondite di OCR, notifiche, backup/CSV della build 7 restano
documentate nel relativo resoconto; non vengono dichiarate ripetute integralmente
su questa build. Restano distinti il controllo locale e la pubblicazione:
Play Console, Pre-launch Report, Vitals, dispositivo fisico e runtime a 16 KB
non sono stati verificati da questa attività di redesign.
