---
name: Scouting App Design System
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
  error: '#C62828'
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
  surface-white: '#FFFFFF'
  branco-yellow: '#FFEB3B'
  reparto-green: '#388E3C'
  clan-red: '#B71C1C'
  success: '#2E7D32'
  security-shield: '#455A64'
typography:
  display-lg:
    fontFamily: Work Sans
    fontSize: 45px
    fontWeight: '700'
    lineHeight: 52px
  headline-lg:
    fontFamily: Work Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Work Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-lg:
    fontFamily: Work Sans
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Work Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-margin: 16px
  gutter: 16px
  section-gap: 24px
  touch-target: 48px
---

# Progettazione app "Scouting"

## Descrizione generale del progetto

L'app "Scouting" è un'applicazione mobile (iOS, Android e desktop) sviluppata con Flutter, il cui scopo principale è connettere i membri del gruppo scout, consentendo loro di poter aggiornare i loro profili personali, mantenere anche le loro informazioni sensibili, come allergie e altri dati medici, dati di contatto propri e dei loro genitori, come recapiti telefonici e indirizzi e-mail, oltre a consentire la visualizzazione dei pagamenti effettuati per diverse attività (censimento, uscite, campi ecc.).  Questa app è destinata ai membri del gruppo scout AGESCI Bari 10. Se i ragazzi (educandi) possono modificare solo le loro informazioni sensibili, i capi invece possono modificarle per i propri educandi, oltre a poter inserire pagamenti, visualizzare statistiche ecc. Nell'applicazione potranno essere inseriti anche eventi con ricezione di notifiche, come per esempio semplici riunioni, oppure uscite e campi. I ragazzi saranno divisi nelle tre branche, quindi Branco, Reparto e Clan/Fuoco.

Il focus principale dell'intera applicazione, che deve essere il punto cardine sia dall'inizio della sua progettazione sino alla sua intera realizzazione, è quello della sicurezza. I dati di ogni membro, essendo sensibili, devono essere conservati in database sicuri e protetti a più livelli. Si deve prevedere l'autenticazione a più fattori per l'accesso e ogni volta che si deve visualizzare/modificare un dato sensibile, deve essere richiesta una verifica biometrica, oltre al passwrod e/o all'OTP (One-Time Password), che verrà inviato tramite email o SMS. I dati di ogni membro devono essere criptati, sia a riposo che in transito. Devono essere previsti dei ruoli ben definiti: ragazzi (educandi), capi, capi unità (responsabili di una branca), capi gruppo (responsabili dell'intero gruppo). Il design dell'app deve essere minimalista ed elegante, seguendo le linee guida del Material Design 3.

Il miglior Database per questo progetto: Supabase (PostgreSQL)
Personalmente, ritengo che Supabase sia la scelta perfetta per il tuo progetto. È un'alternativa open-source a Firebase, ma basata su un database relazionale solido e storico come PostgreSQL.

Ecco perché si sposa perfettamente con il tuo design:

Dati Relazionali (Perfetto per i pagamenti e gerarchie): Avendo a che fare con "pagamenti effettuati", "censimento", storici clinici e divisione in gruppi (Branco, Reparto, Clan), un database relazionale (SQL) ti garantisce che i dati siano sempre coerenti (integrità referenziale). In un DB NoSQL i dati finanziari possono diventare complessi da gestire senza sbavature.
Row Level Security (RLS): È la killer-feature per il tuo requisito sui ruoli. RLS ti permette di scrivere regole di sicurezza direttamente nel database. Puoi dire al DB: "Se l'utente ha ruolo 'educando', fagli leggere solo la riga con il suo ID. Se ha ruolo 'capo unità', fagli leggere tutte le righe degli utenti che appartengono alla sua branca". Questo rende impossibile per un utente accedere a dati non suoi, anche se l'app dovesse avere dei bug.
Autenticazione e MFA integrate: Supabase Auth supporta nativamente l'autenticazione a più fattori (MFA) e l'invio di OTP tramite Email o SMS (per gli SMS dovrai agganciare un provider come Twilio, mentre le email sono gratuite).
Crittografia: I dati sono criptati at-rest (a riposo) e in-transit (in transito). Inoltre, usando PostgreSQL, puoi implementare funzioni per la crittografia a livello di singola colonna per i campi medici (es. estensione pgcrypto), aggiungendo un ulteriore livello di sicurezza.
Integrazione con Flutter: Esiste un SDK ufficiale per Flutter (supabase_flutter) eccellente e costantemente aggiornato.
L'alternativa (Il "Classico"): Firebase (Firestore)
Se preferisci rimanere nell'ecosistema Google, Firebase è l'alternativa principale.

