# Collaudo FreshTrack build 6 sul Pixel 8

> Resoconto storico della prima sessione interrotta. Dopo la riapertura del
> Pixel il lavoro è proseguito: risultati, correzioni build 7 e stato finale
> sono nel [collaudo aggiornato](emulator_qa_build7_2026-09-07.md).

Data del collaudo: 7 settembre 2026. L'orologio dell'emulatore indicava
6 settembre 2026, fuso GMT: le aspettative sulle scadenze sono state calcolate
rispetto alla data del dispositivo.

**Esito: collaudo parziale. I flussi completati hanno funzionato, ma non è
possibile confermare che tutta l'app funzioni senza problemi.** Il Pixel ha
smesso di rispondere in modo affidabile ai comandi Android; riavvio e
riconnessione non hanno ripristinato il controllo. Nessun difetto applicativo
è stato riprodotto con certezza in questa sessione. Il blocco del dispositivo
richiede una nuova prova su un emulatore stabile o su hardware fisico.

## Dispositivo e provenienza del codice

- AVD Pixel_8, seriale `emulator-5554`, Android API 35, x86_64.
- Schermo 1080 × 2400, testo di sistema al 100%, orientamento verticale.
- Pagine di memoria da 4096 byte: questa prova non verifica l'esecuzione a 16 KB.
- Pacchetto `io.github.kaonashi98.freshtrack`, versione `1.0.0+6`.
- Il Pixel aveva una build 6 debuggable con firma Android Debug. Per mantenere
  i dati durante l'aggiornamento è stata installata una copia dell'APK release
  firmata con la stessa chiave di sviluppo.
- Confronto ZIP: tutti i **402 elementi originali** dell'APK release sono
  identici byte per byte nella copia QA. Sono stati aggiunti soltanto tre
  elementi di firma in `META-INF`; cambia inoltre il blocco di firma APK.
  Il codice nativo e Dart compilato, le risorse e il manifest sono quelli release.
- Questa è una prova del contenuto release con firma QA, non un'installazione
  da Play Store e non un collaudo del certificato Play App Signing.
- APK release originale invariato, SHA-256:
  `5f11889e8b9b3f5921f7c2164678762b69a7f47775e1ca1002875136284b5a6d`.

Il pacchetto QA e il confronto sono conservati in
`build/emulator-qa-v6/freshtrack-v6-qa.apk` e `payload-verification.json`.
Gli APK/AAB destinati alla distribuzione non sono stati sostituiti dalla copia QA.

## Prove completate

| Prova | Risultato osservato | Evidenza |
| --- | --- | --- |
| Aggiornamento e avvio a freddo | Installazione riuscita; avvio `Status: ok`, `COLD`, 7894 ms | Log ADB e schermata 01 |
| Dashboard inizialmente vuota | Contatori a zero, invito all'inserimento e pulsante Aggiungi visibili | 01 |
| Prodotti inizialmente vuoti | Invito centrale e CTA interna, senza FAB duplicato | 02 |
| Nome obbligatorio | Salvataggio senza nome respinto con «Inserisci il nome» | 03 |
| Salva e aggiungi un altro | «QA Latte» salvato con scadenza Oggi; modulo azzerato, nuova data predefinita a +7 giorni, messaggio di successo | 04, 06, 12 |
| Permesso notifiche | Richiesta dell'app e dialogo Android; Consenti accettato; impostazioni mostrano avvisi attivi | 04, 05b, 14 |
| OCR da galleria | Il selettore Android apre l'immagine di prova; ML Kit riconosce 30/09/2026 e richiede conferma esplicita | 09, 11 |
| Salvataggio della data OCR | «QA Scadenza foto» compare nell'inventario con scadenza 30 settembre 2026 | 12, 19 |
| Stato alla data corrente | «QA Latte» è «Scade oggi» il 6 settembre; il prodotto del 30 settembre è «Disponibile» | 12 |
| Dettaglio e accesso alla modifica | Nome, categoria, quantità e date coerenti; il comando Modifica apre il modulo con i dati salvati | 19, 20 |
| Navigazione principale | Passaggi fra Dashboard, Prodotti, Impostazioni e Notifiche riusciti | 01, 12, 13, 14 |

Le schermate selezionate e i relativi alberi XML Android sono in
[`screenshots/emulator-qa-v6/`](screenshots/emulator-qa-v6/).
I numeri della tabella corrispondono ai prefissi dei file. Il PNG viene
acquisito prima del dump XML: nelle transizioni può mostrare uno stato
intermedio. In particolare, la prova 12 mostra il salvataggio in corso nel
PNG e i due prodotti salvati nel successivo XML; il dettaglio è confermato
anche dalla schermata 19.
Le acquisizioni complete, XML Android e i log diagnostici sono nella cartella
locale ignorata da Git `build/emulator-qa-v6/`.

