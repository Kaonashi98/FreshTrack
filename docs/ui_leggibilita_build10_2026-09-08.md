# FreshTrack — colori più vivaci e leggibilità, build 10

Data: 8 settembre 2026. Versione `1.0.0+10`.

## Correzione applicata

L’utente ha segnalato una palette spenta e poco leggibile, mostrando la home
scura con inventario vuoto. La revisione interviene su quella condizione oltre
che sulle schermate popolate:

- Azzurro deciso per azioni e navigazione, verde per gli stati senza scadenze.
- Fondo scuro blu `#14243A`, superfici `#263C57`, testo principale bianco e
  secondario `#D9E8FC`; bordi e barra inferiore più distinti dal fondo.
- Tema chiaro con fondo `#EEF4FF`, schede bianche, testo `#12243D` e azioni `#155EEF`.
- Messaggi della home dentro schede azzurre/verdi, icone piene colorate,
  titoli da 16 punti e descrizioni da 14, rispettando l’ingrandimento del sistema.
- Stati di scadenza ancora indicati con etichette e colori ambra/rosso.
- Colori coordinati anche nei menu, campi, finestre, foto e avvio Android.

Le schede informative della home non aggiungono nuovi pulsanti; l’azione
Aggiungi resta nella barra inferiore. Impostazioni nell’angolo superiore destro
e contenuto in alto come richiesto. Nessun cambiamento alla logica dei prodotti.

## Verifiche

- Analisi statica sui sorgenti finali: **nessun problema**.
- Suite completa: **178/178 test superati**, inclusi home vuota, navigazione,
  inserimento e layout da 320×568 a 915×412 con testo 100/150/200%.
- **14 schermate** renderizzate dai widget reali: sei percorsi nei due temi
  con prodotti dimostrativi, più la home vuota chiara/scura; quattro prove superate.
- 50 combinazioni base di contrasto testo/sfondo misurate sui colori Flutter,
  tutte almeno **5,41:1**.

| Contrasto sullo sfondo | Chiaro | Scuro |
| --- | ---: | ---: |
| Testo principale | 14,14:1 | 15,63:1 |
| Testo secondario | 6,59:1 | 12,58:1 |
| Testo nel pulsante primario | 5,41:1 | 6,95:1 |

## Pixel e pacchetti

Sul Pixel aperto, API 35 a 1080×2400 / densità 420, verificati home vuota scura,
inserimento manuale, digitazione con tastiera e pulsante Salva visibile,
ritorno senza salvare, impostazioni, tema chiaro, ritorno allo scuro e riavvio.
Le prove si sono concluse alle 12:20, ora del computer. Nessuna schermata nera
osservata e nessun errore critico rilevato nei log dei processi controllati.
L’app è rimasta aperta sulla home scura; inventario ancora vuoto e nessun
prodotto di prova salvato.

Il primo avvio dopo l’aggiornamento ha impiegato 10385 ms mentre era in corso
la compilazione del bundle; il riavvio finale ha impiegato 3747 ms. Renderer
standard Impeller/OpenGLES e pagine di memoria da 4096 byte. Questo collaudo
è mirato alla revisione visiva e non ripete tutti i test manuali delle funzioni.

APK/AAB `1.0.0+10` generati, firme e metadati verificati, bundletool validate
superato. Font e codice compilato delle tre ABI corrispondono tra i pacchetti.
Per aggiornare l’installazione Android Debug esistente senza cancellarne i dati,
sul Pixel è stata usata una copia dell’APK con firma QA compatibile. Le 326 voci
ZIP esterne a `META-INF/` sono identiche al pacchetto release.

| Artefatto | SHA-256 |
| --- | --- |
| APK release | `19138f7c48fd9701c48d20145440c71b5a2fb0624752663eca9ca6128f463411` |
| AAB release | `d0e1c6bd00d77dd87f17cc8197c1fc249f81c517833f1a6fedda4b63b47327fe` |
| APK QA installato | `bb1021d14a88c7ec0d7b3146a1cfab104d88e9786d67d1fd9723c0a713a39cbe` |

Artefatti release in `build/app/outputs/flutter-apk/app-release.apk` e
`build/app/outputs/bundle/release/app-release.aab`; copia Pixel in
`build/ui-azzurro/app-pixel-qa.apk`. La build segnala ancora il precedente avviso
di futura incompatibilità KGP di `mobile_scanner`; la compilazione attuale riesce.

## Schermate

Queste anteprime provengono dai widget Flutter, con inventario vuoto o dati di esempio:

- [Home vuota scura](screenshots/ui-azzurro-v10/empty-dark-dashboard.png)
- [Home vuota chiara](screenshots/ui-azzurro-v10/empty-light-dashboard.png)
- [Home con prodotti](screenshots/ui-azzurro-v10/dark-dashboard.png)
- [Inventario](screenshots/ui-azzurro-v10/dark-products.png)
- [Inserimento](screenshots/ui-azzurro-v10/dark-products-new.png)

Acquisizioni dal Pixel, separate dalle anteprime Flutter:

- [Home scura finale](screenshots/ui-azzurro-v10/pixel-final-dark-home.png)
- [Home chiara](screenshots/ui-azzurro-v10/pixel-light-home.png)
- [Inserimento con tastiera](screenshots/ui-azzurro-v10/pixel-dark-keyboard.png)
- [Impostazioni chiare](screenshots/ui-azzurro-v10/pixel-light-settings.png)

Evidenze operative e copie antecedenti in `build/ui-azzurro/`. I precedenti
APK/AAB della build 9 sono conservati. Il checkout conteneva già le revisioni
precedenti; nessun commit, push o pubblicazione. Le verifiche esterne di rilascio
restano elencate nella [checklist](release_checklist.md).
