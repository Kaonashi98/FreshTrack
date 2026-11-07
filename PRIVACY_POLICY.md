# Informativa sulla privacy / Privacy Policy di FreshTrack

[Italiano](#italiano) · [English](#english)

## Italiano

Ultimo aggiornamento: 20 ottobre 2026.

FreshTrack è un'applicazione offline-first. Non richiede un account, non mostra
pubblicità e non usa i dati per profilazione. L'inventario è conservato nello
spazio privato dell'app e non viene inviato allo sviluppatore.

La connessione Internet è usata soltanto per la ricerca facoltativa di prodotti
nei cataloghi Open Food Facts, Open Beauty Facts, Open Pet Food Facts e Open
Products Facts e per i dati tecnici raccolti automaticamente dagli SDK
Google ML Kit descritti di seguito.

## Dati conservati sul dispositivo

L'app può memorizzare localmente:

- informazioni inserite sui prodotti, incluso l'eventuale codice a barre;
- date di acquisto e scadenza;
- fotografie selezionate o scattate dall'utente;
- preferenze relative a tema, lingua e notifiche.

Questi dati restano sul dispositivo finché l'utente non elimina un prodotto,
non cancella tutti i dati o non disinstalla l'app.

## Permessi Android

- **Fotocamera:** usata solo quando l'utente avvia la scansione di un codice a
  barre, scatta la foto di un prodotto o fotografa una data per il
  riconoscimento del testo.
- **Internet:** usato per la ricerca facoltativa nei cataloghi Open Facts e dalle
  componenti Google ML Kit.
- **Notifiche:** usate per mostrare promemoria locali sulle scadenze.
- **Allarmi esatti (facoltativo):** usati solo se attivi “Orario più puntuale”
  nelle impostazioni, per programmare i promemoria all’ora scelta. Se il
  permesso manca, FreshTrack continua con avvisi verso quell’orario.
- **Avvio completato:** consente ad Android di ripristinare i promemoria locali
  dopo un riavvio.

Foto e file possono anche essere scelti tramite il selettore di sistema senza
concedere all'app un accesso generale alla memoria condivisa.

## Ricerca tramite codice a barre

Solo quando l'utente richiede una ricerca, FreshTrack invia il codice a barre e
la lingua della richiesta tramite HTTPS all'API di Open Food Facts. La ricerca
può essere reindirizzata a Open Beauty Facts, Open Pet Food Facts o Open
Products Facts in base al tipo di prodotto. Il catalogo consultato riceve anche
i normali dati tecnici della connessione, come l'indirizzo IP e lo User-Agent
con nome e versione dell'app. FreshTrack non invia fotografie, date o l'intero
inventario. Nome, marca e categoria sono proposti solo se il prodotto è presente
con dati sufficienti; altrimenti rimane disponibile l'inserimento manuale.

I dati provengono dai cataloghi collaborativi della famiglia Open Facts. Per
informazioni sui cataloghi e sulle licenze consulta la
[documentazione ufficiale](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/scanning-cosmetics-pet-food-and-other-products/).
Il database Open Food Facts è distribuito con licenza
[Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/).

## Foto, riconoscimento del testo e Google ML Kit

Le immagini scelte vengono copiate nello spazio privato dell'app. Il
riconoscimento del testo che propone una data di scadenza avviene sul
dispositivo; immagini, testo riconosciuto e data proposta non vengono inviati a
Google. La data deve essere controllata e confermata dall'utente.

Gli SDK Google ML Kit possono tuttavia trasmettere automaticamente tramite HTTPS
informazioni tecniche sul dispositivo e sull'app, identificatori per
installazione, metriche delle prestazioni, configurazione delle API, eventi e
codici di errore. Google dichiara di usare questi dati per diagnostica, analisi
dell'utilizzo, funzionamento e miglioramento del servizio e di non condividerli
con terze parti. Questi dati non includono l'inventario o il contenuto delle
immagini analizzate. Consulta la
[guida Data Safety di ML Kit](https://developers.google.com/ml-kit/android-data-disclosure)
e i [termini di ML Kit](https://developers.google.com/ml-kit/terms).

Lo scanner barcode usa lo zoom automatico. Google ML Kit raccoglie inoltre un identificatore generato per la sessione di scansione, non destinato a identificare un utente o dispositivo, le variazioni del livello di zoom e le coordinate previste del riquadro che potrebbe contenere un codice a barre.

## Backup, ripristino ed esportazione

FreshTrack permette di creare manualmente:

- un backup ZIP con prodotti, preferenze e fotografie;
- un file CSV con i dati dell'inventario.

I file vengono creati soltanto su richiesta. Puoi salvarli nella posizione
scelta tramite Android oppure condividerli verso un altro telefono, Drive o una
chat. Non sono cifrati da FreshTrack: vanno conservati in un luogo sicuro.
FreshTrack non li carica automaticamente su server esterni. Se l'utente sceglie
una destinazione cloud nel selettore di sistema o nel foglio di condivisione,
la conservazione è regolata dal fornitore selezionato.

Il backup Android automatico e il trasferimento automatico dei dati dell'app tra
dispositivi sono disabilitati. Un backup creato manualmente può essere
ripristinato dopo una reinstallazione. Non esiste un account famiglia: l'inventario
resta su un dispositivo finché non condividi tu il file.

## Condivisione e controllo dell'utente

Lo sviluppatore non riceve né vende l'inventario. La ricerca Open Food Facts e
l'esportazione avvengono su iniziativa dell'utente; i dati tecnici di ML Kit
possono essere trasmessi automaticamente quando le relative funzioni vengono
usate.

Dalla sezione **Impostazioni > Dati e backup** è possibile esportare,
ripristinare o cancellare definitivamente prodotti, immagini e preferenze. I
permessi possono essere revocati dalle impostazioni Android.

## Modifiche

Eventuali aggiornamenti di questa informativa saranno pubblicati insieme a una
nuova versione dell'app e su questa pagina.

## Contatti

Per richieste relative alla privacy o all'assistenza:
[freshtrack.help@outlook.com](mailto:freshtrack.help@outlook.com).

Sviluppatore: Nicola Zingaro.

---

## English

Last updated: October 20, 2026.

FreshTrack is an offline-first application. It does not require an account,
display advertising, or use data for profiling. Your inventory is stored in the
app's private storage and is not sent to the developer.

Internet access is used only for optional product lookups through Open Food
Facts, Open Beauty Facts, Open Pet Food Facts and Open Products Facts, and for
the technical data automatically collected by Google ML Kit SDKs,
as described below.

### Data stored on your device

The app may store locally:

- product information you enter, including an optional barcode;
- purchase and expiration dates;
- photographs you select or take;
- theme, language and notification preferences.

This data remains on the device until you delete a product, clear all app data,
or uninstall the app.

### Android permissions

- **Camera:** used only when you start a barcode scan, take a product photo, or
  photograph a date for text recognition.
- **Internet:** used for optional Open Facts lookups and by Google ML Kit
  components.
- **Notifications:** used to show local expiration reminders.
- **Exact alarms (optional):** used only if you enable “More precise time” in
  settings, to schedule reminders at the chosen hour. If the permission is
  missing, FreshTrack continues with alerts around that time.
- **Completed boot:** allows Android to restore local reminders after a restart.

Photos and files may also be selected through the Android system picker without
granting the app general access to shared storage.

### Barcode lookup

Only when you request a lookup does FreshTrack send the barcode and request
language over HTTPS to the Open Food Facts API. The request may be redirected to
Open Beauty Facts, Open Pet Food Facts or Open Products Facts according to the
product type. The catalog contacted also receives ordinary connection data,
such as the IP address and the User-Agent containing the app name and version.
FreshTrack does not send photographs, dates or your complete inventory. Name,
brand and category are suggested only when the catalog has sufficient data;
manual entry remains available otherwise.

Product data comes from the collaborative Open Facts catalogs. See the
[official documentation](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/scanning-cosmetics-pet-food-and-other-products/)
for information about the catalogs and their licenses.
The Open Food Facts database is distributed under the
[Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/).

### Photos, text recognition and Google ML Kit

Selected images are copied to the app's private storage. Text recognition that
suggests an expiration date runs on the device; images, recognized text and the
suggested date are not sent to Google. You must review and confirm the date.

Google ML Kit SDKs may nevertheless automatically transmit technical device and
app information, per-installation identifiers, performance metrics, API
configuration, feature input and output sizes, feature versions, event types and
error codes over HTTPS. Google states that it uses this data for diagnostics,
usage analytics, operation and service improvement, and does not share it with
third parties. This data does not include your inventory or the contents of the
images being analyzed. See the
[ML Kit Data Safety guide](https://developers.google.com/ml-kit/android-data-disclosure)
and [ML Kit terms](https://developers.google.com/ml-kit/terms).

The barcode scanner uses auto zoom. Google ML Kit also collects a generated scanning-session identifier not intended to identify a user or device, zoom level changes, and predicted bounding-box coordinates that may contain a barcode.

### Backup, restore and export

FreshTrack can manually create:

- a ZIP backup containing products, preferences and photographs;
- a CSV file containing inventory data.

Files are created only at your request. You can save them to a location you
choose through Android or share them to another phone, Drive or a chat.
FreshTrack does not encrypt them, so keep them in a secure place. FreshTrack
does not automatically upload them to external servers. If you choose a cloud
destination in the system picker or share sheet, storage is governed by that
provider.

Android automatic backup and automatic device-to-device transfer are disabled.
A manually created backup can be restored after reinstalling the app. There is
no family account: the inventory stays on one device until you share the file.

### Sharing and your controls

The developer does not receive or sell your inventory. Open Food Facts lookups
and exports are initiated by you; ML Kit technical data may be transmitted
automatically when the related features are used.

From **Settings > Data and backup**, you can export, restore or permanently
delete products, images and preferences. Permissions can be revoked from Android
settings.

### Changes

Updates to this policy will be published with a new app version and on this
page.

### Contact

For privacy or support requests:
[freshtrack.help@outlook.com](mailto:freshtrack.help@outlook.com).

Developer: Nicola Zingaro.