## Prove interrotte o ancora da eseguire

- Salvataggio delle modifiche, quantità decimale, duplicazione e stati
  consumato/utilizzato/buttato, ripristino ed eliminazione.
- Ricerca, filtri, ordinamento e pannelli della dashboard con dati sufficienti.
- Foto del prodotto, fotocamera e decodifica barcode, compresi gli errori di rete.
- OCR con più date e immagine illeggibile: in questa sessione è stata provata
  soltanto un'immagine leggibile con una singola data.
- Esportazione CSV e backup, importazione Unisci/Sostituisci e file non validi.
- L'orario notifiche è stato aperto e ne è stata tentata la modifica, ma il
  valore finale non è stato verificato. Non è stata provata la consegna di
  una notifica né l'apertura della data corrispondente toccandola.
- Persistenza dopo riavvio, notifiche dopo riavvio e ripresa dal background.
- Temi chiaro/sistema, testo al 200% e rotazione sul dispositivo. I test
  automatici del ridisegno coprono questi layout, ma non sostituiscono la prova Android.
- Installazione con firma definitiva, dispositivo fisico e runtime a 16 KB.

## Interruzione e diagnostica

Inizialmente alcune finestre native comparivano dopo l'acquisizione immediata;
una seconda lettura ha permesso di verificare permessi, galleria e dialogo OCR.
Successivamente `uiautomator dump` è andato ripetutamente in timeout a 40 secondi.
Anche `dumpsys window` ha restituito
`SERVICE 'window' DUMP TIMEOUT (10000ms) EXPIRED`; in seguito si è bloccata
anche l'acquisizione `screencap`.

Il controllo è stato ripetuto fuori dal contesto di esecuzione ristretto,
senza risolvere il comportamento. La lettura di CPU e log Android è riuscita
in un intervallo; il campione di log acquisito non contiene una prova di crash
FreshTrack e non costituisce una verifica completa dell'assenza di crash/ANR.

È stato eseguito un riavvio normale del solo Pixel, senza wipe. Dopo un breve
ritorno allo stato `device`, anche `getprop sys.boot_completed` è rimasto
bloccato. La riconnessione del solo trasporto ADB ha lasciato il dispositivo
`offline`. L'ultima verifica ADB della sessione riporta `offline`.
Anche il tentativo di lettura delle finestre Windows tramite computer-use
è terminato con `js execution timed out; kernel reset, rerun your request`.

Questi elementi documentano un impedimento nel collaudo. Non provano da soli
né un bug FreshTrack né l'assenza di problemi nell'app.

## Dati dell'emulatore e pulizia da completare

Prima dell'aggiornamento sono stati salvati l'APK installato e i dati privati
dell'app. Il database iniziale è stato letto dalla copia: **zero prodotti**.
Le preferenze iniziali contenevano soltanto la cache vuota delle notifiche;
i permessi Fotocamera e Notifiche erano negati.

- APK precedente: `build/emulator-qa-v6/installed-before.apk`.
- Archivio dei dati iniziali: `build/emulator-qa-v6/data-before.tar`.
- SHA-256 dell'archivio:
  `a3ffa796aaa86a592162649ca864c4a6fc074404874343e1dbc2c1c63e5e38de`.
- Copia SQLite e inventario iniziale: `database-before.sqlite`, `inventory-before.json`.

Prima del blocco erano presenti **QA Latte** e **QA Scadenza foto**, il permesso
Notifiche era stato concesso e una foto di prova era stata aggiunta in
`/sdcard/Pictures/freshtrack-qa-expiry.png`. La pulizia non è stata eseguita:
non si può dichiarare ripristinato lo stato iniziale mentre il Pixel è offline.
Quando torna controllabile, verificare i dati, rimuovere soltanto i prodotti
e i file QA, ripristinare le preferenze e i permessi iniziali e ricontrollare
l'inventario vuoto. Non cancellare foto o dati delle altre applicazioni.

## Rapporto con i controlli precedenti

Il [resoconto del ridisegno](ui_redesign_2026-09-07.md) documenta i 168 test
superati, gli 86 controlli UI/contrasto successivi alle ultime correzioni,
l'analisi statica e la validazione dei pacchetti. Non sono stati rieseguiti
in questa sessione, che non ha modificato il codice applicativo.

Il collaudo parziale sul Pixel aggiunge prove reali per i soli flussi elencati.
Non chiude i requisiti della [checklist di rilascio](release_checklist.md),
i test su dispositivo fisico o le verifiche Play Console.
