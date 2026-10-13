---
name: Scouting App Design System v2
colors:
  surface: '#fff8f7'
  surface-dim: '#f1d3d0'
  surface-bright: '#fff8f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff0ef'
  surface-container: '#ffe9e7'
  surface-container-high: '#ffe2de'
  surface-container-highest: '#f9dcd9'
  on-surface: '#271816'
  on-surface-variant: '#5b403d'
  inverse-surface: '#3e2c2a'
  inverse-on-surface: '#ffedeb'
  outline: '#8f6f6c'
  outline-variant: '#e4beba'
  surface-tint: '#ba1a20'
  primary: '#af101a'
  on-primary: '#ffffff'
  primary-container: '#d32f2f'
  on-primary-container: '#fff2f0'
  inverse-primary: '#ffb3ac'
  secondary: '#005faf'
  on-secondary: '#ffffff'
  secondary-container: '#54a0fe'
  on-secondary-container: '#003567'
  tertiary: '#005f7b'
  on-tertiary: '#ffffff'
  tertiary-container: '#00799c'
  on-tertiary-container: '#e9f7ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb3ac'
  on-primary-fixed: '#410003'
  on-primary-fixed-variant: '#930010'
  secondary-fixed: '#d4e3ff'
  secondary-fixed-dim: '#a5c8ff'
  on-secondary-fixed: '#001c3a'
  on-secondary-fixed-variant: '#004786'
  tertiary-fixed: '#bee9ff'
  tertiary-fixed-dim: '#7bd1f8'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d65'
  background: '#fff8f7'
  on-background: '#271816'
  surface-variant: '#f9dcd9'
  scout-red: '#D32F2F'
  scout-blue: '#1976D2'
  background-white: '#FFFFFF'
  surface-dark: '#1C1B1F'
  branco-yellow: '#FFD600'
  reparto-green: '#388E3C'
  clan-red: '#B71C1C'
  status-success: '#2E7D32'
  status-error: '#C62828'
  status-pending: '#F9A825'
typography:
  display-lg:
    fontFamily: Poppins
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Poppins
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Poppins
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-lg:
    fontFamily: Poppins
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Poppins
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Poppins
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Poppins
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  quote-italic:
    fontFamily: Poppins
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-margin-mobile: 16px
  container-margin-desktop: 32px
  gutter: 16px
  card-padding: 16px
  section-gap: 24px
---

# Progettazione app "Scouting"

## Descrizione generale del progetto

L'app "Scouting" è un'applicazione mobile (iOS, Android e desktop) sviluppata con Flutter, il cui scopo principale è connettere i membri del gruppo scout, consentendo loro di poter aggiornare i loro profili personali, mantenere anche le loro informazioni sensibili, come allergie e altri dati medici, dati di contatto propri e dei loro genitori, come recapiti telefonici e indirizzi e-mail, oltre a consentire la visualizzazione dei pagamenti effettuati per diverse attività (censimento, uscite, campi ecc.).  Questa app è destinata ai membri del gruppo scout AGESCI Bari 10. Se i ragazzi (educandi) possono modificare solo le loro informazioni sensibili, i capi invece possono modificarle per i propri educandi, oltre a poter inserire pagamenti, visualizzare statistiche ecc. Nell'applicazione potranno essere inseriti anche eventi con ricezione di notifiche, come per esempio semplici riunioni, oppure uscite e campi. I ragazzi saranno divisi nelle tre branche, quindi Branco, Reparto e Clan/Fuoco.

Il focus principale dell'intera applicazione, che deve essere il punto cardine sia dall'inizio della sua progettazione sino alla sua intera realizzazione, è quello della sicurezza. I dati di ogni membro, essendo sensibili, devono essere conservati in database sicuri e protetti a più livelli. Si deve prevedere l'autenticazione a più fattori per l'accesso e ogni volta che si deve visualizzare/modificare un dato sensibile, deve essere richiesta una verifica biometrica, oltre al passwrod e/o all'OTP (One-Time Password), che verrà inviato tramite email o SMS. I dati di ogni membro devono essere criptati, sia a riposo che in transito. Devono essere previsti dei ruoli ben definiti: ragazzi (educandi), capi, capi unità (responsabili di una branca), capi gruppo (responsabili dell'intero gruppo). Il design dell'app deve essere minimalista ed elegante, seguendo le linee guida del Material Design 3.

