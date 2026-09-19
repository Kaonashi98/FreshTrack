# FreshTrack — verifica sul Pixel riaperto

8 settembre 2026, 10:46–10:56, orario del PC (Europe/Rome).

## Esito

La schermata nera e i blocchi precedenti **non si sono ripresentati** durante
questa prova sul Pixel originale. Home, tastiera, fotocamera e navigazione sono
state controllate sia nell'albero di accessibilità sia nelle immagini effettive.
Superati anche il riavvio completo del processo e la verifica dei dati salvati.
Non sono stati modificati sorgenti, APK, risoluzione o configurazione del renderer.

Questo risultato aggiorna il limite osservato nel precedente
[resoconto della build 8](ui_iris_build8_2026-09-08.md). Non identifica da solo
la causa del blocco precedente né prova il comportamento su ogni dispositivo.

## Dispositivo e pacchetto

- Pixel `emulator-5554`, Android API 35, 1080×2400, densità 420.
- Renderer standard Impeller/OpenGLES, confermato nei log dei processi 3617 e 5349.
- Pagine di memoria da 4096 byte: questa non è una prova del runtime a 16 KB.
- APK installato `1.0.0+8`, SHA-256 uguale al candidato finale:
  `e1a918cb2f4e7508be6c5bf5fb814b4f919d534484a81eb4465c0e701bbe1609`.

## Percorsi verificati

| Prova | Risultato |
|---|---|
| Home, Prodotti e Impostazioni | Visibili e navigabili, testata senza marchio |
| Inserimento manuale e tastiera | Nome digitato integralmente, pulsante di salvataggio accessibile |
| Scadenza Oggi e salvataggio | Prodotto presente nell'inventario e nella home |
| Consumato e Annulla | Stato aggiornato e poi ripristinato sul database reale |
| Ricerca con tastiera aperta | Risultato visibile; ricerca cancellabile |
| Modifica | Nuovo nome salvato e mostrato nel dettaglio |
| Riavvio completo dell'app | Home visibile, modifica conservata; avvio a freddo riportato da Android: 2585 ms |
| Riapertura di Aggiungi | Funziona dopo salvataggio e dopo Indietro dal modulo |
| Scanner | Permesso temporaneo, anteprima della camera virtuale, ritorno al modulo e alla home |
| Tema chiaro e scuro | Cambio applicato; tema scuro originale ripristinato |
| Archivio e In scadenza | Consumato visibile in Archivio ed escluso dalle scadenze; ripristino disponibile funzionante |
| Eliminazione | Conferma riferita al solo prodotto temporaneo; inventario tornato a zero |

Nei log raccolti dei due processi non sono stati trovati crash, eccezioni Flutter
non gestite, overflow RenderFlex o assertion failure. Non è una misurazione
completa delle prestazioni o una garanzia di assenza di ogni possibile difetto.

## Stato lasciato sul Pixel

L'app è aperta sulla home, in tema scuro. Il prodotto temporaneo `VerificaPixelUI`,
poi rinominato `VerificaPixelModificata`, è stato eliminato. L'inventario iniziale
e finale contiene zero prodotti. Revocato il permesso Fotocamera concesso solo
per la prova; le notifiche restano non autorizzate. L'emulatore è rimasto aperto.

## Osservazione UX e prove distinte

Con le notifiche non autorizzate, la proposta «Attivare i promemoria?» viene
ripresentata anche dopo il salvataggio di una modifica, nonostante il precedente
«Non ora». Il salvataggio riesce, ma questa ripetizione è un dettaglio UX
migliorabile, annotato senza cambiare il comportamento in questa verifica.

Non sono stati ripetuti qui decodifica di un barcode reale, OCR, consegna delle
notifiche o backup/ripristino. Restano separate le prove su telefono fisico e
le verifiche Play Console, privacy/Data Safety e Pre-launch Report. I 178 test
automatici e l'analisi statica pulita appartengono alla verifica precedente
sugli stessi sorgenti, ricontrollati mediante impronte.

## Evidenze

Log, XML, impronte e risultato automatico sono in `build/ui-iris/pixel-recheck/`.
Copie delle schermate principali:

- [Home dopo il riavvio](screenshots/pixel-recheck-v8/after-cold-start.png)
- [Tastiera nel modulo](screenshots/pixel-recheck-v8/keyboard.png)
- [Ricerca](screenshots/pixel-recheck-v8/search-keyboard.png)
- [Fotocamera](screenshots/pixel-recheck-v8/camera.png)
- [Tema chiaro](screenshots/pixel-recheck-v8/home-light.png)
- [Stato finale](screenshots/pixel-recheck-v8/final-home.png)
