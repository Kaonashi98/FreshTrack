# FreshTrack — piano di implementazione

## Architettura

FreshTrack usa una variante feature-first della Clean Architecture:

- `domain`: entità, contratti dei repository e regole pure;
- `data`: database Drift, mapper e implementazioni dei repository;
- `presentation`: stato Riverpod, navigazione GoRouter e widget;
- `core`: tema, routing e servizi trasversali;
- `features`: moduli successivi con dipendenze rivolte al domain;
- `shared`: componenti UI riusabili.

Il dominio non dipende da Flutter o dal database. La UI osserva stream esposti dal repository e tutte le scritture passano dal relativo contratto.

## Fase 1 — fondazioni e inventario minimo

- Progetto Android, Material 3 e navigazione principale.
- Entità prodotto, categorie e unità di misura.
- Regole testabili per scaduto, oggi, in scadenza e fresco.
- Database Drift offline con repository CRUD.
- Dashboard con indicatori e prodotti da consumare presto.
- Lista con ricerca, categoria e ordinamento.
- Form di inserimento con validazione e selezione date.
- Test di dominio, repository e schermate principali.

## Fase 2 — gestione completa e acquisizione

- Modifica ed eliminazione con conferma dalla UI.
- Foto da fotocamera/galleria, copia persistente e cleanup dei file.
- Visualizzazione completa della foto e azioni essenziali nel dettaglio.

Lo scanner barcode è escluso dalla versione 1.0 e resta nel backlog per un aggiornamento futuro, quando potrà essere consegnato come flusso completo.

## Fase 3 — calendario e notifiche

- Calendario mensile con raggruppamento per data di scadenza.
- Servizio locale di scheduling con timezone e permessi Android.
- Giorni di preavviso per prodotto e orario globale configurabile.
- Rescheduling automatico su modifica ed eliminazione.

## Fase 4 — statistiche

- Aggregati per stato e categoria.
- Percentuale anti-spreco con definizione esplicita del denominatore.
- Serie mensili e grafici accessibili con `fl_chart`.

## Fase 5 — impostazioni e portabilità

- Tema chiaro/scuro/sistema persistito.
- Preavviso predefinito di zero giorni e orario predefinito alle 09:00.
- Import/export JSON rimandati a una versione successiva.
- Cancellazione dati e media con doppia conferma.

## Fase 6 — hardening e rilascio

- Migrazioni database, accessibilità, localizzazione e performance.
- Copertura test di regressione, test integrazione Android e QA responsive.
- Icona, splash screen, privacy, firma release e pipeline CI.