Il miglior Database per questo progetto: Supabase (PostgreSQL)
Personalmente, ritengo che Supabase sia la scelta perfetta per il tuo progetto. È un'alternativa open-source a Firebase, ma basata su un database relazionale solido e storico come PostgreSQL.

Ecco perché si sposa perfettamente con il tuo design:

Dati Relazionali (Perfetto per i pagamenti e gerarchie): Avendo a che fare con "pagamenti effettuati", "censimento", storici clinici e divisione in gruppi (Branco, Reparto, Clan), un database relazionale (SQL) ti garantisce che i dati siano sempre coerenti (integrità referenziale). In un DB NoSQL i dati finanziari possono diventare complessi da gestire senza sbavature.

Autenticazione e MFA integrate: Supabase Auth supporta nativamente l'autenticazione a più fattori (MFA) e l'invio di OTP tramite Email.
Crittografia: I dati sono criptati at-rest (a riposo) e in-transit (in transito). Inoltre, usando PostgreSQL, puoi implementare funzioni per la crittografia a livello di singola colonna per i campi medici (es. estensione pgcrypto), aggiungendo un ulteriore livello di sicurezza.
Integrazione con Flutter: Esiste un SDK ufficiale per Flutter (supabase_flutter) eccellente e costantemente aggiornato.
L'alternativa (Il "Classico"): Firebase (Firestore)
Se preferisci rimanere nell'ecosistema Google, Firebase è l'alternativa principale.

Un consiglio extra per la sicurezza (visto il tuo focus)
Poiché il file menziona la sicurezza come "punto cardine" e parla di "verifica biometrica", ti consiglio di strutturare l'app in questo modo:

Usa il pacchetto Flutter local_auth per la biometria (FaceID/Impronta).
Tieni i dati sensibili medici criptati non solo dal database, ma valuta una Client-Side Encryption: cifra i dati medici in Flutter prima di inviarli al DB, e decifrali in Flutter dopo averli ricevuti. In questo modo, nemmeno un eventuale amministratore con accesso diretto al database Supabase/Firebase potrebbe leggere i dati sanitari dei ragazzi, ma vedrebbe solo stringhe incomprensibili. Solo il dispositivo dell'utente, sbloccato con biometria, potrà leggerli.

Vorrei gestire la pubblicazione e gli eventuali aggiornamenti dell'app in maniera interna e non passando dagli store principali.

Sì, è assolutamente possibile gestire la distribuzione e gli aggiornamenti internamente, ma bisogna fare una netta distinzione tra i sistemi operativi, perché mentre per Android e Windows è facilissimo e totalmente gratuito, per iOS (Apple) ci sono delle limitazioni importanti.

Ecco la strategia migliore per distribuire la tua app in modo privato, gratuito e con aggiornamenti in-app.

1. Android (Semplicissimo e 100% gratuito)
Su Android non hai alcun bisogno del Play Store.

Distribuzione iniziale: Puoi semplicemente generare il file di installazione (flutter build apk), caricarlo su un Google Drive, su uno spazio web privato o inviarlo nel gruppo WhatsApp dei capi/genitori. Gli utenti dovranno solo abilitare l'installazione da "Origini sconosciute" per quel file.
Aggiornamenti in-app: Puoi creare un sistema di aggiornamento interno in questo modo:
Nel tuo database (es. Supabase) crei una tabellina chiamata app_version contenente il numero dell'ultima versione (es. 1.0.5) e il link diretto al nuovo file APK.
All'avvio, la tua app su Flutter interroga il database. Se la versione dell'app installata (1.0.4) è minore di quella sul database, fai comparire un pop-up che dice: "È disponibile un nuovo aggiornamento fondamentale".
Usando un pacchetto Flutter come ota_update o flutter_downloader insieme a install_plugin, l'app scaricherà il nuovo APK in background e, una volta finito, chiederà all'utente di cliccare "Installa" per sovrascrivere l'app attuale.
2. Windows Desktop (Gratuito)
Come per Android, è estremamente semplice.

