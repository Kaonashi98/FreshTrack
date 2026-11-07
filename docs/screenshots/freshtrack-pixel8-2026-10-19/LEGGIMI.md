# FreshTrack — schermate reali dal Pixel 8 emulato

Questa cartella contiene 21 screenshot PNG acquisiti dall'app FreshTrack aperta
sull'emulatore Android `emulator-5554` il 19 ottobre 2026. Ogni immagine ha la
risoluzione originale di 1080 × 2400 pixel. Sono catture dell'interfaccia in
esecuzione, non anteprime generate dai test Flutter e non composizioni per lo
Store.

L'app installata si identifica come `io.github.kaonashi98.freshtrack` e riporta
`1.0.1+13`. Questo numero non dimostra che il contenuto dell'installazione sia
identico all'AAB release firmato con lo stesso numero: il codice locale ha
modifiche successive.

## Cosa mostra la sequenza

1. Home e inventario vuoti: `01`–`02`.
2. Scelta tra scansione e inserimento manuale, modulo prodotto, categorie e
   campi facoltativi: `03`–`07`.
3. Permesso fotocamera, scanner, codice manuale e calendario scadenza:
   `08`–`11`.
4. Inserimento di una voce temporanea chiamata **Demo**, richiesta dei
   promemoria, inventario, dettaglio e home con un prodotto: `12`–`16`.
5. Impostazioni, aspetto, notifiche, backup e CSV: `17`–`21`.

La voce **Demo** è stata eliminata dopo le catture. Una lettura del database
dell'app ha confermato **0 prodotti**. Il permesso fotocamera è stato concesso
durante l'uso per visualizzare lo scanner; i promemoria non sono stati attivati.

## Contesto del progetto

FreshTrack è un'app Flutter Android per registrare prodotti e scadenze, vedere
le priorità nella dashboard e ricevere promemoria locali. L'inventario resta
sul dispositivo. L'app offre foto prodotto, scansione barcode con ricerca
facoltativa nei cataloghi Open Facts, lettura OCR della scadenza con conferma
dell'utente, backup ZIP manuale e esportazione CSV. L'interfaccia è in italiano
e inglese, con tema di sistema, chiaro e scuro.

Queste immagini documentano l'aspetto e i percorsi visibili dell'app, non
certificano il funzionamento completo di scansione, OCR, notifiche, backup o
distribuzione Google Play. Durante la ripresa del lavoro l'emulatore ha mostrato
artefatti grafici e FreshTrack è rimasta sulla schermata iniziale; non sono
state quindi acquisite le pagine Privacy e informazioni o altre varianti del
tema. Per il rilascio pubblico restano necessarie verifiche del bundle finale,
dei dispositivi fisici, della privacy pubblicata e della Play Console.
