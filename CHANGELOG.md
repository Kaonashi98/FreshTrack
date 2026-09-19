# Changelog

Tutte le modifiche rilevanti di FreshTrack sono documentate in questo file.

## [1.0.0] - In preparazione

### Candidato globale bilingue, build 11 — 15 settembre 2026

- Interfaccia completa in italiano e inglese: italiano quando la lingua primaria
  del dispositivo è italiana, inglese per tutti gli altri sistemi; scelta
  manuale Sistema, Italiano o English persistente nelle Impostazioni.
- Localizzati anche notifiche, date, accessibilità, categorie, messaggi di
  errore, backup, CSV e risultati Open Food Facts.
- Informative privacy italiana e inglese allineate alle funzioni correnti;
  preparati scheda Store inglese e handoff delle dichiarazioni Play Console.
- Aggiornato `mobile_scanner` alla versione 7.4.2 per le correzioni Android a
  fotocamera, analizzatore barcode, ProGuard e compatibilità Kotlin integrata.

### Colori più vivaci e home leggibile, build 10 — 8 settembre 2026

- Sostituiti i toni petrolio con azzurro per le azioni e verde per gli stati
  senza scadenze; tema scuro blu più luminoso, testi secondari più chiari,
  bordi e barra di navigazione più visibili.
- I messaggi della home vuota sono ora schede colorate con icone riconoscibili,
  titoli da 16 e descrizioni da 14 punti. Contenuto in alto e impostazioni
  nell’angolo superiore destro.
- Temi chiaro/scuro coordinati in tutta l’app. Suite completa: 178 test superati,
  comprese le prove con testo al 200% e sugli schermi piccoli.
- Analisi pulita, APK/AAB release `1.0.0+10` firmati e verificati; home, tastiera,
  cambio tema e riavvio collaudati sul Pixel con copia del contenuto release firmata QA.
- [Resoconto e schermate della revisione](docs/ui_leggibilita_build10_2026-09-08.md).

### Palette Grafite e petrolio, build 9 — 8 settembre 2026

- Sostituita la palette Iris con sfondi neutri e azioni petrolio nei temi chiaro
  e scuro; coordinati anche menu, selettori, messaggi e sfondo di avvio Android.
- Icone delle categorie uniformate su superfici neutre; ambra per la scadenza
  di oggi e rosso per i prodotti scaduti.
- Superfici Material calibrate per la leggibilità dei testi secondari:
  50 combinazioni di contrasto verificate, tutte almeno 4,5:1.
- Conservati disposizione compatta, testata senza marchio e impostazioni in alto
  a destra. Suite completa: 178 test superati.
- Analisi pulita, APK/AAB release `1.0.0+9` firmati e validati; verificati temi,
  tastiera, calendario, menu e riavvio sul Pixel con una copia del contenuto release
  firmata QA per mantenere i dati esistenti.
- Anteprime e verifiche nel [resoconto della palette](docs/ui_petrolio_build9_2026-09-08.md).

### Stile Iris e percorsi semplificati, build 8 — 8 settembre 2026

- Applicato il design approvato: palette Iris, superfici compatte, DM Sans
  incluso offline e temi chiaro/scuro coordinati.
- Rimossi logo e nome dalla testata: data e titolo occupano lo spazio liberato,
  con le impostazioni in alto a destra, accessibili anche durante caricamento o errore.
- Home divisa tra scadenze di oggi e prossimi giorni; azione consumato/utilizzato
  con annullamento protetto da modifiche successive e sincronizzazione dei promemoria.
- Navigazione Oggi / Aggiungi / Prodotti; scelta tra scansione e inserimento manuale,
  modulo senza sezioni numerate e filtri rapidi per scadenze, scaduti e archivio.
- Corretto il pulsante Aggiungi che poteva restare bloccato dopo il primo
  salvataggio; verificata la riapertura anche dopo Indietro.
- 178 test superati, inclusi gli stati di caricamento/errore;
  analisi pulita e APK/AAB firmati `1.0.0+8`.