Distribuzione: Compili l'app (flutter build windows), ottieni il file .exe e lo condividi.
Aggiornamenti: Il processo è simile ad Android. All'avvio l'app controlla il database; se c'è una nuova versione, scarica il nuovo .exe. Per l'installazione automatica su Windows puoi usare librerie come auto_updater.

💡 LA SOLUZIONE GRATUITA PER IOS: La PWA (Progressive Web App) Dato che l'app è in Flutter (che compila perfettamente anche per il Web), la soluzione migliore e a costo zero per chi ha l'iPhone è questa:

Compili l'app per il web (flutter build web).
La ospiti gratuitamente su un servizio come Firebase Hosting, Vercel o GitHub Pages.
Dai il link agli utenti iOS e dici loro di aprirlo con Safari.
Lì dentro, istruisci gli utenti a cliccare sul tasto "Condividi" di Safari e selezionare "Aggiungi alla schermata Home".
Il risultato: L'utente avrà l'icona dell'app Scout sulla sua home, l'app si aprirà a schermo intero senza la barra di ricerca del browser (sembrerà un'app nativa al 100%) e, soprattutto, gli aggiornamenti saranno automatici: ogni volta che tu aggiorni il sito web, la loro app si aggiornerà da sola al riavvio successivo!

L'applicazione deve essere stabile, leggera, facile da usare, intuitiva e graficamente accattivante. Non deve avere bug, né crash, né blocchi, né rallentamenti. Deve essere in grado di funzionare offline, sincronizzando i dati quando torna online. Deve essere in grado di inviare notifiche push agli utenti, come per esempio semplici riunioni, oppure uscite e campi. Inoltre, l'app deve essere in grado di funzionare su diverse piattaforme, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi sistemi operativi, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi browser, come Safari, Chrome e Firefox. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi sistemi operativi, come iOS, Android e Windows. Inoltre, la sicurezza deve essere al primo posto. I dati sensibili, come allergie, malattie, ecc. devono essere criptati e protetti, così come tutti i dati sanitari dei ragazzi e i dati di pagamento. L'accesso all'app deve essere sicuro e protetto. Deve essere in grado di funzionare su diverse piattaforme, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi browser, come Safari, Chrome e Firefox.

## Dati generali e priorità dell'app

Nome dell'app: Scouting

Realizzazione: Dart con Flutter

Database: Supabase (database gratuito). SICUREZZA MASSIMA FONDAMENTALE, i dati sensibili, come allergie, malattie, ecc. devono essere criptati e protetti, così come tutti i dati sanitari dei ragazzi e i dati di pagamento. Anche le transazioni che avvengono all'interno dell'app, come la pagamento delle quote, devono essere sicure e protette, possibilmente a più livelli. L'accesso all'app deve essere sicuro e protetto. Deve garantire la privacy e la riservatezza dei dati sensibili di ciascun membro. Deve essere in grado di funzionare offline, sincronizzando i dati quando torna online. Oltre a ciò, Supabase offre una vasta gamma di funzionalità, come autenticazione, database, archiviazione file, notifiche push e molto altro.

Logo: da definire (il logo deve essere semplice, moderno e facilmente riconoscibile). Possibilmente che richiami il colore rosso e il nodo piano, simbolo del gruppo AGESCI Bari 10.

Colori base: Rosso (colore primario), Blu (colore secondario), Bianco (colore di sfondo). Da utilizzare questi colori in tutta l'app in manera coerente.

Font: Poppins

Basato su Material Design 3

L'app deve poter essere utilizzabile sia in tema chiaro che in tema scuro.

**Caratteristiche dell'app (in ordine di priorità)**:

1. Sicurezza di livello altissimo (criptazione dei dati sensibili, autenticazione a due fattori, ecc.)
2. I pagamenti avvengono tramite bonifico bancario effettuato dal socio maggiorenne/genitore al gruppo, in app poi si inserirà il PDF contenente la ricevuta del bonifico che, una volta accettata dai capi, determinerà il corretto pagamento di un'attività o del censimento annuale. Deve essere prevista una sezione pagamenti dove i capi potranno vedere chi ha pagato e chi no. Perciò non è necessario prevedere il pagamento direttamente in app, ma i dati dei bonifici inseriti all'interno dell'app vanno resi sicuri (crittografati).
3. I documenti in PDF da firmare (come censimento, autorizzazione alla privacy e dati medici) devono poter essere compilabili in app (prevedere un sistema di inserimento dati in PDF già all'interno dell'app stessa)
4. Stabilità e performance (l'app deve essere stabile, leggera, facile da usare, intuitiva e graficamente accattivante. Non deve avere bug, né crash, né blocchi, né rallentamenti.)
5. Notifiche push (l'app deve essere in grado di inviare notifiche push agli utenti, come per esempio semplici riunioni, oppure uscite e campi.)
6. Graficamente accattivante (l'app deve essere graficamente accattivante. Deve avere un design moderno, pulito e intuitivo anche per i meno avvezzi all'uso di questi sistemi, come persone adulte e non formate del tutto sul loro utilizzo)
7. Funzionalità offline (l'app deve essere in grado di funzionare offline, sincronizzando i dati quando torna online.)
8. Disponibilità su diverse piattaforme (l'app deve essere in grado di funzionare su diverse piattaforme, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi sistemi operativi, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi browser, come Safari, Chrome e Firefox.)

## Passi generali per la realizzazione del progetto

1. Bozza grafica dell'applicazione
2. Strutturazione delle varie sezioni dell'app (prima descrivendole dettagliatamente) con l'uso di blocchi di codice riutilizzabili per i vari elementi, come bottoni, grafici, ecc.
3. Progettazione e impostazione del database con l'uso di Supabase
4. Integrazione tra app e database
5. Test di funzionamento
6. Pubblicazione dell'applicazione

Devono essere previsti diversi tipi di accesso. Tutti gli utenti possono visualizzare i dati degli altri utenti (tutti i ragazzi e i capi) ma non possono modificare i dati altrui, ovviamente, eccetto i capi che possono modificare i dati di tutti i ragazzi (esclusi i dati anagrafici). Inoltre ci sono i soci maggiorenni (18+) che hanno alcuni poteri in più, come per esempio la possibilità di autorizzare uscite e campi, ma non possono modificare i dati altrui. Infine ci sono i capi che hanno tutti i poteri, come per esempio la possibilità di organizzare e autorizzare uscite e campi, ma non possono modificare i dati altrui. Ogni utente avrà una sua foto profilo che sarà visibile a tutti gli altri utenti.

Vari tipi di accesso:

1. Genitore (visualizzazione in sola lettura dei dati del proprio figlio e di tutti gli altri utenti, con possibilità di autorizzare uscite e campi e di poter pagare direttamente in app eventuali spese come censimenti, uscite, campi ecc.). Per i soci minorenni, i genitori possono compilare direttamente in app i vari PDF (con firma) del censimento (prevedere la possibilità di compilare i PDF direttamente in app), delle dichiarazioni mediche, in maniera tale che, una volta inviate, i capi possono leggere subito i dati in PDF compilati e firmati e accettarli/rifiutarli. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente. Tutto questo processo prevede scambi di notifiche in app tra i vari agenti: i capi ricevono una notifica quando un genitore/socio maggiorenne carica un documento di censimento/medico/di pagamento, i genitori/soci maggiorenni ricevono una notifica quando questi documenti vengono accettati o rifiutati, in maniera tale da rimanere sempre al corrente, in tempo reale, della propria situazione.

2. Socio censito (visualizzazione dei propri dati e di tutti gli altri utenti, possibilità di modifica dei propri dati (la cui conferma deve comunque essere accettata da un capo) e autorizzazione uscite e campi, se maggiore di 18 anni). Anche i soci censiti hanno possibilità di pagare direttamente in app eventuali spese come censimenti, uscite, campi ecc, anche se minorenni. Invece i soci minorenni non hanno possibilità di autorizzare uscite e campi, ma possono comunque pagare eventuali spese come censimenti, uscite, campi ecc. Ogni socio censito potrà appartenere a una tra tre diverse branche: Branco, Reparto e Clan/Fuoco. I soci appartenenti a Branco e Reparto potranno visualizzare, sul loro profilo, eventuali specialità e competenze acquisite (che sono diverse tra il Branco e il Reparto, mentre i soci del Clan/Fuoco non possono avere ne specialità ne competenze). Ogni specialità e competenza ha una sua immagine e una sua descrizione. Ogni socio, però, potrà aggiornare il proprio profilo, inserendo due distinte descrizioni: impegni presi durante l'anno e obiettivi da raggiungere (di solito tramite gli impegni presi). Quindi impegni e obiettivi sono collegati (prevedere collegamento anche in app. Ad esempio, se un utente clicca sull'obiettivo di un altro utente, o di se stesso, potrà vedere quali impegni dovrà portare a termine per raggiungere quell'obiettivo). Ogni socio, poi, potrà decidere se rendere visibili a tutti oppure visibili solo per se stesso gli impegni e gli obiettivi nel proprio profilo. Per i soci maggiorenni, l'unica differenza è che oltre ad autorizzare uscite e campi, possono anche pagarli, così come i capi e i genitori dei soci minorenni. Inoltre i soci maggiorenni possono compilare direttamente in app i vari PDF (con firma) del censimento, delle dichiarazioni mediche, in maniera tale che, una volta inviati, i capi possono leggere subito i dati in PDF compilati e firmati. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente. Per i soci minorenni, i genitori possono compilare direttamente in app i vari PDF (con firma) del censimento, delle dichiarazioni mediche, in maniera tale che, una volta inviate, i capi possono leggere subito i dati in PDF compilati e firmati. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente. (serviranno quindi eventuali librerie per compilare e firmare file in PDF)

3. Capo (visualizzazione di tutti i dati degli utenti, possibilità di modifica dei dati di tutti gli utenti, compresi censimenti, pagamenti ecc, autorizzazione uscite e campi). I capi possono essere di vario tipo: Aiuto capo, capo unità, capo gruppo, capo a disposizione, ecc. Ognuno avrà privilegi diversi in base al proprio ruolo. Ad esempio un aiuto capo avrà privilegi minori rispetto a un capo gruppo. Il capo gruppo, comunque, avrà accesso completo ai privilegi e potrà decidere di assegnarli ad un qualsiasi altro capo, tramite una dashboard apposita. Ogni capo, poi, apparterrà a una branca: Branco, Reparto e Clan/Fuoco (oppure gruppo, nel caso dei capi gruppo e di capi a disposizione). I capi appartenenti al Branco potranno inserire il loro "soprannome" (nome della giungla) che dovrà essere visualizzato al posto del loro nome, sia nella loro scheda profilo che in qualsiasi altra sezione dell'app dove loro siano presenti. Gli altri capi, invece, manterranno il loro semplice nome, invece.

Maggiori informazioni riguardo i singoli soci, le specialità e le competenze e i capi saranno poi aggiunti nelle descrizioni più dettagliate delle sezioni singole dell'app.

## Spiegazione specifica delle varie sezioni dell'app

### Registrazione dei soci minorenni

Nella fase di registrazione, i nuovi utenti inseriscono i loro dati: nome, cognome, sesso, data di nascita, indirizzo di residenza, numero di telefono, email, CAP, comune, provincia, password. Una volta inseriti tutti i dati, la registrazione non sarà ancora completa, poichè la richiesta di registrazione perverrà ad un capo, il quale dovrà decidere se accettare o rifiutare la registrazione e, in caso positivo, assegnare il ragazzo alla branca corretta (Branco, Reparto o Clan/Fuoco). Una volta accettata la registrazione, perverrà una notifica via email al nuovo utente, con il link per confermare la registrazione, che quindi potrà finalmente accedere all'app. Da quel momento, il nuovo utente potrà modificare le sue informazioni, inserendo per esempio i dati di censimento, pagamento ecc, e inserire anche la sua foto profilo. Quando un socio raggiunge la maggiore età (calcolabile tramite la data di nascita), automaticamente passerà a "socio maggiorenne" e potrà usufruire delle funzioni dei soci maggiorenni. Ovviamente, la registrazione è destinata ai soci del gruppo scout, quindi ci sarà bisogno di una fase successiva in cui i capi, o chi di competenza, verificheranno che i nuovi utenti siano effettivamente soci del gruppo scout. I capi possono anche rimuovere utenti dal sistema, a loro discrezione.

Vorrei che, in tempo reale, una volta inserita la data di nascita, se inferiore ai 18 anni, il campo "numero di telefono" diventa facoltativo (relativo al singolo socio) e venissero aggiunti dei nuovi campi "email genitore 1" e "email genitore 2" (con email genitore 2 facoltativo e email genitore 1 obbligatorio) e numero di telefono genitore 1 e numero di telefono genitore 2, con numero di telefono genitore 2 facoltativo e numero di telefono genitore 1 obbligatorio. La mail di registrazione perverrà in primis al genitore, nel caso di socio minorenne, ma poi, se inserita anche la mail del socio minorenne, anche a lui (ma al socio minorenne perverrà solo la mail in caso di accettazione finale della registrazione).

La sezione di registrazione è composta da tre sottosezioni: "Dati base", "indirizzo" e "riepilogo". Nella sezione "Dati base", verranno inseriti tutti i dati anagrafici del socio e, in aggiunta, eventualmente se minorenne, i dati di uno o due genitori (almeno uno obbligatorio). In particolare:

- Nome;
- Cognome;
- Genere (M/F o altro);
- Data di nascita;
- Email (obbligatoria sia per maggiorenni che per minorenni);
- Password;
- Numero di telefono (obbligatorio per maggiorenni, opzionale per minorenni);

Nel caso di socio minorenne, vengono aggiunti i campi dei due genitori:

- Nome genitore 1 (obbligatorio);
- Cognome genitore 1 (obbligatorio);
- Email genitore 1 (obbligatoria);
- Numero di telefono genitore 1 (obbligatorio);
- Nome genitore 2 (facoltativo);
- Cognome genitore 2 (facoltativo);
- Email genitore 2 (facoltativo);
- Numero di telefono genitore 2 (facoltativo);

Nella seconda sezione, "indirizzo", verranno inseriti i seguenti dati:

- Indirizzo di residenza;
- Numero civico;
- CAP;
- Comune;
- Provincia (menù a tendina);

Infine, la sezione "Riepilogo" presenterà un riepilogo di tutti i dati inseriti, permettendo all'utente di verificare i dati inseriti prima di procedere con l'invio della richiesta di registrazione.

### Registrazione di un socio maggiorenne

Nel caso di socio maggiorenne, i passaggi sono i medesimi di quelli previsti per la registrazione di un socio minorenne, con la differenza che non ci saranno i campi per i dati dei genitori.

### Conferma della registrazione di un socio qualsiasi da parte di un capo

Una volta pervenuta a un capo qualsiasi la richiesta di registrazione di un socio, il capo, prima di procedere all'eventuale assegnazione a una branca, dovrà verificarne i dati e accettare o rifiutare la registrazione. In caso di accettazione, il capo dovrà assegnare il socio alla branca corretta e, nel caso in cui si tratti di un socio minorenne, dovrà inserire i dati di uno o due genitori, uno dei quali deve essere obbligatorio, se non già inseriti dal socio stesso. Se non accetta, la richiesta verrà rifiutata e il socio non potrà registrarsi, dovendo effettuare, nel caso, una nuova richiesta di registrazione.

### Registrazione di un capo

Se un utente si vuole registrare come capo, i passaggi sono diversi. Dovrà essere il capo gruppo, o uno dei capi a cui è stato permesso al capo gruppo di agire e aggiungere nuovi capi, ad inserire i dati del nuovo capo, tramite la dashboard apposita. In particolare, verrà inserita solo l'email. Una volta inserita l'email del capo da aggiungere, esso riceverà una mail contenente un link specifico per terminare il processo di registrazione tramite l'app. Dopodiché, il nuovo capo potrà inserire i propri dati, che sono: nome, cognome, genere, data di nascita, email (che verrà recuperata da quella già inserita in precedenza), numero di telefono, indirizzo, numero civico, CAP, comune, provincia, password e branca di cui fanno parte (che possono essere 4: Branco, Reparto, Clan/Fuoco o Gruppo, successivamente inseriranno il loro ruolo: se selezionano Branco, i ruoli potranno essere "Capo Branco", "Aiuto Capo Branco"; se selezionano Reparto, potranno essere "Capo Reparto", "Aiuto Capo Reparto"; se selezionano Clan/Fuoco, potranno essere "Capo Clan", "Capo Fuoco", "Aiuto Capo Clan", "Aiuto Capo Fuoco","Maestro dei Novizi"; se selezionano Gruppo, potranno essere "Capo Gruppo", "Capo a disposizione", "Assistente Ecclesiastico"). Se il capo ha selezionato il Branco, ci sarà un campo in più in cui verrà chiesto di inserire il suo nome della giungla ("Soprannome"). Ciò accadrà anche ogni volta che un capo qualsiasi viene spostato in Branco, bisognerà aggiornare il suo nome della giungla. Se un capo esce dal Branco e va in un altra branca, il suo nome della giungla non verrà più visualizzato. Questo processo è così strutturato per rendere più completa, più sicura e meno probabile la registrazione di un capo tramite form di registrazione generico già previsto nell'app. In aggiunta, i capi avranno poi la possibilità, sempre tramite la dashboard apposita, di modificare i propri dati e, se autorizzati dal capo gruppo, potranno inserire i dati di nuovi capi da far registrare.

### Login

La pagina di login prevede un form a due campi, email e password. Una volta inseriti correttamente i dati, l'utente potrà accedere all'app. Ci saranno un campo per l'email, un campo per la password, un pulsante per accedere, un pulsante per recuperare la password e un pulsante per registrarsi. Il form di login sarà accessibile tramite la pagina principale dell'app. In caso di errore di inserimento dati, l'utente dovrà reinserire i dati (con visualizzazione del messaggio d'errore). In caso di recupero password, l'utente verrà indirizzato ad una pagina in cui inserire la propria email, dopodiché riceverà una mail con un link per reimpostare la password. In caso di registrazione, l'utente verrà indirizzato alla pagina di registrazione. In aggiunta, in base al proprio ruolo, dopo essersi registrato e aver effettuato il login, l'utente verrà indirizzato alla home page apposita a lui riservata.

### Home page generale

La home page è la pagina principale dell'app, accessibile dopo aver effettuato il login. Si differenzierà per alcuni determinati aspetti in base al ruolo dell'utente (che verranno specificate nelle sezioni successive), ma avrà anche alcune sezioni in comune tra tutti i ruoli, qui spiegate:

- Barra di navigazione inferiore (in stile Material Design 3), con le sezioni, in ordine, "Home" (attuale), "Calendario", "Ricerca" e "Profilo". Queste sezioni saranno approfondite successivamente. Ora ci si concentra sulla pagina "Home".

A livello generale, per tutti gli utenti, la pagina "Home" presenta:

- Un'area in alto a sinistra in cui viene mostrato "Buongiorno (oppure Buon pomeriggio o Buona sera, in base all'orario), nome!" (dove "nome" è il nome dell'utente. Se l'utente è un capo appartenente al branco, verrà visualizzato il suo "soprannome" o nome della giungla);
- Sotto di essa, centrata e che prende tutto lo spazio orizzontale, ci sarà una card con una frase di Baden-Powell o comunque relativa allo scautismo, che sarà composta da testo (la frase) e l'autore. La frase è meglio che compaia in uno stile grafico da citazione. La frase sarà estrapolata da un pool in maniera casuale e sarà visibile una frase al giorno (cambia a mezzanotte, ora italiana);
- Sotto di essa, un'altra barra orizzontale che mostrerà un piccolo riepilogo dei dati dell'utente: foto profilo, nome, cognome e branca di appartenenza (dove comparirà anche il ruolo di capo se l'utente è un capo). Se l'utente è un capo e appartiene al branco, comparirà anche il suo "soprannome" o nome della giungla. L'utente, cliccando su questa barra, potrà accedere alla sezione del proprio profilo, approfondita in seguito;
- Un riepilogo generale delle attività in programma più imminenti, mostrate in card più piccole disposte verticalmente (dall'alto verso il basso, le attività sono mostrate in ordine cronologico).

Il riepilogo mostrato in ogni attività presente nel riepilogo di cui sopra presenterà (verranno mostrate le attività relative alla propria branca oppure se coinvolgono l'intero gruppo):

- Il titolo dell'attività, scritto in grassetto in alto;
- Un breve riassunto del luogo in cui si svolgerà l'attività (anche non completo), scritto sotto il titolo in corsivo;
- La data e l'ora di inizio dell'attività, scritte sotto il riassunto del luogo in corsivo;
- Il costo dell'attività, se presente, scritto sotto la data e l'ora, in grassetto;

All'utente poi, compariranno delle informazioni determinate dal suo profilo:

### Sezione home page soci censiti (maggiorenni e non)

- Eventuali prove di specialità da presentare;
- Eventuali compiti o incarichi da svolgere (anche per singole uscite o campi). Se presenti già nella lista dei riepiloghi attività di cui qui sopra, anche nella lista delle attività sopra comparirà una scritta che specificherà la presenza di tale prova o compito associata alla singola attività;

### Sezione home page capi

- Sarà visibile una sezione con diversi pulsanti che rimanderanno a funzionalità specifiche per i capi:

  - Creazione di una nuova attività (riunione, uscita, campo etc.);
  - Visualizzazione e gestione di tutti i soci appartenenti alla stessa branca del capo;
  - Visualizzazione e gestione dei soci appartenenti a tutto il gruppo;
  - Aggiunta di un nuovo capo da registrare (se abilitato dal capo gruppo; se non abilitato, tale pulsante non comparirà);
  - Modifica i dati di un'attività già presente nel calendario (valido per gli eventi della propria branca. Se gli eventi coinvolgono altre branche o il gruppo intero, la modifica sarà possibile solo se il capo è tra quelli autorizzati ad eseguire tale operazione, come stabilito dal capo gruppo).

### Sezione home page capi gruppo

- Oltre alle funzionalità già presenti nella home page dei capi, ci sarà anche la possibilità di:
  - Gestione di tutti i soci del proprio gruppo (censimento del socio, modifica dei propri dati etc.);
  - Visualizzazione e modifica di tutte le attività previste per il proprio gruppo;
  - Assegnazione di incarichi e compiti ai capi del proprio gruppo (anche per singole uscite o campi);
  - Modifica dei dati di un capo (per esempio la branca a cui appartiene, il ruolo che ricopre, ecc.).
