# Scheda Google Play — Italiano (it-IT)

## Nome

FreshTrack

## Descrizione breve

Organizza dispensa e cura personale, ricorda le scadenze e riduci gli sprechi.

## Descrizione completa

FreshTrack è l’app semplice e privata che ti aiuta a tenere sotto controllo
alimenti, bevande e prodotti per la cura personale, ricordando cosa
usare o consumare prima.

Registra un prodotto partendo da nome e scadenza. Puoi riutilizzare i prodotti
già inseriti, duplicarli, aggiungerne più di uno di seguito oppure scansionare
il barcode. La dashboard mette in evidenza le priorità, mentre ricerca, filtri
e ordinamento rendono immediato trovare ciò che serve.

Funzioni principali:

- gestione offline di alimenti, bevande e prodotti personali;
- promemoria locali nel giorno della scadenza e, se lo imposti, nei giorni
  precedenti (verso l’orario scelto; Android può ritardarli, ma FreshTrack li
  recupera all’apertura e può usare allarmi più puntuali se li consenti);
- foto da fotocamera o galleria;
- scansione barcode con zoom, torcia, foto o codice inserito a mano, ricerca
  opzionale su Open Food Facts e inserimento sempre disponibile;
- lettura sul dispositivo della scadenza da una foto ravvicinata, con conferma
  obbligatoria;
- backup completo di prodotti, preferenze e foto, con salvataggio, condivisione
  verso un altro telefono e anteprima prima del ripristino;
- esportazione CSV per Excel e Fogli Google;
- categorie dedicate ad alimenti, bevande e cura personale;
- stato consumato, utilizzato o buttato con possibilità di ripristino;
- ricerca, categorie e ordinamento per scadenza;
- tema chiaro, scuro o di sistema;
- lingua italiana o inglese, selezionata automaticamente dal telefono o
  manualmente dalle Impostazioni.

Privacy prima di tutto: FreshTrack non richiede un account, non contiene
pubblicità e non invia allo sviluppatore inventario, foto o scadenze. Una
ricerca barcode avviata dall'utente invia il codice cercato a Open Food Facts.
Il riconoscimento del testo avviene sul dispositivo; gli SDK Google ML Kit
possono trasmettere informazioni tecniche e diagnostiche, ma non il contenuto
delle immagini o dell'inventario.

FreshTrack è pensata per un telefono in casa. Non c’è un elenco famiglia né un
account cloud: per copiare l’inventario su un altro dispositivo usa Condividi
backup, poi Ripristina sull’altro telefono.

## Note di rilascio 1.0.1 (build 13)

FreshTrack ora si concentra su dispensa, bevande e prodotti per la cura
personale. I prodotti e i backup esistenti restano disponibili. Sono inclusi
promemoria, scanner barcode, backup e interfaccia italiana/inglese.

## Risorse Play Console

- URL privacy HTTPS:
  https://kaonashi98.github.io/FreshTrack/
- email di assistenza: freshtrack.help@outlook.com
- icona `docs/play-store/play-store-icon-512.png`
- feature graphic `docs/play-store/feature-graphic-1024x500.png`
- screenshot telefono: `docs/play-store/screenshots-benefits/`

## Data Safety

- Inventario, fotografie, date e preferenze sono conservati localmente e non
  vengono inviati allo sviluppatore.
- La ricerca barcode, soltanto su iniziativa dell'utente, trasmette a Open Food
  Facts tramite HTTPS il codice cercato e i normali dati tecnici di rete. Non
  trasmette foto, date o l'intero inventario.
- Open Food Facts è usato tramite API v3.6. I dati prodotto provengono dal
  database collaborativo Open Food Facts e sono soggetti a licenza ODbL;
  l'attribuzione è visibile nella schermata «Privacy e informazioni».
- Google ML Kit può raccogliere tramite HTTPS informazioni su dispositivo e
  app, identificatori per installazione, metriche delle prestazioni,
  configurazione API, eventi e codici di errore. Indicare le categorie e le
  finalità applicabili per diagnostica e analisi dell'utilizzo; le immagini e il
  testo riconosciuto sono elaborati sul dispositivo.
- Copiare le risposte dettagliate e le cautele riportate in
  `docs/play_console_handoff.md`, verificando i nomi dei campi mostrati dalla
  Console prima dell'invio.
- Dichiarare i permessi Notifiche e Fotocamera come usati in-app. La fotocamera
  serve per barcode, foto prodotto e foto OCR; è disponibile anche il selettore
  di sistema per le immagini.
- Pubblico di riferimento: non progettata per i bambini.
- Categoria: Produttività. Nessuna pubblicità.
- Dichiarazione app per la salute: selezionare «La mia app non ha funzionalità relative alla salute» soltanto dopo aver sostituito la vecchia release in tutti i canali di test.