- Dettagli ed evidenze nel [resoconto del redesign](docs/ui_iris_build8_2026-09-08.md).

### Collaudo Pixel 8 e correzioni build 7 — 7 settembre 2026

- Corretto il salvataggio delle foto Android quando la ricompressione cambia
  il formato ma conserva l'estensione originale.
- Azione Aggiungi nascosta con tastiera aperta, per lasciare accessibile la ricerca.
- CSV con stato Scaduto coerente con la data corrente; quantità esatta anche
  nelle priorità della dashboard.
- Conferme scorrevoli per evitare sovrapposizioni con testo al 200% e in orizzontale.
- Otto regressioni aggiunte: suite completa 176/176, analisi statica pulita.
- Prove reali di inventario, immagini, OCR, notifiche, CSV e backup sul Pixel;
  evidenze e limiti nel [resoconto del collaudo](docs/emulator_qa_build7_2026-09-07.md).

### Ridisegno UI e UX build 6 — 7 settembre 2026

- Nuova palette verde bosco, avorio e lime, tema scuro coordinato e
  navigazione sospesa con azione Aggiungi compatta quando il testo è grande.
- Dashboard con riepilogo delle scadenze in primo piano, calendario, due
  indicatori separati e priorità presentate come righe aperte.
- Elenco prodotti riprogettato con giorno, mese e anno della scadenza in
  evidenza; inserimento suddiviso in tre sezioni numerate.
- Nuovo calendario nel dettaglio prodotto, impostazioni divise in gruppi e
  intestazioni/campi adattati al testo al 200%.
- Contrasto corretto per le conferme di eliminazione e per Mostra tutti,
  verificato sui colori effettivamente renderizzati nei due temi.
- Suite completa: 168 test superati. Dopo le ultime correzioni visive:
  86 test UI e di contrasto superati. Analisi statica senza problemi.
- APK e AAB firmati `1.0.0+6`, verificati con gli strumenti Android e con
  allineamento a 16 KB. Anteprime reali e impronte nel
  [resoconto del ridisegno](docs/ui_redesign_2026-09-07.md).

### UI e UX build 5 — 6 settembre 2026

- Superfici più leggere, ombre ridotte, pulsanti coerenti e colori delle
  scadenze con maggiore contrasto in tema chiaro e scuro.
- Dashboard con data, richiamo ai prodotti scaduti e messaggi coerenti con
  l'inventario. “Mostra tutti” apre tutte le scadenze vicine.
- Schede con nome su due righe, categoria e quantità, stato distinto dalla
  data; dicitura “Disponibile” anche per prodotti non alimentari e “Domani”.
- Ricerca e categoria azzerabili insieme, anche dalla schermata senza risultati.
- Inserimento con nome e scadenza per primi, date rapide, salvataggio separato
  visivamente e disposizione compatta per schermi bassi o testo grande.
- Dettaglio senza spazio riservato a una foto assente; testo delle impostazioni
  semplificato. Navigazione e controlli adattati al testo ingrandito.
- Quattro regressioni aggiunte per azzeramento filtri, contesto delle scadenze,
  richiamo agli scaduti e salvataggio delle date rapide. Anteprime generate dai
  widget reali con dati dimostrativi.
- Suite completa: 168/168 test superati, copertura linee 75,41%; analisi statica
  pulita e verifiche responsive aggiuntive completate.
- Versione portata a `1.0.0+5`: gli artefatti della build 4 non includono queste
  modifiche. Il bundle Play va rigenerato prima della pubblicazione.

### Correzioni build 4 — 6 settembre 2026

- Risolti i 15 difetti riprodotti nell'audit: scadenza di oggi, precisione delle
  quantità, validazione dei dettagli chiusi, salvataggi duplicati, risposte
  barcode tardive, reset categorie, terminologia CSV, concorrenza delle
  preferenze, cancellazione dopo la navigazione, backup e notifiche.