Pro: Firebase Authentication è il sistema più maturo in circolazione per MFA e OTP. Le notifiche push (per gli eventi) sono gestite nativamente con Firebase Cloud Messaging (FCM).
Contro: Essendo NoSQL (a documenti), gestire transazioni di pagamento o relazioni complesse (es. "mostrami tutti i ragazzi del reparto X che non hanno pagato la quota Y") è meno naturale rispetto al linguaggio SQL. Inoltre le Firestore Security Rules possono diventare molto verbosere e complesse per gerarchie di ruoli a più livelli rispetto all'RLS di Supabase.
Si può prevedere di usare un DB gratuito?
Assolutamente sì. Con 120-130 utenti, il tuo progetto rientra ampiamente (e direi quasi permanentemente) nei limiti dei piani gratuiti di queste piattaforme.

Supabase (Piano Free): Ti offre un database da 500 MB (che per soli dati testuali, date e cifre di 130 persone è un'infinità, ci vorranno anni per riempirlo), 50.000 Utenti Attivi Mensili (MAU) e limiti di banda generosissimi.
Firebase (Piano Spark): Ti offre 1 GB di spazio di archiviazione, 50.000 letture al giorno e 20.000 scritture al giorno. Anche qui, per 130 utenti che fanno accessi saltuari o settimanali, sei perfettamente coperto.
L'unico potenziale costo che potresti dover affrontare in futuro riguarda gli SMS per l'OTP. Se decidi di inviare l'OTP tramite SMS, i provider (come Twilio, o lo stesso Firebase dopo un tot di SMS gratuiti) si fanno pagare a singolo messaggio inviato. Se invece implementi l'OTP tramite Email o tramite App Authenticator (es. Google Authenticator), il costo sarà esattamente zero.

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

Nome dell'app: Scouting

Realizzazione: Dart con Flutter

Database: Supabase (database gratuito). SICUREZZA MASSIMA FONDAMENTALE, i dati sensibili, come allergie, malattie, ecc. devono essere criptati e protetti, così come tutti i dati sanitari dei ragazzi e i dati di pagamento. Anche le transazioni che avvengono all'interno dell'app, come la pagamento delle quote, devono essere sicure e protette, possibilmente a più livelli. L'accesso all'app deve essere sicuro e protetto. Deve garantire la privacy e la riservatezza dei dati sensibili di ciascun membro. Deve essere in grado di funzionare offline, sincronizzando i dati quando torna online. Oltre a ciò, Supabase offre una vasta gamma di funzionalità, come autenticazione, database, archiviazione file, notifiche push e molto altro.

Logo: da definire (il logo deve essere semplice, moderno e facilmente riconoscibile). Possibilmente che richiami il colore rosso e il nodo piano, simbolo del gruppo AGESCI Bari 10.

Colori base: Rosso (colore primario), Blu (colore secondario), Bianco (colore di sfondo). Da utilizzare questi colori in tutta l'app in manera coerente.

Font: da definire (il font deve essere semplice, moderno e facilmente riconoscibile).

Basato su Material Design 3

## Passi generali per la realizzazione del progetto

1. Bozza grafica dell'applicazione
2. Strutturazione delle varie sezioni dell'app (prima descrivendole dettagliatamente)con l'uso di blocchi di codice riutilizzabili per i vari elementi, come bottoni, grafici, ecc.
3. Impostazione del database con l'uso di Supabase
4. Integrazione tra app e database
5. Test di funzionamento
6. Pubblicazione dell'applicazione

La parte fondamentale è la strutturazione delle varie sezioni dell'app con l'uso di blocchi di codice riutilizzabili per i vari elementi, come bottoni, grafici, ecc. Questo permetterà di mantenere il codice pulito, organizzato e facile da mantenere nel tempo.

Devono essere previsti diversi tipi di accesso. Tutti gli utenti possono visualizzare i dati degli altri utenti (tutti i ragazzi e i capi) ma non possono modificare i dati altrui, ovviamente, eccetto i capi che possono modificare i dati di tutti i ragazzi. Inoltre ci sono i soci maggiorenni (18+) che hanno alcuni poteri in più, come per esempio la possibilità di autorizzare uscite e campi, ma non possono modificare i dati altrui. Infine ci sono i capi che hanno tutti i poteri, come per esempio la possibilità di autorizzare uscite e campi, ma non possono modificare i dati altrui. Ogni utente avrà una sua foto profilo che sarà visibile a tutti gli altri utenti.

1. Genitore (visualizzazione in sola lettura dei dati del proprio figlio e di tutti gli altri utenti, con possibilità di autorizzare uscite e campi e di poter pagare direttamente in app eventuali spese come censimenti, uscite, campi ecc.). Per i soci minorenni, i genitori possono compilare direttamente in app i vari PDF (con firma) del censimento, delle dichiarazioni mediche, in maniera tale che, una volta inviate, i capi possono leggere subito i dati in PDF compilati e firmati. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente.

2. Socio censito (visualizzazione dei propri dati e di tutti gli altri utenti, possibilità di modifica dei propri dati (la cui conferma deve comunque essere accettata da un capo) e autorizzazione uscite e campi, se maggiore di 18 anni). Anche i soci censiti hanno possibilità di pagare direttamente in app eventuali spese come censimenti, uscite, campi ecc, anche se minorenni. Invece i soci minorenni non hanno possibilità di autorizzare uscite e campi, ma possono comunque pagare eventuali spese come censimenti, uscite, campi ecc. Ogni socio censito potrà appartenere a una tra tre diverse branche: Branco, Reparto e Clan/Fuoco. I soci appartenenti a Branco e Reparto potranno visualizzare, sul loro profilo, eventuali specialità e competenze acquisite (che sono diverse tra il Branco e il Reparto, mentre i soci del Clan/Fuoco non possono avere ne specialità ne competenze). Ogni specialità e competenza ha una sua immagine e una sua descrizione. Ogni socio, però, potrà aggiornare il proprio profilo, inserendo due distinte descrizioni: impegni presi durante l'anno e obiettivi da raggiungere (di solito tramite gli impegni presi). Quindi impegni e obiettivi sono collegati. Ogni socio, poi, potrà decidere se rendere visibili a tutti oppure visibili solo per sè stesso gli impegni e gli obiettivi nel proprio profilo. Per i soci maggiorenni, l'unica differenza è che oltre ad autorizzare uscite e campi, possono anche pagarli, così come i capi. Inoltre i soci maggiorenni possono compilare direttamente in app i vari PDF (con firma) del censimento, delle dichiarazioni mediche, in maniera tale che, una volta inviati, i capi possono leggere subito i dati in PDF compilati e firmati. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente. Per i soci minorenni, i genitori possono compilare direttamente in app i vari PDF (con firma) del censimento, delle dichiarazioni mediche, in maniera tale che, una volta inviate, i capi possono leggere subito i dati in PDF compilati e firmati. I dati in PDF, una volta inviati, devono essere accettati dai capi. Se accettati, non sono più modificabili fino all'anno successivo, a meno che un capo non ne faccia richiesta tramite l'app, mentre in caso di rifiuto, i dati devono essere modificati e inviati nuovamente. (serviranno quindi eventuali librerie per compilare e firmare file in PDF)

3. Capo (visualizzazione di tutti i dati degli utenti, possibilità di modifica dei dati di tutti gli utenti, compresi censimenti, pagamenti ecc, autorizzazione uscite e campi). I capi possono essere di vario tipo: Aiuto capo, capo unità, capo gruppo, capo a disposizione, ecc. Ognuno avrà privilegi diversi in base al proprio ruolo. Ad esempio un aiuto capo avrà privilegi minori rispetto a un capo gruppo. Il capo gruppo, comunque, avrà accesso completo ai privilegi e potrà decidere di assegnarli ad un qualsiasi altro capo, tramite una dashboard apposita. Ogni capo, poi, apparterrà a una branca: Branco, Reparto e Clan/Fuoco (oppure gruppo, nel caso dei capi gruppo e di capi a disposizione). I capi appartenenti al Branco potranno inserire il loro "soprannome" (nome della giungla) che dovrà essere visualizzato al posto del loro nome, sia nella loro scheda profilo che in qualsiasi altra sezione dell'app dove loro siano presenti. Gli altri capi, invece, manterranno il loro semplice nome, invece.

Maggiori informazioni riguardo i singoli soci, le specialità e le competenze e i capi saranno poi aggiunti nelle descrizioni più dettagliate delle sezioni singole dell'app.
