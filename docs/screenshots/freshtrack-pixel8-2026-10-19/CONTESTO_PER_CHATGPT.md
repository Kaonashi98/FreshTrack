# Prompt da inviare insieme agli screenshot

Ti invio 21 screenshot reali di FreshTrack, acquisiti sull'emulatore Google
Pixel 8. Guardali in ordine numerico per capire com'è fatta oggi l'app, quali
percorsi sono presenti e quale direzione visiva sta prendendo. Le schermate con
il prodotto **Demo** mostrano una voce temporanea: è stata rimossa dopo la
raccolta.

FreshTrack nasce come app Android Flutter per organizzare le scadenze dei
prodotti di casa e ridurre sprechi e dimenticanze. L'obiettivo iniziale era un
inventario semplice e principalmente offline: aggiungere e modificare prodotti,
vedere scaduti e prossime scadenze, cercare e filtrare, segnare un articolo come
consumato, utilizzato o buttato, e ricevere promemoria locali.

Nel tempo abbiamo aggiunto foto, inserimento rapido, duplicazione, scansione
barcode con ricerca facoltativa nei cataloghi Open Facts, inserimento manuale
sempre disponibile, OCR sul dispositivo per leggere la data della confezione
con conferma obbligatoria, backup ZIP manuale con ripristino ed esportazione
CSV. La ricerca barcode è stata estesa oltre gli alimenti italiani: il codice
locale usa `product_type=all` e considera anche cosmetici, prodotti per animali
e prodotti generici. La copertura dei cataloghi non è universale e l'utente
può sempre compilare il prodotto a mano.

L'interfaccia è stata rivista più volte per leggibilità e fluidità. La direzione
attuale usa blu, azzurro e verde, con dashboard, inventario, aggiunta e
impostazioni coordinati. Sono disponibili italiano e inglese, tema di sistema,
chiaro e scuro. È stata rimossa la categoria dedicata ai farmaci: la V1 si
presenta per alimenti, bevande, cura personale, pulizia e altri prodotti.

Abbiamo preparato testi e asset per Google Play, privacy bilingue, documenti di
handoff e test automatici. L'ultima verifica locale documentata prima di queste
catture riportava analisi statica pulita e 203 test superati. Questo non prova
che la versione pubblica sia pronta: serve un nuovo AAB firmato che includa le
modifiche correnti, il confronto delle immagini Store con quel bundle, test su
dispositivo fisico, verifica della privacy pubblicata e completamento delle
dichiarazioni e dei controlli Play Console.

Valuta gli screenshot come documentazione visiva dell'app installata
sull'emulatore, non come prova di tutte le funzioni o della build finale. La
versione installata riporta `1.0.1+13`, ma il suo contenuto non è stato
confrontato con l'AAB release firmato. Se dai un parere, separa ciò che è
visibile nelle immagini da ciò che richiederebbe una prova funzionale.
