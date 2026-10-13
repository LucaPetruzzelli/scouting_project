# Progettazione app "Scouting"

## Descrizione generale del progetto

L'app "Scouting" è un'applicazione mobile (iOS, Android e desktop) sviluppata con Flutter, il cui scopo principale è connettere i membri del gruppo scout, consentendo loro di poter aggiornare i loro profili personali, mantenere anche le loro informazioni sensibili, come allergie e altri dati medici, dati di contatto propri e dei loro genitori, come recapiti telefonici e indirizzi e-mail, oltre a consentire la visualizzazione dei pagamenti effettuati per diverse attività (censimento, uscite, campi ecc.).  Questa app è destinata ai membri del gruppo scout AGESCI Bari 10. Se i ragazzi (educandi) possono modificare solo le loro informazioni sensibili, i capi invece possono modificarle per i propri educandi, oltre a poter inserire pagamenti, visualizzare statistiche ecc. Nell'applicazione potranno essere inseriti anche eventi con ricezione di notifiche, come per esempio semplici riunioni, oppure uscite e campi. I ragazzi saranno divisi nelle tre branche, quindi Branco, Reparto e Clan/Fuoco.

Il focus principale dell'intera applicazione, che deve essere il punto cardine sia dall'inizio della sua progettazione sino alla sua intera realizzazione, è quello della sicurezza. I dati di ogni membro, essendo sensibili, devono essere conservati in database sicuri e protetti a più livelli (utilizzando le Row Level Security). Si deve prevedere l'autenticazione a due fattori (2FA/MFA) in fase di registrazione per tutelare l'account. Inoltre, ogni volta che si deve visualizzare o firmare un dato sensibile in-app, deve essere richiesta una verifica biometrica o, in alternativa, un PIN di sicurezza di 4/6 cifre configurato localmente. I dati di ogni membro devono essere criptati, sia a riposo che in transito. Devono essere previsti dei ruoli ben definiti: ragazzi (educandi), capi, capi unità (responsabili di una branca), capi gruppo (responsabili dell'intero gruppo). Il design dell'app deve essere minimalista ed elegante, seguendo le linee guida del Material Design 3.

Il miglior Database per questo progetto: Supabase (PostgreSQL)
Personalmente, ritengo che Supabase sia la scelta perfetta per il tuo progetto. È un'alternativa open-source a Firebase, ma basata su un database relazionale solido e storico come PostgreSQL.

Ecco perché si sposa perfettamente con il tuo design:

Dati Relazionali (Perfetto per i pagamenti e gerarchie): Avendo a che fare con "pagamenti effettuati", "censimento", storici clinici e divisione in gruppi (Branco, Reparto, Clan), un database relazionale (SQL) ti garantisce che i dati siano sempre coerenti (integrità referenziale). In un DB NoSQL i dati finanziari possono diventare complessi da gestire senza sbavature.

Autenticazione e MFA integrate: Supabase Auth supporta nativamente l'autenticazione a due fattori (2FA). Per i capi (che accedono a molti dati sensibili) è fortemente consigliato l'uso di un'App Authenticator (TOTP, es. Google Authenticator). Per i soci e i genitori, l'accesso avverrà tramite Email/Password, potendo attivare Email OTP o TOTP come secondo fattore (la 2FA verrà richiesta solo al primo accesso sul dispositivo). Qualora non venga attivata la 2FA, all'utente sarà preclusa la possibilità di inserire dati importanti come le ricevute dei bonifici.
Crittografia: I dati sono criptati at-rest (a riposo) e in-transit (in transito). Inoltre, usando PostgreSQL, puoi implementare funzioni per la crittografia a livello di singola colonna e dei file (tramite pgcrypto e Supabase Vault) per i campi medici, garantendo la massima sicurezza.
Integrazione con Flutter: Esiste un SDK ufficiale per Flutter (supabase_flutter) eccellente e costantemente aggiornato.
L'alternativa (Il "Classico"): Firebase (Firestore)
Se preferisci rimanere nell'ecosistema Google, Firebase è l'alternativa principale.

Struttura della Sicurezza e Gestione dei Dati Sensibili
Poiché la sicurezza è il "punto cardine" dell'app, l'architettura dovrà seguire questo flusso rigoroso per i dati medici e i moduli privacy:

1. **Protezione In-App (Biometria e PIN):** Usa il pacchetto Flutter `local_auth` per la biometria (FaceID/Impronta) per proteggere la visualizzazione a schermo dei documenti. Per chi non dispone di biometria o come metodo di fallback veloce, l'app richiederà un PIN locale di 4/6 cifre configurato dall'utente (utile per autorizzare rapidamente operazioni, come la visualizzazione dei PDF).
2. **Crittografia Lato Database e RLS:** I documenti PDF medici e i dati testuali sensibili (es. allergie) saranno fortemente crittografati sul server (tramite `pgcrypto` o Supabase Vault).
3. **Decrittazione Condizionata (Coerenza dei Ruoli):** Quando l'app richiede un dato medico, il database verificherà tramite le Row Level Security (RLS) *chi* sta effettuando la richiesta. Il dato verrà decifrato e inviato al client (tramite connessione TLS sicura) **solo ed esclusivamente se** il richiedente è il genitore dell'utente oppure un capo scout responsabile autorizzato per quella specifica branca. Questo garantisce che i capi possano sempre fare il loro lavoro (leggere e approvare le schede), proteggendo al contempo il file da accessi non autorizzati.

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

LA SOLUZIONE GRATUITA PER IOS: La PWA (Progressive Web App) Dato che l'app è in Flutter (che compila perfettamente anche per il Web), la soluzione migliore e a costo zero per chi ha l'iPhone è questa:

Compili l'app per il web (flutter build web).
La ospiti gratuitamente su un servizio come Firebase Hosting, Vercel o GitHub Pages.
Dai il link agli utenti iOS e dici loro di aprirlo con Safari.
Lì dentro, istruisci gli utenti a cliccare sul tasto "Condividi" di Safari e selezionare "Aggiungi alla schermata Home".
Il risultato: L'utente avrà l'icona dell'app Scout sulla sua home, l'app si aprirà a schermo intero senza la barra di ricerca del browser (sembrerà un'app nativa al 100%) e, soprattutto, gli aggiornamenti saranno automatici: ogni volta che tu aggiorni il sito web, la loro app si aggiornerà da sola al riavvio successivo!

L'applicazione deve essere stabile, leggera, facile da usare, intuitiva e graficamente accattivante. Non deve avere bug, né crash, né blocchi, né rallentamenti. Deve essere in grado di funzionare offline, sincronizzando i dati quando torna online. Deve essere in grado di inviare notifiche push agli utenti, come per esempio semplici riunioni, oppure uscite e campi. Inoltre, l'app deve essere in grado di funzionare su diverse piattaforme, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi sistemi operativi, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi browser, come Safari, Chrome e Firefox. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi sistemi operativi, come iOS, Android e Windows. Inoltre, la sicurezza deve essere al primo posto. I dati sensibili, come allergie, malattie, ecc. devono essere criptati e protetti, così come tutti i dati sanitari dei ragazzi e i dati di pagamento. L'accesso all'app deve essere sicuro e protetto. Deve essere in grado di funzionare su diverse piattaforme, come iOS, Android e Windows. Deve essere in grado di funzionare su diversi dispositivi, come smartphone, tablet e computer. Deve essere in grado di funzionare su diversi browser, come Safari, Chrome e Firefox.

- Progettazione delle schermate in Figma

## Distribuzione e Aggiornamenti In-App (OTA)

L'obiettivo è distribuire l'applicazione in maniera completamente gratuita, garantendo **aggiornamenti in-app automatici** (Over-The-Air, OTA). Gli OTA permettono all'utente di ricevere l'aggiornamento (nuove funzionalità o bug fix) direttamente al successivo avvio dell'app, senza dover scaricare nulla esternamente o cliccare su link terzi.

Per garantire che questa architettura rimanga al 100% gratuita per tutti (e per aggirare i costi e le restrizioni degli store ufficiali, in particolare i 99$/anno richiesti da Apple per iOS), si adotterà questa strategia di distribuzione divisa per sistema operativo:

1. **Android (App Nativa con Shorebird):**
   - **Distribuzione:** I soci Android scaricheranno un singolo file d'installazione (`.apk`) inviato dai capi (nessun costo legato al Play Store).
   - **Aggiornamenti In-App:** L'app integrerà **Shorebird**, uno strumento ufficiale per l'ecosistema Flutter. Shorebird è in grado di inviare patch del codice (OTA) direttamente ai dispositivi. Quando pubblichi un aggiornamento, l'app Android lo scaricherà invisibilmente in background e lo applicherà in automatico al riavvio successivo. È un servizio completamente gratuito per le dimensioni del tuo gruppo scout.

2. **iOS (Apple) e Alternativa Desktop Universale (Progressive Web App - PWA):**
   - **Il blocco iOS:** Apple vieta rigorosamente la distribuzione nativa permanente fuori dall'App Store senza un abbonamento sviluppatore a pagamento. L'installazione gratuita manuale "scade" dopo soli 7 giorni, rendendola invivibile.
   - **La soluzione PWA:** Per avere l'app su iOS e Desktop in modo 100% gratuito e con aggiornamenti istantanei, l'app verrà servita come PWA (Progressive Web App). L'utente aprirà semplicemente un link dal browser e cliccherà "Aggiungi alla schermata Home" (su iOS) o "Installa App" (su Desktop). L'app verrà aggiunta al dispositivo con tanto di icona, funzionando a schermo intero esattamente come un'app nativa.
   - **Aggiornamenti In-App PWA:** Essendo basata sulle tecnologie web, per la PWA **l'aggiornamento è letteralmente istantaneo**. Quando rilasci un aggiornamento, alla successiva riapertura dell'app da parte dell'utente, questa caricherà automaticamente la versione aggiornata. Nessun file da scaricare, nessuna autorizzazione esterna richiesta: 100% gratuito e invisibile.

## Dati generali e priorità dell'app

Nome dell'app: Scouting

Realizzazione: Dart con Flutter

Database: Supabase (database gratuito). SICUREZZA MASSIMA FONDAMENTALE, i dati sensibili, come allergie, malattie, ecc. devono essere criptati e protetti, così come tutti i dati sanitari dei ragazzi e i dati di pagamento. Anche le transazioni che avvengono all'interno dell'app, come la pagamento delle quote, devono essere sicure e protette, possibilmente a più livelli. L'accesso all'app deve essere sicuro e protetto. Deve garantire la privacy e la riservatezza dei dati sensibili di ciascun membro. Deve essere in grado di funzionare offline, sincronizzando i dati quando torna online. Oltre a ciò, Supabase offre una vasta gamma di funzionalità, come autenticazione, database, archiviazione file, notifiche push e molto altro.

Logo: img/logo.png

Colori base: Rosso (colore primario), Blu (colore secondario). Da utilizzare questi colori in tutta l'app in manera coerente.

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

1. Genitore (visualizzazione in sola lettura dei dati del proprio figlio e di tutti gli altri utenti, con possibilità di autorizzare uscite e campi). **Non sono previsti pagamenti in-app**. I genitori dei soci minorenni si occupano della gestione burocratica: tramite la sezione privata del figlio compilano e firmano in-app i moduli PDF per il censimento (inclusa la ricevuta del bonifico) e le dichiarazioni mediche, sottoponendoli poi alla validazione dei capi (come dettagliato nella sezione "Documenti Personali e Censimento"). Tutto questo processo prevede scambi di notifiche in app tra i vari agenti: i capi ricevono una notifica quando un genitore carica un documento o una ricevuta, e i genitori ricevono una notifica quando questi documenti vengono accettati o rifiutati, in maniera tale da rimanere sempre al corrente della situazione.

2. Socio censito (visualizzazione dei propri dati e di tutti gli altri utenti, possibilità di modifica dei propri dati (la cui conferma deve comunque essere accettata da un capo) e autorizzazione uscite e campi, se maggiore di 18 anni). I soci minorenni non hanno possibilità di autorizzare uscite e campi. **Non sono previsti pagamenti in-app**. Il saldo delle quote per uscite e campi è gestito tramite una casella di spunta di sola lettura per il socio. Ogni socio censito potrà appartenere a una tra tre diverse branche: Branco, Reparto e Clan/Fuoco. I soci appartenenti a Branco e Reparto potranno visualizzare, sul loro profilo, eventuali specialità e competenze acquisite (che sono diverse tra il Branco e il Reparto, mentre i soci del Clan/Fuoco non possono avere ne specialità ne competenze). Ogni specialità e competenza ha una sua immagine e una sua descrizione. Ogni socio, però, potrà aggiornare il proprio profilo, inserendo due distinte descrizioni: impegni presi durante l'anno e obiettivi da raggiungere (di solito tramite gli impegni presi). Quindi impegni e obiettivi sono collegati (prevedere collegamento anche in app. Ad esempio, se un utente clicca sul proprio obiettivo, potrà vedere quali impegni dovrà portare a termine per raggiungerlo). **Regola di visibilità:** Le specialità e le competenze conquistate sono pubbliche e visibili da tutti i membri del gruppo; al contrario, **impegni e obiettivi sono dati privati** e saranno visibili unicamente al socio stesso (nel proprio profilo), ai suoi genitori (se minorenne) e ai capi. Per i soci maggiorenni, l'unica differenza è che, oltre ad autorizzare uscite e campi, gestiscono autonomamente la burocrazia: tramite la loro sezione privata possono compilare e firmare in-app i moduli PDF per il censimento (inclusa la ricevuta del bonifico) e le dichiarazioni mediche, inviandoli poi ai capi (come descritto nella sezione "Documenti Personali e Censimento").

3. Capo (visualizzazione di tutti i dati degli utenti, possibilità di modifica dei dati di tutti gli utenti, compresi censimenti, pagamenti ecc, autorizzazione uscite e campi). I capi possono essere di vario tipo: Aiuto capo, capo unità, capo gruppo, capo a disposizione, ecc. Ognuno avrà privilegi ben definiti in base al proprio ruolo. **Gerarchia delle autorizzazioni:** i "capi gruppo" possiedono tutte le autorizzazioni di inserimento, modifica e rimozione attive sull'intero sistema; inoltre, tramite una dashboard apposita, possono modificare a loro piacimento le autorizzazioni di tutti gli altri capi. I "capi unità" possiedono tutte le autorizzazioni attive ma limitatamente alla branca di loro competenza; tramite la loro sezione, possono modificare le autorizzazioni degli altri capi della propria branca che non ricoprono il ruolo di capo unità (es. gli "aiuto capo"). Ogni capo, in generale, apparterrà a una branca: Branco, Reparto e Clan/Fuoco (oppure "gruppo", nel caso dei capi gruppo e capi a disposizione). I capi appartenenti al Branco potranno inserire il loro "soprannome" (nome della giungla) che dovrà essere visualizzato al posto del loro nome, sia nella loro scheda profilo che in qualsiasi altra sezione dell'app dove loro siano presenti. Gli altri capi manterranno il loro nome anagrafico.

Maggiori informazioni riguardo i singoli soci, le specialità e le competenze e i capi saranno poi aggiunti nelle descrizioni più dettagliate delle sezioni singole dell'app.

## Spiegazione specifica dei ruoli, dei privilegi e delle funzioni di ciascun tipo di utente

### Socio censito (minorenne)

Funzioni e privilegi:

- Essendo un socio censito, il socio in questione potrà visualizzare i propri dati e di tutti gli altri soci del gruppo (in quest'ultimo caso, la visualizzazione sarà in sola lettura). Non potrà ovviamente visualizzare dati medici, di pagamento e altri dati privati e che devono rimanere visibili ai capi o ai genitori dei soci minorenni, ai soci minorenni stessi e ai soci maggiorenni ;
- Il socio potrà modificare i propri dati, inserendo nello specifico foto profilo, aggiornando i recapiti, inserendo le specialità e le competenze conquistate negli anni precedenti e quelle da conquistare durante l'anno in corso (devono essere due sezioni distinte), obiettivi da conquistare durante l'anno in corso e impegni presi durante l'anno in corso. N.B. le specialità e le competenze del Branco sono diverse da quelle del reparto, e per questo differiscono in nome, immagine e descrizione. Inoltre i soci del Clan/Fuoco non possono avere ne specialità ne competenze, ma potranno inserire solo impegni ed obiettivi. Le richieste relative alla modifica dei propri dati dovranno essere approvate da un capo, ma solamente quelle relative ai dati anagrafici e ai dati riguardanti le specialità e le competenze conquistate negli anni precendenti e quelle da conquistare durante l'anno in corso.
- **Appartenenza alle Branche, Età e Sotto-gruppi**: Il socio apparterrà a una branca specifica in base all'età e all'anno di progressione:
  - **Branco (8-12 anni, durata 4 anni)**: I soci sono divisi in *Sestiglie*. I ruoli disponibili sono: *Capo Sestiglia*, *Vice Capo Sestiglia* e *Membro della Sestiglia* (senza ruolo di rilievo). I lupetti potranno visualizzare la Legge del Branco, la Promessa del Lupetto e la lista delle specialità del Branco (in branco non esistono competenze).
  - **Reparto (12-16 anni, durata 4 anni)**: I soci sono divisi in *Squadriglie*. I ruoli disponibili sono: *Capo Squadriglia*, *Vice Capo Squadriglia* e *Membro della Squadriglia*.
    - **Attività di Squadriglia**: Il Capo Squadriglia ha l'autorizzazione per inserire nel calendario un'attività periodica settimanale chiamata "Riunione di Squadriglia", che coinvolge tutta la sua squadriglia.
    - **Alta Squadriglia**: I soci che frequentano il terzo e quarto anno di Reparto formano automaticamente l'"Alta Squadriglia". Questo gruppo può avere attività e riunioni a sé stanti rispetto al resto del Reparto o alle singole squadriglie.
    In app, i soci del Reparto visualizzeranno la Legge Scout, la Promessa Scout e le loro specifiche specialità e competenze.
  - **Clan/Fuoco e Noviziato (16-21 anni, durata 4-5 anni)**: Il primo anno costituisce il *Noviziato*, ma il novizio fa automaticamente parte anche del Clan/Fuoco. Nel Clan/Fuoco **non esistono gerarchie o divisioni di ruoli** tra i ragazzi (sono tutti allo stesso livello). In base all'attività, l'evento a calendario potrà coinvolgere solo il Noviziato, solo il Clan/Fuoco, o entrambi. I soci visualizzeranno la Promessa Scout, la Legge Scout e la Carta di Clan.
  In base alla branca e all'eventuale sotto-gruppo (es. Alta Squadriglia o specifica Sestiglia/Squadriglia), il calendario si adatterà mostrando solo gli eventi pertinenti al socio.
- I soci appartenenti al Reparto, una volta che le loro specialità conquistate saranno accettate dai capi, entrano automaticamente a far parte del raggruppamento dei "Maestri di Specialità" per quella singola specialità (il socio potrà essere "Maestro di Specialità" di più specialità contemporaneamente). In Reparto, quando un socio vuole conquistare una nuova specialità (ovvero quando la inserisce nella sezione apposita), deve selezionare un Maestro di Specialità, ovvero uno dei soci che hanno già conquistato questa specialità. Tutti i membri della Comunità Capi (ovvero tutti i capi) fanno parte del raggruppamento dei Maestri di Specialità e, in quanto tali, sono gli unici autorizzati ad approvare la conquista di nuove specialità. In Clan, anche se non saranno visibili specialità e competenze conquistate, esse dovranno rimanere comunque in memoria, dato che i membri del Noviziato e del Clan/Fuoco che hanno conquistato quella specialità possono essere Maestri di Specialità per i soci del Reparto. Solo i capi appartenenti alla branca del socio che richiede la specialità potranno autorizzarla e convalidarla. I capi del Branco quindi potranno autorizzare le specialità e le competenze dei soci del Branco, mentre i capi del Reparto potranno autorizzare e convalidare solo le specialità richieste dai soci del Reparto.
- Tutti i dati relativi ad autorizzazioni, pagamenti e compilazione in PDF dei documenti dei soci minorenni devono essere effettuati da uno dei due genitori del socio per poi essere convalidati dai capi.

### Genitori dei soci minorenni

I genitori dei soci minorenni avranno la possibilità di visualizzare i dati dei propri figli (ad eccezione della password), inclusa la facoltà di **visionare le specialità/competenze conquistate e quelle in corso, oltre agli impegni presi e agli obiettivi prefissati per l'anno corrente** unicamente per i propri figli. Potranno modificare le informazioni relative ai propri figli (ad eccezione della password e delle competenze, specialità, impegni o dati prevalentemente relativi alle attività interne al gruppo, che verranno gestiti dai ragazzi stessi), oltre alla possibilità di compilare PDF, inserire i dati relativi a pagamenti e autorizzazioni varie (es. uscite, campi, riunioni ecc.). In ultima analisi, i genitori potranno anche visualizzare l'elenco completo dei maestri di specialità del proprio figlio, oltre a visualizzare i capi e i dati degli altri membri (per gli altri ragazzi potranno vedere solo specialità e competenze che sono pubbliche, ma NON impegni e obiettivi altrui). Le modifiche di informazioni dovranno essere comunque autorizzate dai capi della branca di appartenenza.

### Socio censito (maggiorenne)

Tutte le funzioni dei soci minorenni + la possibilità di compilare PDF e altre autorizzazioni (es. uscite, campi, riunioni ecc.) e, inoltre, la possibilità di poter inserire i dati relativi ai bonifici effettuati.

- I soci appartenenti al Clan/Fuoco potranno effettuare uno o più anni di "servizio associativo" nel quale essi aiuteranno i capi di un'altra branca (Branco oppure Reparto), oltre a continuare a fare comunque parte del Clan/Fuoco. In questo caso, oltre a visualizzare gli impegni del Clan/Fuoco, i soci che svolgono servizio associativo potranno visualizzare anche gli impegni della branca in cui fanno servizio associativo durante l'anno. I soci del Clan, nella sezione personale (del proprio profilo) potranno inserire anche il tipo di servizio che svolgono (associativo o altro, specificandolo tramite testo).

### Documenti Personali e Censimento

All'interno del profilo di ogni socio (nella sua **sezione privata**) sono gestiti tutti i documenti necessari per il censimento annuale.

- **Tipologia di documenti:** I moduli (es. privacy, consenso, iscrizione) differiscono a seconda che il socio sia minorenne o maggiorenne. Oltre ai moduli, in questa sezione viene inserito anche il PDF della ricevuta del bonifico relativo al censimento.
- **Compilazione In-App:** L'app disporrà di un tool integrato. Il socio maggiorenne (o il genitore, per i minorenni) potrà aprire i documenti vuoti, compilarli inserendo testo da tastiera e inserire immagini (es. la foto o il disegno della propria firma). Questo permette di completare la burocrazia senza stampare alcun foglio.
- **Invio e Convalida:** I documenti compilati vengono inviati digitalmente in-app, in maniera diretta, ai capi della branca per la verifica e la convalida. Se accettati, diventano di sola lettura fino all'anno successivo. Se rifiutati, vengono sbloccati per il reinvio.
- **Regola di visibilità:** I documenti di censimento (ricevute incluse) sono **estremamente riservati**. Saranno visibili ESCLUSIVAMENTE nella sezione privata del socio, accessibili solo al socio stesso, ai suoi genitori (se minorenne) e ai capi. Tutti gli altri soci non possono vedere i dati di censimento altrui.

### Gestione Quote e Logistica

Come specificato, nell'app non vengono gestiti pagamenti digitali diretti.

- **Quote per Uscite/Campi:** È presente una specifica casella di spunta ("Quota ricevuta") all'interno dell'evento in app. **Questa casella non può essere spuntata dal socio o dal genitore**, ma solo da un capo appartenente alla branca del socio o dal capo gruppo.
- **Gruppo Logistica (Solo Clan/Fuoco e Noviziato):** Esclusivamente per la branca del Clan/Fuoco e Noviziato, per ogni singola uscita/campo un capo può designare sull'app un gruppo temporaneo di soci chiamato "Logistica" (specifico per quel singolo evento). I membri di questo gruppo speciale ottengono i permessi per gestire e confermare la ricezione delle quote dei singoli soci per quella determinata uscita/campo, potendo quindi spuntare la casella delle quote al posto dei capi.

### Capi

- Ogni capo farà automaticamente parte, oltre che alla branca di appartenenza, della Comunità Capi, ovvero l'insieme di tutti i capi. Ci potranno essere delle attività specifiche dedicate solo alla Comunità Capi. Inoltre, i capi che appartengono alla stessa branca si troveranno raggruppati insieme in un raggruppamento denominato "Staff". Per esempio, tutti i capi del Branco saranno parte anche della "Staff di Branco", tutti i capi del Reparto saranno parte anche della "Staff del Reparto" e tutti i capi del Clan/Fuoco saranno parte anche della "Staff di Clan/Fuoco". Potranno essere previste delle attività specifiche, dedicate solo a singole Staff o più Staff, per esempio un'attività dedicata solo alla Staff di Branco, oppure alla Staff di Branco e quella di Reparto. Ognuno di questi raggruppamenti (Comunità Capi, Staff di Branco, Staff di Reparto, Staff di Clan/Fuoco) potrà avere un calendario e delle attività a sé dedicati, che saranno visualizzabili solo dai membri di quel raggruppamento.
- I capi avranno la possibilità di visualizzare le attività e le proposte dei capi (sia di Branco, che di Reparto, che di Clan/Fuoco), di modifica, approvazione o rimozione delle richieste di modifica dei dati dei soci (sia minorenni che maggiorenni), di autorizzazione delle specialità e delle competenze richieste dai soci (solamente i capi appartenenti alla branca del socio che richiede la specialità potranno autorizzarla e convalidarla).
- I capi potranno aggiornare i dati censimento (dei soci minorenni e maggiorenni), i dati relativi a pagamenti, sia per i soci minorenni che per i soci maggiorenni, anche senza un documento specifico inviato dal singolo socio o dai suoi genitori. Inoltre, i capi dovranno anche convalidare la foto profilo inserita dal socio, per evitare di accettare foto discriminatorie o non conformi.

### Campetti Regionali e Nazionali

Tutti i membri del gruppo (soci e capi) possono partecipare a "campetti" (regionali, nazionali o di formazione) che coinvolgono membri di altri gruppi scout.

- **Campetti dei Soci (minorenni e maggiorenni):** Ogni socio potrà arricchire il proprio profilo inserendo i campetti a cui ha partecipato, specificandone il titolo, il tipo e le date di inizio e fine tramite un calendario. L'inserimento dovrà essere validato da un "capo gruppo" oppure da un qualsiasi capo appartenente alla stessa branca del socio (sia esso capo unità o aiuto capo).
  - I tipi di campetti selezionabili variano in base alla branca di appartenenza:
    - **L/C (Branco):** Piccole Orme, Piccole Tracce, Altro L/C.
    - **E/G (Reparto):** Specialità, Capi Squadriglia, Specialità Squadriglia, Competenza, Candidature Competenza, Guidoncini verdi, Maestro di competenza, Altro E/G.
    - **R/S (Clan/Fuoco e Noviziato):** ROSS, Partenti, EPPPI, Campi R/S estero, Altro R/S.
- **Campetti dei Capi:** Anche i capi possono partecipare a campetti di formazione e inserirli nel proprio profilo indicando il titolo, le date di inizio/fine e la specifica **tipologia di formazione**:
  - **CFT:** CFT
  - **CFM:** CFM L/C, CFM E/G, CFM R/S
  - **CFA:** CFA
  - **CCG:** CCG
  La validazione dei campetti inseriti da un capo spetta **esclusivamente al capo gruppo**. Per questioni di privacy, i campetti svolti dai capi saranno **visibili solo ed esclusivamente agli altri capi**; nessun socio (né minorenne né maggiorenne) avrà i permessi per visualizzarli.

## Spiegazione specifica delle varie sezioni dell'app

### Registrazione e Gestione Anagrafica (Minorenni e Maggiorenni)

Nella fase di registrazione, i nuovi utenti inseriscono i loro dati: nome, cognome, sesso, data di nascita, indirizzo di residenza, numero di telefono (sempre obbligatorio a prescindere dall'età), email, CAP, comune, provincia, password. In base alla data di nascita inserita:

- **Se minorenne:** Verranno aggiunti dinamicamente i campi per i genitori/tutori legali: "Email genitore/tutore legale 1" (obbligatorio), "Email genitore/tutore legale 2" (facoltativo), "Numero di telefono genitore/tutore legale 1" (obbligatorio) e "Numero di telefono genitore/tutore legale 2" (facoltativo). La mail di conferma registrazione perverrà in primis al genitore/tutore e, se inserita, anche al ragazzo (ma solo ad accettazione finale avvenuta).
- **Se maggiorenne:** Il socio potrà iscriversi direttamente con i privilegi da adulto. Tuttavia, è richiesto obbligatoriamente l'inserimento di almeno un "Nome genitore/tutore legale" e il relativo "Numero di telefono" (è possibile inserirne fino a due). Questi dati fungeranno unicamente da contatto di emergenza a esclusiva disposizione dei capi.

Una volta inviata, la richiesta di registrazione perverrà a un capo che dovrà accettarla/rifiutarla e assegnare la branca (Branco, Reparto, Clan/Fuoco). Dopo l'accettazione, l'utente riceve un'email con il link di conferma e potrà accedere all'app per modificare il profilo (es. inserire la foto profilo). I capi hanno il pieno potere di verificare gli utenti e rimuoverli dal sistema a loro discrezione.

**Passaggio alla Maggiore Età (18 anni):**
Quando un socio minorenne compie 18 anni, il sistema lo promuoverà automaticamente allo status di "socio maggiorenne", conferendogli tutti i relativi privilegi, ma questo avverrà **esclusivamente a partire dal successivo 1° settembre** (inizio del nuovo anno associativo scout). Ad esempio, se un socio compie 18 anni ad aprile 2026, l'account diventerà maggiorenne il 1° settembre 2026.
Contestualmente a questo passaggio, i dati anagrafici e i privilegi dei genitori/tutori legali precedentemente inseriti **verranno eliminati dal sistema**, ad eccezione del "Nome" e del "Numero di telefono" di almeno uno di essi (o entrambi, se presenti), che rimarranno salvati unicamente come contatti di emergenza visibili in sola lettura ai capi.

**Generazione Automatica Username:**
Al completamento dell'operazione di registrazione (valido per qualsiasi tipologia di utente), il sistema assegnerà automaticamente un username univoco nel formato `@nomecognome` (es. `@mariorossi`). L'utente non dovrà digitare nulla per crearlo. Se l'username esiste già per omonimia, il sistema aggiungerà alla fine le ultime due cifre dell'anno di nascita dell'utente (es. `@mariorossi96`). Questo username serve per identificare e ricercare i membri in modo rapido e preciso nell'app.

La sezione di registrazione è composta da tre sottosezioni: "Dati base", "indirizzo" e "riepilogo". Nella sezione "Dati base", verranno inseriti tutti i dati anagrafici del socio e, in aggiunta, eventualmente se minorenne, i dati di uno o due genitori (almeno uno obbligatorio). In particolare:

- Nome;
- Cognome;
- Genere (M/F o altro);
- Data di nascita;
- Email (obbligatoria sia per maggiorenni che per minorenni);
- Password;
- Numero di telefono (obbligatorio sia per maggiorenni che per minorenni);

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

Bisognerà prevedere l'inserimento di due o più password diverse, per i soli soci minorenni: una per il socio minorenne e un'altra per il genitore, ovviamente collegate alle email inserite in fase di registrazione. Nel caso in cui i genitori siano due, inserire anche una password per il secondo genitore. Ovviamente, le tre password dovranno essere diverse. In aggiunta, il genitore, ma non il socio minorenne, avrà anche la possibilità di inserire un PIN di 4 cifre per autorizzazioni veloci, in sostituzione del riconoscimento biometrico. Stessa cosa sarà prevista per i capi, che saranno sempre maggiorenni.

### Registrazione di un socio maggiorenne

Nel caso di socio maggiorenne, i passaggi sono i medesimi di quelli previsti per la registrazione di un socio minorenne, con la differenza che non ci saranno i campi per i dati dei genitori.

### Conferma della registrazione di un socio qualsiasi da parte di un capo

Una volta pervenuta a un capo qualsiasi la richiesta di registrazione di un socio, il capo, prima di procedere all'eventuale assegnazione a una branca, dovrà verificarne i dati e accettare o rifiutare la registrazione. In caso di accettazione, il capo dovrà assegnare il socio alla branca corretta e, nel caso in cui si tratti di un socio minorenne, dovrà inserire i dati di uno o due genitori, uno dei quali deve essere obbligatorio, se non già inseriti dal socio stesso. Se non accetta, la richiesta verrà rifiutata e il socio non potrà registrarsi, dovendo effettuare, nel caso, una nuova richiesta di registrazione.

### Registrazione di un capo

Se un utente si vuole registrare come capo, i passaggi sono diversi. Dovrà essere il capo gruppo, o uno dei capi a cui è stato permesso al capo gruppo di agire e aggiungere nuovi capi, ad inserire i dati del nuovo capo, tramite la dashboard apposita. In particolare, verrà inserita solo l'email. Una volta inserita l'email del capo da aggiungere, esso riceverà una mail contenente un link specifico per terminare il processo di registrazione tramite l'app. Dopodiché, il nuovo capo potrà inserire i propri dati, che sono: nome, cognome, genere, data di nascita, email (che verrà recuperata da quella già inserita in precedenza), numero di telefono, indirizzo, numero civico, CAP, comune, provincia, password e branca di cui fanno parte (che possono essere 4: Branco, Reparto, Clan/Fuoco o Gruppo. Successivamente inseriranno il loro ruolo: se selezionano Branco, i ruoli potranno essere "Capo Branco", "Aiuto Capo Branco"; se selezionano Reparto, potranno essere "Capo Reparto", "Aiuto Capo Reparto"; se selezionano "Noviziato", l'unico ruolo potrà essere "Maestro dei Novizi"; se selezionano Clan/Fuoco, potranno essere "Capo Clan", "Capo Fuoco", "Aiuto Capo Clan", "Aiuto Capo Fuoco" (N.B. Il Maestro dei Novizi appartiene sia al Noviziato che al Clan/Fuoco); se selezionano Gruppo, potranno essere "Capo Gruppo", "Capo a disposizione", "Assistente Ecclesiastico"). Se il capo ha selezionato il Branco, ci sarà un campo in più in cui verrà chiesto di inserire il suo nome della giungla ("Soprannome"). Ciò accadrà anche ogni volta che un capo qualsiasi viene spostato in Branco, bisognerà aggiornare il suo nome della giungla. Se un capo esce dal Branco e va in un altra branca, il suo nome della giungla non verrà più visualizzato. Questo processo è così strutturato per rendere più completa, più sicura e meno probabile la registrazione di un capo tramite form di registrazione generico già previsto nell'app. In aggiunta, i capi avranno poi la possibilità, sempre tramite la dashboard apposita, di modificare i propri dati e, se autorizzati dal capo gruppo, potranno inserire i dati di nuovi capi da far registrare.

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

### Sezione Calendario

La sezione Calendario permette la visualizzazione di tutte le attività programmate. Sarà suddivisa in diverse viste: mensile, settimanale e giornaliera.

- **Filtri e Visibilità:** Gli utenti vedranno solo gli eventi relativi alla loro branca o all'intero gruppo. I capi vedranno gli eventi della propria branca, della Comunità Capi e delle relative Staff. I capi gruppo vedranno tutto. Sarà possibile filtrare gli eventi tramite appositi chip (es. "Solo riunioni", "Solo uscite", "Eventi di Gruppo").
- **Dettaglio Evento:** Cliccando su un evento, si aprirà una schermata di dettaglio contenente: titolo, descrizione, luogo (con mappa integrata), orario di inizio e fine, costo (se previsto) e materiale necessario.
- **Gestione Presenze e Autorizzazioni:** All'interno del dettaglio evento, i genitori (per i minorenni) o i soci maggiorenni potranno confermare o declinare la presenza in anticipo. Inoltre, **i capi di ogni branca** avranno a disposizione uno strumento di "Appello" per quello specifico evento: potranno inserire esplicitamente le presenze effettive (o segnare le assenze) dei soci appartenenti alla loro branca. Se l'evento (come un'uscita o un campo) richiede un'autorizzazione, comparirà il modulo PDF da compilare, firmare digitalmente in-app e inviare ai capi per l'approvazione.
- **Collegamento ai Pagamenti:** Se l'evento prevede una quota di partecipazione, sarà presente un pulsante "Carica Ricevuta Bonifico" (dettagliato nella sezione pagamenti).

### Sezione Ricerca

La sezione Ricerca è fondamentale per trovare rapidamente altri membri del gruppo.

- **Barra di ricerca:** Permette di cercare per nome e cognome oppure direttamente tramite l'username univoco (es. digitando `@mariorossi`).
- **Filtri Avanzati:** Sarà possibile filtrare per Branca (Branco, Reparto, Clan/Fuoco, Comunità Capi), ruolo (Socio, Capo) e per "Maestri di Specialità".
- **Visualizzazione Profilo Altrui:** Cliccando su un utente trovato, si aprirà una versione in "sola lettura" del suo profilo. I capi vedranno tutti i dettagli (inclusi recapiti, genitori, situazione medica, se autorizzati), mentre i soci normali vedranno solo le informazioni pubbliche (nome, foto profilo, specialità acquisite, ecc., a seconda delle impostazioni di privacy dell'utente e della branca).

### Sezione Profilo

Questa è la sezione personale dell'utente (o del figlio, se visualizzata dal genitore). Sarà divisa in comode tab o schede:

1. **Dati Anagrafici e Contatti:** Riepilogo delle informazioni di base, con possibilità di richiederne la modifica (soggetta ad approvazione dei capi). Inclusa la possibilità di cambiare foto profilo (anch'essa soggetta ad approvazione).
2. **Profilo Medico e Alimentare (Allergie):** Ogni socio potrà inserire e aggiornare le proprie allergie e intolleranze alimentari. Per garantire la massima privacy e sicurezza, **questi dati saranno visibili unicamente al socio stesso, ai suoi genitori/tutori (se minorenne) e ai capi**. Assolutamente nessun altro membro del gruppo potrà visualizzarli in nessun caso.
3. **Progressione Personale (Competenze e Specialità):** In base alla branca, l'utente vedrà le specialità e competenze che può acquisire, quelle "in corso" e quelle già "conquistate". Ci sarà la possibilità di richiedere l'approvazione di una nuova specialità o competenza, selezionando il relativo Maestro di Specialità.
4. **Impegni e Obiettivi:** Sezione testuale dove l'utente inserisce i propri impegni annuali e gli obiettivi personali (tipico soprattutto per Reparto e Clan/Fuoco). Potrà scegliere se renderli pubblici agli altri soci o visibili solo ai capi.
5. **Documenti e Modulistica (Privacy, Dati Medici, Censimento):** Area dove generare, compilare e firmare in-app i PDF obbligatori annuali (scheda medica, privacy, modulo di censimento). Una volta inviati, mostreranno lo stato: "In attesa di approvazione", "Approvato" o "Rifiutato". I documenti medici saranno fortemente crittografati, gestiti solo tra dispositivo ed i capi autorizzati, come da requisiti.

### Sezione Pagamenti e Ricevute (PDF Bonifici)

**Gestione Rigorosa tramite Bonifico Bancario**
Per garantire tracciabilità e zero commissioni in-app, **nessun pagamento avverrà direttamente all'interno dell'applicazione** (né tramite carte di credito né tramite gateway come Stripe o PayPal). Il flusso dei pagamenti sarà gestito esclusivamente tramite caricamento del documento PDF della ricevuta/contabile del bonifico.

- **Dati Bancari del Gruppo:** Nella sezione pagamenti (o nel dettaglio dell'attività a pagamento) verranno mostrati in modo chiaro l'IBAN del gruppo scout, l'intestatario e la causale esatta da inserire al momento del bonifico tramite la propria banca.
- **Caricamento Ricevuta (PDF):** Una volta effettuato il bonifico tramite l'home banking dell'utente, il genitore o il socio maggiorenne salverà la ricevuta in formato PDF (o immagine). All'interno dell'app, selezionerà la pendenza da pagare (es. "Quota Censimento 2026" o "Campo Invernale Reparto") e cliccherà su "Carica PDF Ricevuta".
- **Flusso di Approvazione:**
  1. Il file PDF caricato viene crittografato e archiviato in modo sicuro nel database Supabase (Storage), venendo associato all'ID dell'utente e all'ID dell'evento o della quota.
  2. Lo stato del pagamento per quell'utente passa da "Da Pagare" a "In attesa di verifica".
  3. Il sistema invia una notifica push ai capi responsabili (es. Capi Unità, Tesoriere o Capo Gruppo).
  4. Il capo responsabile accede all'apposita "Dashboard Pagamenti" presente nella sua Home, visualizza il PDF caricato per verificare la correttezza dell'importo e della causale, e clicca su "Approva" o "Rifiuta".
  5. Se approvato, il pagamento passa definitivamente allo stato "Saldato" e l'utente riceve una notifica di conferma. Se rifiutato (es. importo errato, causale sbagliata, documento illeggibile), il capo inserirà un breve motivo del rifiuto; l'utente riceverà una notifica e dovrà ricaricare il documento corretto.
- **Dashboard Pagamenti per i Capi:** I capi avranno un'interfaccia dedicata e riepilogativa per vedere rapidamente chi ha saldato una quota, chi è in attesa di verifica (con i PDF da controllare) e chi è ancora insoluto, permettendo anche l'invio di notifiche di sollecito in modo mirato. Questa architettura garantisce che nessun pagamento eluda il controllo umano dei capi prima di essere validato.

### Sistema di Notifiche

L'applicazione utilizzerà un sistema di notifiche push e in-app (tramite un'icona a forma di campanella nella barra superiore) per mantenere costantemente aggiornati i membri:

- **Ai Genitori / Soci maggiorenni e minorenni:** Notifiche di approvazione/rifiuto documenti (PDF medici, privacy), conferme di approvazione/rifiuto delle ricevute dei pagamenti, solleciti, promemoria per eventi imminenti e avvisi generici dai capi.
- **Ai Capi:** Notifiche tempestive ogni qualvolta un utente carica una nuova ricevuta di pagamento da verificare, quando vengono inviati nuovi moduli PDF compilati (medici o di privacy), quando arrivano richieste di modifica dati anagrafici e quando vengono richieste nuove specialità da autorizzare. Tutte queste notifiche serviranno per snellire il lavoro del capo garantendo un pronto intervento.

## Funzionalità Organizzative Aggiuntive

Per ottimizzare al massimo la gestione pratica del gruppo, l'app integrerà le seguenti funzionalità ausiliarie:

1. **Esportazione Dati (Excel/CSV per Segreteria):**
   I Capi Gruppo e i responsabili di segreteria avranno a disposizione una funzione per esportare rapidamente in formato tabellare (es. foglio Excel) le liste dei censiti, i contatti telefonici di emergenza dei genitori/tutori e il riepilogo dello stato dei pagamenti. Questa funzione è vitale per poter stampare le anagrafiche d'emergenza da portare ai campi dove non c'è connessione internet.

2. **Gestione Magazzino/Inventario (Solo Reparto e Clan/Fuoco):**
   Questa sezione è dedicata al tracciamento del materiale (es. tende, casse, attrezzi) e **non coinvolge i soci del Branco**. L'accesso è strettamente regolamentato da due livelli di permesso:
   - **Accesso Permanente:** I capi e i "Magazzinieri" (ruolo annuale fisso, presente nel Clan e nelle singole squadriglie di Reparto) possono visualizzare e modificare l'inventario in qualsiasi momento dell'anno associativo, registrandone lo stato di usura ("da riparare", "funzionante") e tracciando il materiale in prestito.
   - **Accesso Temporaneo:** I soci assegnati temporaneamente al gruppo "Logistica" per una specifica uscita o campo acquisiranno i permessi per visualizzare lo stato del magazzino, ma **esclusivamente per la durata dell'evento**. Una volta concluso l'evento, perderanno immediatamente l'accesso, a meno che non ricoprano anche il ruolo fisso di Magazzinieri.

3. **Bacheca Avvisi (Comunicazioni Permanenti):**
   Oltre alle effimere notifiche push, ogni branca avrà una propria "Bacheca Virtuale" in app, visibile solo ai membri e ai genitori della relativa branca. Qui i capi potranno pubblicare comunicazioni importanti (es. "Lista materiale per il campo estivo") che resteranno ancorate e visibili nel tempo, evitando che le info si perdano nelle chat.

4. **Archivio Storico (vs. Progressione Permanente):**
   Al termine dell'anno associativo scout (31 agosto), gli eventi passati, i vecchi moduli PDF e le ricevute dei pagamenti si sposteranno automaticamente in un "Archivio Storico" interno, accessibile per future consultazioni. In questo modo la dashboard del nuovo anno riparte pulita.
   **Eccezione Tassativa (Cosa resta sempre visibile):** Indipendentemente dall'anno associativo o dall'archiviazione, **le specialità e le competenze conquistate, così come i campetti a cui si è partecipato**, non verranno MAI spostati nell'archivio. Essi rimangono ancorati in modo permanente e perenne sulla dashboard del profilo utente (o del capo), costituendo il "curriculum scout" storico e incancellabile dell'individuo.

5. **Registro Presenze e Statistiche Annuali:**
   Nella sezione dedicata ai capi, sarà presente una dashboard per monitorare l'affluenza dei ragazzi alle varie attività (riunioni, uscite, campi). Sfruttando le conferme di presenza agli eventi (tramite l'apposito pulsante) e gli appelli in-app, il sistema calcolerà automaticamente le statistiche e le percentuali di partecipazione. Questo strumento sarà un validissimo supporto per i capi durante le verifiche di fine anno, per poter valutare oggettivamente la costanza e l'impegno di ogni singolo socio.