- Il ripristino Unisci conserva la versione più recente di ogni prodotto; a
  parità di data mantiene quella attuale. Le scritture concorrenti attendono
  il completamento del trasferimento.
- Limiti di esportazione e importazione coerenti, manifest fino a 32 MB entro
  il limite complessivo di 250 MB, compressione delle foto una alla volta e
  lavoro ZIP/JSON fuori dal thread dell'interfaccia.
- Rifiuto di backup con foto mancanti, contenuti ZIP duplicati o dimensioni
  dichiarate false; protezione delle foto quando il rollback non riesce.
- Preferenze salvate in un singolo documento, mantenendo la lettura del formato
  precedente; incremento rapido del preavviso senza perdere tocchi.
- Promemoria serializzati, inizializzazione ritentabile e riallineamento dopo
  il primo consenso alle notifiche.
- Indicatori delle scadenze aggiornati a mezzanotte e al ritorno nell'app.
- Dettagli prodotto aggiornati dalle modifiche del repository, gestione degli
  errori della torcia e protezione CSV anche con spazi prima di una formula.
- Risolto il blocco della build release R8 causato dai riconoscitori ML Kit
  opzionali non inclusi: esclusioni puntuali per i quattro alfabeti inutilizzati,
  mantenendo attive ottimizzazione e verifica delle altre classi.
- Suite ampliata da 135 a 164 test, con copertura linee dal 71,91% al 74,57%.
- Versione locale aggiornata a `1.0.0+4`. Il rilascio pubblico richiede ancora
  verifica su dispositivo, informativa pubblica aggiornata e Play Console.

### Funzionalità

- Inventario offline con persistenza Drift.
- Dashboard con scadenze entro sette giorni ordinate per urgenza.
- Creazione, modifica ed eliminazione dei prodotti.
- Foto da fotocamera e galleria, con visualizzazione a schermo intero.
- Ricerca, filtro per categoria e ordinamento.
- Notifiche locali nel giorno della scadenza, con preavviso e orario configurabili. Android può ritardare l’orario di alcuni minuti.
- Preavviso globale applicato a tutto l’inventario.
- Richiesta del permesso notifiche dopo il salvataggio di un prodotto.
- Testo dedicato e disclaimer per la categoria Farmaci.
- Apertura dei prodotti della data corretta toccando una notifica.
- Temi chiaro, scuro e di sistema.
- Cancellazione completa dei dati locali.
- Limiti e validazione rafforzata per nomi, quantità e fotografie.
- Aggiunta rapida, suggerimenti dai prodotti già usati, duplicazione e
  inserimento consecutivo di più articoli.
- Scansione barcode con ricerca facoltativa tramite Open Food Facts API v3.6 e
  compilazione manuale sempre disponibile.
- Riconoscimento sul dispositivo della data da una foto, con conferma
  obbligatoria.
- Backup ZIP completo di inventario, impostazioni e foto, con anteprima e
  ripristino per unione o sostituzione.
- Esportazione CSV compatibile con Excel e Fogli Google.
- Impostazioni suddivise per area, attribuzione Open Food Facts/ODbL e
  informativa privacy accessibile nell'app.

### Qualità

- Clean Architecture con repository pattern.
- Test di dominio, data layer e schermate principali.
- Android Lint e CI GitHub.
- Configurazione sicura della firma release.
- Esclusione esplicita dei dati da backup cloud e trasferimenti tra dispositivi.
- Percorsi delle immagini confinati alla cartella privata gestita dall’app.
- Verifica di dimensione, struttura, duplicati, riferimenti, CRC e limiti prima
  del ripristino di un backup.
- Controllo della firma reale dei file immagine, oltre alla sola estensione.
- Protezione dei valori CSV che potrebbero essere interpretati come formule.
- Informativa e bozza Data Safety allineate ai dati tecnici trasmessi da ML Kit.
- Asset Google Play riproducibili per icona e feature graphic.
- Nessuna API key o credenziale inclusa nel repository.
