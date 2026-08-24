# Changelog

Tutte le modifiche rilevanti di FreshTrack sono documentate in questo file.

## [1.0.0] - In preparazione

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

### Qualità

- Clean Architecture con repository pattern.
- Test di dominio, data layer e schermate principali.
- Android Lint e CI GitHub.
- Configurazione sicura della firma release.
- Esclusione esplicita dei dati da backup cloud e trasferimenti tra dispositivi.
- Percorsi delle immagini confinati alla cartella privata gestita dall’app.
- Asset Google Play riproducibili per icona e feature graphic.
- Nessuna API key o credenziale inclusa nel repository.
