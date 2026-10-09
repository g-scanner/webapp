// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

const String ppIt = r'''
## Privacy Policy di G-Scanner

**Versione:** 1.0
**Data di entrata in vigore:** 9 ottobre 2026
**Data di ultimo aggiornamento:** 9 ottobre 2026

---

La presente Privacy Policy descrive le modalità di trattamento dei dati personali effettuato attraverso l'applicazione mobile e web **G-Scanner**, sviluppata nel rispetto del **Regolamento (UE) 2016/679 (GDPR)** e della normativa italiana applicabile in materia di protezione dei dati personali.

---

# Finalità dell'applicazione

G-Scanner è un'applicazione che consente agli utenti di consultare informazioni relative ai prodotti alimentari mediante la scansione dei codici a barre, con particolare attenzione alle esigenze delle persone affette da celiachia o intolleranza al lattosio.

L'applicazione permette inoltre agli utenti di configurare specifiche preferenze alimentari, ricevere indicazioni basate su filtri informativi preimpostati e partecipare a una community attraverso la condivisione di segnalazioni relative ai prodotti.

**Importante – Limitazione di responsabilità**

Le informazioni fornite da G-Scanner hanno esclusivamente finalità informative e di supporto all'utente.

L'applicazione **non costituisce un dispositivo medico**, **non fornisce consulenze mediche**, **non ha valore diagnostico o terapeutico** e **non produce effetti o valutazioni aventi valore legale**.

Le informazioni visualizzate non sostituiscono in alcun modo:

* il parere di un medico o di altro professionista sanitario qualificato;
* la consultazione delle etichette ufficiali dei prodotti alimentari;
* le informazioni fornite direttamente dal produttore.

Le valutazioni generate dall'applicazione si basano esclusivamente sui dati disponibili nel database e sulle impostazioni configurate dall'utente e potrebbero non riflettere variazioni nella composizione dei prodotti, aggiornamenti delle ricette da parte dei produttori o informazioni non disponibili.

L'utente è sempre tenuto a verificare autonomamente la composizione e l'etichettatura dei prodotti prima del consumo.

---

# 1. Titolare del Trattamento

Il Titolare del Trattamento dei dati personali è:

**Emanuele Ciotola**

E-mail:
**supporto-gscanner@googlegroups.com**

Per qualsiasi richiesta relativa al trattamento dei dati personali o all'esercizio dei diritti previsti dal GDPR è possibile contattare il Titolare al suddetto indirizzo.

---

# 2. Tipologie di dati trattati

L'applicazione tratta esclusivamente i dati necessari al proprio funzionamento e all'erogazione delle funzionalità offerte.

## 2.1 Utenti anonimi

Quando G-Scanner viene utilizzata senza effettuare l'accesso, i dati personali dell'utente e le preferenze configurate rimangono esclusivamente sul dispositivo e vengono memorizzati localmente tramite **SharedPreferences**.

Tra questi rientrano:

* cronologia delle scansioni;
* impostazioni dell'applicazione;
* preferenze relative alle funzionalità alimentari e sanitarie selezionate dall'utente.

Tali dati personali **non vengono trasmessi ai server del Titolare**.

Resta tuttavia inteso che le **segnalazioni relative ai prodotti**, qualora inviate tramite l'applicazione, vengono memorizzate nel database cloud dell'applicazione e rese disponibili agli altri utenti della community al fine di migliorare il servizio.

Le segnalazioni pubblicate nella community possono contenere esclusivamente:

* informazioni relative all'alimento o prodotto segnalato;
* eventuali note inserite dall'utente;
* il motivo della segnalazione.

L'identità dell'utente che effettua la segnalazione, inclusi **nome, cognome, indirizzo e-mail o altri dati identificativi**, **non viene mai resa pubblica né associata visibilmente alla segnalazione in nessuna circostanza**.

Anche le segnalazioni effettuate da altri utenti possono essere consultate dagli utilizzatori dell'applicazione, indipendentemente dall'autenticazione.

---

## 2.2 Utenti autenticati

L'utente può autenticarsi mediante **Firebase Authentication** utilizzando un account:

* Google;
* Facebook.

A seguito dell'autenticazione vengono acquisiti dal provider i dati necessari all'identificazione dell'utente, che possono comprendere:

* nome;
* cognome;
* indirizzo e-mail;
* numero di telefono, ove disponibile o associato al profilo utilizzato per l'autenticazione.

A tali informazioni viene associato un identificativo univoco dell'utente (**User ID**).

G-Scanner non accede alle credenziali di autenticazione dell'utente, quali password o strumenti equivalenti, e non tratta tali informazioni.

---

## 2.3 Dati memorizzati nel database cloud

Per gli utenti autenticati vengono memorizzati su **Firebase Firestore**, associati all'identificativo dell'utente:

* cronologia delle scansioni;
* elenco delle segnalazioni inviate;
* impostazioni relative alle preferenze alimentari:
* Avvertimento Additivi;
* Filtro Rigido Contaminazioni;
* Intolleranza al Lattosio;
* eventuali impostazioni relative agli avvisi sulle contaminazioni;
* lingua selezionata;
* tema grafico scelto.

I dati identificativi ottenuti mediante l'autenticazione (nome, cognome, indirizzo e-mail ed eventuale numero di telefono, ove disponibile) sono utilizzati esclusivamente per:

* consentire la gestione dell'account;
* associare correttamente i dati dell'utente al relativo profilo;
* fornire le funzionalità riservate agli utenti autenticati.

---

## 2.4 Cookie e Tecnologie di Archiviazione Locale

G-Scanner (sia nella versione Web App che come applicazione Mobile) non utilizza cookie di profilazione, strumenti di tracciamento pubblicitario o sistemi di analytics di terze parti.

L'applicazione utilizza esclusivamente tecnologie di archiviazione locale strettamente necessarie (come *SharedPreferences* su dispositivi mobili e *LocalStorage / Cookie tecnici* su browser) al solo fine di:

* Mantenere la sessione utente attiva in modo sicuro tramite Firebase Authentication;
* Memorizzare localmente le preferenze dell'utente (es. lingua, tema grafico) e la conferma di accettazione dei documenti legali.

Poiché si tratta esclusivamente di strumenti tecnici indispensabili per l'erogazione del servizio richiesto dall'utente, ai sensi della normativa europea (Direttiva ePrivacy) e dei provvedimenti del Garante Privacy italiano, non è richiesto il preventivo consenso dell'utente per il loro utilizzo. L'utente viene informato della loro presenza tramite la presente Privacy Policy, senza necessità di banner o documenti separati.

I dati memorizzati localmente rimangono sul dispositivo dell'utente fino alla loro eliminazione o alla disinstallazione dell'applicazione.

---

## 2.5 Database locale per l'utilizzo offline

G-Scanner può consentire all'utente di scaricare sul proprio dispositivo una copia locale di dati relativi ai prodotti alimentari, al fine di permettere la consultazione e la scansione dei prodotti anche in assenza di una connessione Internet.

Il database offline contiene esclusivamente informazioni relative ai prodotti alimentari necessarie al funzionamento delle funzionalità offline e non contiene dati personali dell'utente.

L'utente può scegliere tra differenti configurazioni del database offline, caratterizzate da un diverso livello di copertura e dalla conseguente diversa quantità di dati memorizzati sul dispositivo.

I dati presenti nel database offline costituiscono una copia locale dei dati disponibili al momento del relativo aggiornamento e potrebbero pertanto non riflettere eventuali modifiche o aggiornamenti successivi delle informazioni relative ai prodotti.

I dati consultati tramite il database offline non vengono automaticamente associati al profilo personale dell'utente né utilizzati per creare o aggiornare il relativo profilo.

Il database offline può essere aggiornato o eliminato dall'utente mediante le funzionalità messe a disposizione dall'applicazione.

---

# 3. Dati appartenenti a categorie particolari (Art. 9 GDPR)

G-Scanner consente all'utente di configurare specifiche preferenze personali finalizzate alla consultazione delle informazioni sui prodotti alimentari. Tali impostazioni possono riflettere lo stato di salute o particolari esigenze alimentari dell'utente e, pertanto, possono costituire **categorie particolari di dati personali**, ai sensi dell'**art. 9 del Regolamento (UE) 2016/679 (GDPR)**.

Le impostazioni disponibili nell'applicazione sono le seguenti:

* **Avvertimento Additivi**: genera un avviso in presenza di ingredienti quali amidi modificati o aromi la cui origine non sia specificata, affinché l'utente possa effettuare ulteriori verifiche.
* **Filtro Rigido Contaminazioni**: considera come **"Vietato"** qualsiasi alimento la cui etichetta riporti diciture quali **"può contenere tracce di glutine"** o formulazioni equivalenti relative alla possibile contaminazione da glutine.
* **Intolleranza al Lattosio**: verifica la presenza di ingredienti quali lattosio, burro, latte in polvere o siero del latte, segnalandone l'eventuale presenza secondo le funzionalità dell'applicazione.

Al **primo avvio dell'applicazione** risultano abilitate per impostazione predefinita esclusivamente le seguenti opzioni:

* Avvertimento Additivi;
* Filtro Rigido Contaminazioni.

L'opzione **Intolleranza al Lattosio** è inizialmente disabilitata e può essere attivata dall'utente in qualsiasi momento.

Il trattamento di tali informazioni avviene **esclusivamente previo consenso esplicito dell'utente**, ai sensi dell'**art. 9, paragrafo 2, lettera a) del GDPR**.

L'utente è libero di modificare, attivare o disattivare in qualsiasi momento le suddette impostazioni secondo le proprie esigenze personali.

Tali scelte sono effettuate sotto la responsabilità dell'utente, il quale riconosce che G-Scanner costituisce esclusivamente uno **strumento di supporto informativo** e non sostituisce:

* la verifica delle etichette dei prodotti;
* le informazioni fornite dal produttore;
* il parere di un medico o di altro professionista sanitario qualificato.

L'eventuale modifica delle impostazioni e l'utilizzo delle informazioni fornite dall'applicazione avvengono pertanto **a esclusivo rischio dell'utente**.

L'utente può in ogni momento modificare le proprie preferenze o revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca.

---

# 4. Finalità del trattamento

I dati personali raccolti attraverso G-Scanner sono trattati per le seguenti finalità:

* consentire la scansione dei codici a barre e la consultazione delle informazioni relative ai prodotti alimentari;
* consentire la consultazione delle informazioni relative ai prodotti anche in assenza di una connessione Internet, mediante l'eventuale database locale scaricato dall'utente;
* permettere la personalizzazione dell'esperienza dell'utente tramite la configurazione delle preferenze alimentari e delle impostazioni dell'applicazione;
* consentire agli utenti autenticati la sincronizzazione dei dati tra dispositivi diversi;
* permettere la partecipazione alla community attraverso l'invio, la gestione e la consultazione delle segnalazioni relative ai prodotti;
* gestire l'autenticazione tramite provider esterni quali Google e Facebook;
* garantire il corretto funzionamento tecnico dell'applicazione, la sicurezza dei servizi e la protezione dei dati trattati.

---

# 5. Base giuridica del trattamento

Il trattamento dei dati personali si fonda su:

* consenso esplicito dell'interessato per il trattamento delle **categorie particolari di dati personali** relative alla salute (art. 9, par. 2, lett. a GDPR);
* esecuzione del servizio richiesto dall'utente e delle funzionalità offerte dall'applicazione;
* adempimento degli obblighi previsti dalla normativa vigente;
* interesse legittimo del Titolare relativamente alla sicurezza tecnica dell'applicazione e alla prevenzione di utilizzi impropri del servizio, ove applicabile.

---

# 6. Minori

L'utilizzo di G-Scanner è vietato ai minori di **14 anni**.

In conformità alla normativa italiana sul consenso digitale, l'applicazione non è destinata a utenti di età inferiore ai 14 anni e non raccoglie consapevolmente dati personali riferibili a tali soggetti.

Qualora il Titolare venga a conoscenza della presenza di dati appartenenti a un minore di 14 anni, provvederà alla loro tempestiva cancellazione.

---

# 7. Accesso a funzionalità e informazioni del dispositivo

Per garantire il corretto funzionamento delle funzionalità offerte, G-Scanner può accedere ad alcune funzionalità e informazioni del dispositivo dell'utente.

## Fotocamera

La fotocamera viene utilizzata esclusivamente per consentire la scansione dei codici a barre dei prodotti.

Le immagini acquisite tramite fotocamera non vengono salvate, trasmesse o utilizzate per finalità diverse dalla scansione del codice a barre.

---

## Connessione Internet

L'applicazione verifica, ove necessario, la disponibilità della connessione Internet al fine di determinare se le funzionalità che richiedono l'accesso ai servizi online possano essere utilizzate.

La connessione Internet è necessaria, in particolare, per:

* effettuare l'autenticazione tramite i provider supportati;
* sincronizzare i dati degli utenti autenticati;
* accedere ai servizi cloud utilizzati dall'applicazione;
* recuperare e aggiornare le informazioni sui prodotti mediante i servizi online;
* consentire il funzionamento delle funzionalità basate sui dati della community.

Lo stato della connessione viene utilizzato esclusivamente per la gestione tecnica delle funzionalità dell'applicazione e non viene raccolto, conservato o utilizzato per finalità di profilazione o tracciamento.

---

## Tema di sistema

Il permesso relativo al tema di sistema viene utilizzato esclusivamente per adattare automaticamente l'interfaccia grafica dell'applicazione alla modalità chiara o scura configurata sul dispositivo dell'utente.

---

## Lingua del dispositivo e lingua dell'interfaccia

Al primo avvio, l'applicazione può leggere la lingua configurata sul dispositivo al fine di determinare automaticamente la lingua dell'interfaccia dell'applicazione.

La lingua così determinata viene utilizzata per configurare l'interfaccia dell'applicazione e, per gli utenti autenticati, può essere salvata nel database associato all'account al fine di mantenere la preferenza e sincronizzarla tra i dispositivi.

La lingua dell'interfaccia non viene utilizzata per finalità di profilazione, tracciamento o pubblicità.

---

# 8. Assenza di pubblicità, tracciamento e raccolta dati analitici

G-Scanner adotta una politica di tutela della riservatezza degli utenti.

L'applicazione:

* è completamente gratuita;
* non contiene pubblicità;
* non utilizza strumenti di analytics;
* non utilizza Google Analytics;
* non utilizza Firebase Crashlytics;
* non effettua profilazione degli utenti;
* non svolge attività di tracciamento degli utenti;
* non vende dati personali;
* non comunica né cede dati personali a terzi per finalità commerciali.

In particolare, **G-Scanner non raccoglie identificativi pubblicitari, informazioni di utilizzo dell'applicazione, dati diagnostici o dati tecnici del dispositivo per finalità analitiche o di profilazione**.

L'applicazione non effettua processi di monitoraggio comportamentale dell'utente né crea profili commerciali o pubblicitari.

---

# 9. Conservazione dei dati

## 9.1 Utenti anonimi

Quando l'utente utilizza G-Scanner senza autenticazione, i dati personali e le preferenze configurate rimangono esclusivamente memorizzati localmente sul dispositivo tramite **SharedPreferences**.

Tali dati vengono conservati fino a quando:

* l'utente li elimina tramite le funzionalità disponibili nell'applicazione;
* l'applicazione viene disinstallata;
* il dispositivo viene ripristinato o i dati locali vengono cancellati.

Le segnalazioni relative ai prodotti inviate alla community costituiscono un trattamento distinto e vengono invece conservate nel database cloud dell'applicazione per consentirne la consultazione da parte degli altri utenti.

---

## 9.2 Database locale per l'utilizzo offline

I dati relativi ai prodotti contenuti nel database offline vengono conservati localmente sul dispositivo fino a quando l'utente:

* elimina il database tramite le funzionalità disponibili nell'applicazione;
* sostituisce il database con una diversa configurazione;
* disinstalla l'applicazione;
* elimina i relativi dati locali, ove previsto dal sistema operativo.

Il database offline può essere aggiornato periodicamente. La versione disponibile sul dispositivo potrebbe pertanto non coincidere con la versione più recente dei dati disponibili online.

---

## 9.3 Utenti autenticati

Per gli utenti autenticati i dati vengono conservati mediante una modalità di **doppia memorizzazione**:

* localmente sul dispositivo dell'utente, per consentire un utilizzo rapido dell'applicazione;
* nel database cloud Firebase Firestore, per consentire la sincronizzazione delle informazioni tra dispositivi diversi e il mantenimento delle funzionalità associate all'account.

I dati associati all'account rimangono conservati fino alla loro eliminazione secondo le modalità descritte nel successivo articolo relativo alla cancellazione dei dati.

---

# 10. Diritto alla cancellazione e gestione dell'account (Art. 17 GDPR)

L'utente dispone di due modalità distinte per la gestione della cancellazione dei propri dati.

## 10.1 Eliminazione dell'account tramite funzione interna dell'applicazione

Qualora l'utente utilizzi l'apposita funzione interna di eliminazione dell'account disponibile in G-Scanner, viene effettuata la cancellazione del relativo **profilo di autenticazione Firebase Authentication**.

Tale operazione comporta:

* la rimozione definitiva dell'associazione tra l'account e i dati identificativi utilizzati per l'autenticazione;
* la cancellazione dei riferimenti relativi a email, nome, cognome ed eventuali dati del provider associati al profilo.

Tuttavia, l'eliminazione del profilo di autenticazione **non comporta automaticamente la distruzione fisica immediata dei documenti presenti su Firebase Firestore**.

I dati eventualmente presenti nel database cloud, quali:

* cronologia delle scansioni;
* impostazioni dell'applicazione;
* dati associati all'identificativo utente;

non risultano più collegabili all'identità dell'utente e diventano tecnicamente inaccessibili tramite il normale utilizzo dell'applicazione.

Il collegamento tra tali dati e l'identità dell'utente viene eliminato definitivamente.

---

## 10.2 Cancellazione completa e definitiva dei dati (Wipe dei dati)

Qualora l'utente desideri la cancellazione fisica completa e definitiva di tutti i record associati al proprio identificativo presente nei sistemi cloud, deve inoltrare una richiesta esplicita al Titolare tramite:

**supporto-gscanner@googlegroups.com**

La richiesta deve essere effettuata **prima di procedere all'eliminazione del profilo tramite l'applicazione**, utilizzando lo stesso indirizzo e-mail associato all'account utilizzato per l'accesso.

Questa procedura è necessaria affinché il Titolare possa verificare l'identità del richiedente e individuare correttamente i record associati all'account.

Qualora l'utente elimini preventivamente il proprio profilo dall'applicazione senza aver inviato la richiesta di cancellazione completa, potrebbe non essere più possibile verificare l'identità del richiedente e individuare i dati precedentemente associati all'account eliminato.

A seguito della verifica dell'identità, il Titolare procederà alla cancellazione definitiva dei dati presenti nei sistemi cloud associati all'identificativo dell'utente, nei limiti tecnicamente disponibili e previsti dalla normativa applicabile.

---

# 11. Diritti dell'interessato

Ai sensi degli articoli 15 e seguenti del GDPR, l'interessato può esercitare il diritto di:

* ottenere conferma dell'esistenza dei propri dati personali;
* accedere ai dati personali trattati;
* richiedere la rettifica dei dati inesatti;
* richiedere la cancellazione dei dati nei casi previsti dalla normativa;
* ottenere la limitazione del trattamento;
* opporsi al trattamento nei casi consentiti;
* revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca;
* ricevere i propri dati in formato strutturato, ove applicabile;
* proporre reclamo all'Autorità Garante per la Protezione dei Dati Personali.

Per l'esercizio dei propri diritti è possibile contattare il Titolare:

**supporto-gscanner@googlegroups.com**

---

# 12. Sicurezza dei dati

I dati personali sono trattati mediante strumenti informatici e misure tecniche e organizzative adeguate a garantirne:

* riservatezza;
* integrità;
* disponibilità;
* protezione contro accessi non autorizzati.

In particolare, per i dati conservati tramite infrastruttura Firebase, l'accesso ai dati in cloud è limitato esclusivamente ai soggetti autorizzati ed è protetto mediante le misure tecniche e di sicurezza messe a disposizione dall'infrastruttura Firebase.

Il Titolare adotta misure proporzionate alla natura dei dati trattati, tenendo conto dei rischi connessi al trattamento, in conformità all'art. 32 GDPR.

---

# 13. Modifiche alla presente Privacy Policy

Il Titolare si riserva il diritto di modificare o aggiornare la presente Privacy Policy per adeguarla a:

* modifiche normative;
* evoluzioni tecniche dell'applicazione;
* variazioni delle modalità di trattamento dei dati personali.

La versione aggiornata sarà resa disponibile all'interno dell'applicazione e/o attraverso gli eventuali canali ufficiali di G-Scanner, con indicazione della data di ultimo aggiornamento.

---

# 14. Fornitori di Servizi e Trasferimento dei Dati

Per l'erogazione delle funzionalità offerte da G-Scanner, il Titolare si avvale di fornitori di servizi tecnologici che trattano dati personali esclusivamente nei limiti necessari all'esecuzione dei servizi richiesti.

---

## 14.1 Infrastruttura Cloud (Google Firebase)

Per le funzionalità di autenticazione e archiviazione dei dati, G-Scanner utilizza la piattaforma **Google Firebase**, fornita da **Google Ireland Limited**, con sede in Gordon House, Barrow Street, Dublin 4, Irlanda.

In particolare, l'applicazione utilizza:

* **Firebase Authentication**, per la gestione dell'autenticazione degli utenti;
* **Cloud Firestore**, per la memorizzazione e sincronizzazione dei dati degli utenti autenticati.

Per i trattamenti effettuati per conto del Titolare nell'ambito dei servizi Firebase utilizzati dall'applicazione, **Google Ireland Limited opera quale Responsabile del Trattamento ai sensi dell'art. 28 GDPR**.

Restano ferme le eventuali attività di trattamento per le quali Google agisce quale autonomo titolare secondo quanto previsto dalla documentazione privacy del servizio Firebase.

---

## 14.2 Localizzazione dei dati e trasferimenti verso Paesi terzi

Il database **Cloud Firestore** utilizzato da G-Scanner è configurato nella regione:

**eur3 – Francoforte (Germania)**

corrispondente a infrastrutture localizzate all'interno dell'Unione Europea.

Il Titolare adotta tale configurazione con l'obiettivo di favorire la conservazione dei dati personali all'interno dello Spazio Economico Europeo (SEE).

Qualora Google dovesse effettuare trasferimenti tecnici di dati personali verso Paesi situati al di fuori dello Spazio Economico Europeo, tali trasferimenti saranno effettuati nel rispetto degli articoli 44 e seguenti del GDPR e garantiti mediante strumenti legalmente riconosciuti, tra cui:

* il **Data Privacy Framework UE-USA**, ove applicabile;
* le **Clausole Contrattuali Tipo (Standard Contractual Clauses – SCC)** approvate dalla Commissione Europea.

---

## 14.3 Servizi di autenticazione tramite provider esterni (Social Login)

L'utente può scegliere di autenticarsi tramite:

* Google;
* Facebook.

Durante la procedura di autenticazione:

* **Google Ireland Limited**;
* **Meta Platforms Ireland Limited**

agiscono in qualità di **Titolari Autonomi del Trattamento**, limitatamente alle attività necessarie alla verifica delle credenziali, alla gestione dell'identità digitale e all'erogazione del servizio di autenticazione.

G-Scanner riceve esclusivamente i dati necessari alla creazione e gestione dell'account, che possono comprendere:

* nome;
* cognome;
* indirizzo e-mail;
* eventuale numero di telefono disponibile.

Per ogni ulteriore trattamento effettuato direttamente dai provider esterni si rinvia alle rispettive informative privacy ufficiali:

* Google Privacy Policy;
* Meta Privacy Policy.

Il Titolare non è responsabile dei trattamenti effettuati autonomamente da tali provider per finalità proprie.

---

# 15. Assenza di decisioni automatizzate (Art. 22 GDPR)

G-Scanner utilizza filtri e criteri informativi configurati dall'applicazione per fornire indicazioni relative ai prodotti alimentari.

Le classificazioni generate dall'applicazione, quali ad esempio **"Vietato"**, **"Consentito"**, **"Attenzione"** o indicazioni equivalenti, costituiscono esclusivamente informazioni di supporto basate sui dati disponibili e sulle impostazioni selezionate dall'utente.

**L'applicazione non effettua processi decisionali automatizzati aventi effetti giuridici o analogamente significativi sull'utente ai sensi dell'art. 22 GDPR.**

---

# 16. Lingua delle Informative e dei Termini

La presente Privacy Policy, nonché i Termini e Condizioni d'Uso e gli eventuali ulteriori documenti legali relativi all'Applicazione, sono redatti originariamente in **lingua italiana**. Eventuali traduzioni in altre lingue sono fornite esclusivamente a fini di cortesia e per agevolare la comprensione da parte dell'Utente. In caso di discrepanze, incongruenze o difformità interpretative tra la versione in lingua italiana e qualsiasi versione tradotta, prevarrà la versione in lingua italiana, nei limiti massimi consentiti dalla normativa applicabile.

---

# Contatti del Titolare del Trattamento

**Emanuele Ciotola**

**E-mail:**
**supporto-gscanner@googlegroups.com**
''';
