// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

Widget buildNativeTos(Color textColor) {
  // Helper per creare le parti in grassetto automaticamente e velocemente
  Widget pContent(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        children: spans,
      ),
    );
  }

  Widget h1(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget h2(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: pContent(text),
  );

  Widget bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        ),
        Expanded(child: pContent(text)),
      ],
    ),
  );

  Widget divider() => const Divider(height: 32);

  return SingleChildScrollView(
    child: SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          h2("Termini e Condizioni d'Uso (ToS) di G-Scanner"),
          p(
            "**Versione:** 1.0\n**Data di entrata in vigore:** 17 luglio 2026\n**Data di ultimo aggiornamento:** 17 luglio 2026",
          ),
          divider(),

          p(
            "Il presente documento disciplina l'accesso e l'utilizzo dell'applicazione **G-Scanner** (di seguito, l’“App”).",
          ),
          p(
            "Prima di utilizzare l'App, l'Utente è tenuto a leggere attentamente i presenti **Termini e Condizioni d'Uso** (di seguito, i “Termini”).",
          ),
          p(
            "L'accesso, la registrazione, l'installazione o qualsiasi utilizzo dell'App costituiscono accettazione elettronica dei presenti Termini e determinano la conclusione di un accordo vincolante tra l'Utente e lo Sviluppatore, nei limiti consentiti dalla normativa applicabile.",
          ),
          p(
            "Qualora l'Utente non intenda accettare integralmente i presenti Termini, è tenuto ad astenersi dall'utilizzare l'App.",
          ),
          divider(),

          h1("1. Identità dello Sviluppatore e Natura del Progetto"),
          p("L'App **G-Scanner** è sviluppata e gestita da:"),
          p("**Emanuele Ciotola**"),
          p(
            "Contatto per assistenza, richieste o comunicazioni:\n**supporto-gscanner@googlegroups.com**",
          ),
          p("G-Scanner è un progetto software:"),
          bullet("**gratuito**;"),
          bullet("**amatoriale**;"),
          bullet("**non commerciale**;"),
          bullet(
            "sviluppato nell'ambito di un progetto personale da uno studente di informatica.",
          ),
          p(
            "L'App è realizzata con finalità informative, tecniche e sperimentali e non costituisce un servizio professionale, commerciale, medico, sanitario o nutrizionale.",
          ),
          p(
            "Lo Sviluppatore non opera come produttore alimentare, ente certificatore, consulente nutrizionale, medico o professionista sanitario.",
          ),
          divider(),

          h1("2. Requisiti di Età"),
          p(
            "L'utilizzo dell'App è consentito esclusivamente agli utenti che abbiano compiuto almeno **14 (quattordici) anni di età**.",
          ),
          p(
            "Utilizzando l'App, l'Utente dichiara e garantisce di possedere tale requisito anagrafico.",
          ),
          p(
            "Lo Sviluppatore non assume responsabilità per l'utilizzo dell'App da parte di soggetti che non soddisfino tale requisito.",
          ),
          p(
            "Qualora lo Sviluppatore venga a conoscenza della presenza di dati appartenenti a un minore di 14 anni, provvederà alla loro cancellazione nei limiti tecnicamente possibili e compatibilmente con eventuali obblighi di legge applicabili.",
          ),
          divider(),

          h1("3. Accettazione dei Termini e Accettazione Elettronica"),
          p("L'utilizzo dell'App, in qualsiasi sua forma, inclusa:"),
          bullet("la Web App;"),
          bullet("l'applicazione Android distribuita tramite file **.apk**;"),
          bullet(
            "eventuali versioni future rese disponibili dallo Sviluppatore;",
          ),
          p("costituisce accettazione integrale dei presenti Termini."),
          p(
            "L'accesso, la registrazione tramite sistemi di autenticazione disponibili o il semplice utilizzo delle funzionalità dell'App costituiscono una forma di **accettazione elettronica vincolante** dei presenti Termini ai sensi della normativa applicabile.",
          ),
          p(
            "L'Utente riconosce che tale accettazione elettronica produce effetti giuridici equivalenti all'accettazione delle condizioni contrattuali mediante strumenti tradizionali, nei limiti previsti dalla legge.",
          ),
          p(
            "Il mancato rispetto anche di una sola disposizione dei presenti Termini può comportare la sospensione, limitazione o cessazione dell'accesso ai servizi dell'App.",
          ),
          divider(),

          h1(
            "4. Natura del Servizio, Finalità Informative e Disclaimer Medico",
          ),
          h2("4.1 Assenza di finalità mediche"),
          p(
            "**G-Scanner non è un dispositivo medico, non costituisce uno strumento diagnostico e non fornisce consulenze mediche, nutrizionali o sanitarie.**",
          ),
          p(
            "L'App non effettua diagnosi, non certifica la sicurezza degli alimenti e non sostituisce il parere di medici, nutrizionisti o altri professionisti qualificati.",
          ),
          p(
            "Le informazioni mostrate dall'App hanno esclusivamente carattere:",
          ),
          bullet("informativo;"),
          bullet("orientativo;"),
          bullet("sperimentale."),
          p(
            "Gli esiti della scansione, inclusi ma non limitati agli indicatori:",
          ),
          bullet("**Semaforo Verde**;"),
          bullet("**Semaforo Giallo**;"),
          bullet("**Semaforo Rosso**;"),
          p(
            "sono generati mediante algoritmi automatici basati su dati disponibili da fonti interne e/o di terze parti.",
          ),
          p("Tali risultati non devono essere interpretati come:"),
          bullet("certificazioni alimentari;"),
          bullet("valutazioni mediche;"),
          bullet("garanzie assolute di sicurezza;"),
          bullet("indicazioni professionali personalizzate."),

          h2("4.2 Assenza di rapporto professionale"),
          p("L'utilizzo dell'App non crea alcun rapporto:"),
          bullet("medico;"),
          bullet("sanitario;"),
          bullet("nutrizionale;"),
          bullet("consulenziale;"),
          bullet("professionale;"),
          p("tra l'Utente e lo Sviluppatore."),
          p(
            "Le informazioni fornite dall'App non costituiscono consulenza professionale e non devono essere utilizzate come unica base per decisioni relative alla salute o all'alimentazione.",
          ),

          h2("4.3 Obbligo di verifica dell'Utente"),
          p("L'Utente riconosce e accetta che:"),
          bullet(
            "è esclusivamente responsabile delle proprie decisioni alimentari;",
          ),
          bullet(
            "deve leggere integralmente l'etichetta fisica del prodotto prima del consumo;",
          ),
          bullet(
            "deve verificare personalmente ingredienti, allergeni, avvertenze, valori nutrizionali e ogni altra informazione presente sulla confezione originale.",
          ),
          p(
            "L'App non sostituisce in alcun modo l'etichetta ufficiale del produttore.",
          ),

          h2("4.4 Preferenze alimentari e trattamento dei dati personali"),
          p(
            "L'Utente riconosce che alcune impostazioni dell'Applicazione relative a esigenze alimentari personali possono riguardare informazioni potenzialmente riconducibili a categorie particolari di dati personali ai sensi dell'art. 9 GDPR.",
          ),
          p(
            "L'attivazione e l'utilizzo delle funzionalità relative a tali preferenze avvengono esclusivamente secondo quanto indicato nella Privacy Policy dell'Applicazione.",
          ),
          p(
            "Utilizzando tali funzionalità, l'Utente dichiara di aver preso visione della relativa informativa privacy e di aver prestato, ove richiesto, il consenso previsto dalla normativa applicabile.",
          ),
          p(
            "L'Utente può modificare o disattivare tali preferenze in qualsiasi momento secondo le modalità disponibili nell'Applicazione, senza pregiudicare la liceità dei trattamenti effettuati prima della revoca del consenso.",
          ),

          h2("4.5 Clausola di Responsabilità e Manleva"),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, l'Utente riconosce che:",
          ),
          bullet(
            "il consumo di qualsiasi prodotto alimentare costituisce una scelta personale;",
          ),
          bullet(
            "la decisione finale relativa all'acquisto e al consumo di un prodotto spetta esclusivamente all'Utente.",
          ),
          p("Lo Sviluppatore non potrà essere ritenuto responsabile per:"),
          bullet("reazioni allergiche;"),
          bullet("intolleranze;"),
          bullet("effetti indesiderati;"),
          bullet("conseguenze derivanti dal consumo di prodotti;"),
          bullet("errori di classificazione;"),
          bullet("dati incompleti;"),
          bullet("informazioni inesatte;"),
          bullet("errori algoritmici;"),
          bullet("interpretazioni personali dei risultati forniti dall'App."),
          p(
            "L'Utente si impegna a tenere indenne e manlevare lo Sviluppatore da pretese, contestazioni o richieste derivanti direttamente dall'uso improprio dell'App o da decisioni autonome assunte sulla base delle informazioni visualizzate, nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore.",
          ),
          divider(),

          h1("5. Dati di Terze Parti (Open Food Facts)"),
          p(
            "L'App utilizza dati provenienti dal database collaborativo **Open Food Facts**.",
          ),
          p(
            "Tali dati sono forniti da utenti e collaboratori della comunità internazionale e sono distribuiti secondo la licenza **Open Database License (ODbL)**.",
          ),
          p("Lo Sviluppatore:"),
          bullet("non crea tali dati;"),
          bullet("non controlla direttamente il loro inserimento;"),
          bullet("non garantisce la loro accuratezza;"),
          bullet("non garantisce la loro completezza;"),
          bullet("non garantisce il loro aggiornamento;"),
          bullet("non garantisce l'assenza di errori o omissioni."),
          p(
            "L'Utente riconosce che eventuali inesattezze, omissioni o dati obsoleti presenti nel database di Open Food Facts non possono essere imputati allo Sviluppatore.",
          ),
          p(
            "L'Utente riconosce inoltre che **Open Food Facts opera come database collaborativo indipendente e che G-Scanner si limita a utilizzare tali informazioni senza certificarne o modificarne necessariamente il contenuto originale.**",
          ),
          p(
            "In particolare, G-Scanner non certifica la conformità normativa dei prodotti alimentari, la sicurezza degli stessi o la correttezza delle informazioni presenti nelle etichette dei produttori.",
          ),
          divider(),

          h1(
            "6. Distribuzione dell'Applicazione, Installazione APK e Servizi Esterni",
          ),
          p("L'App è resa disponibile:"),
          bullet("come Web App tramite GitHub Pages;"),
          bullet(
            "come applicazione Android distribuibile mediante file **.apk**.",
          ),
          p(
            "L'installazione manuale di file APK provenienti da fonti esterne agli store ufficiali (\"sideloading\") costituisce una scelta volontaria dell'Utente e avviene sotto la sua esclusiva responsabilità.",
          ),
          p("Lo Sviluppatore non assume responsabilità per:"),
          bullet("errori di installazione;"),
          bullet("incompatibilità hardware o software;"),
          bullet("modifiche effettuate dall'Utente;"),
          bullet("configurazioni non corrette del dispositivo;"),
          bullet(
            "problemi derivanti dall'abilitazione di installazioni da fonti sconosciute;",
          ),
          bullet("danni derivanti dall'ambiente del dispositivo utilizzato."),

          h2("6.1 Servizi infrastrutturali e provider esterni"),
          p(
            "Per il funzionamento dell'App possono essere utilizzati servizi forniti da soggetti terzi, inclusi, a titolo esemplificativo:",
          ),
          bullet("GitHub Pages;"),
          bullet("Firebase;"),
          bullet("servizi di hosting;"),
          bullet("servizi database;"),
          bullet("servizi cloud;"),
          bullet("API esterne."),
          p(
            "Lo Sviluppatore non controlla direttamente tali servizi e non è responsabile per:",
          ),
          bullet("malfunzionamenti;"),
          bullet("interruzioni temporanee;"),
          bullet("modifiche tecniche;"),
          bullet("sospensioni;"),
          bullet("cessazioni del servizio;"),
          bullet("modifiche delle API;"),
          bullet("perdita di disponibilità;"),
          p("imputabili ai rispettivi fornitori terzi."),
          p(
            "L'Utente riconosce che tali servizi sono soggetti ai termini, alle condizioni e alle politiche dei relativi provider.",
          ),
          divider(),

          h1("7. Account Utente, Social Login e Segnalazioni della Community"),
          h2("7.1 Creazione e gestione dell'account"),
          p(
            "Alcune funzionalità dell'App possono richiedere l'autenticazione dell'Utente tramite sistemi di accesso forniti da soggetti terzi (\"Social Login\"), inclusi, a titolo esemplificativo:",
          ),
          bullet("Google;"),
          bullet("Facebook;"),
          bullet(
            "eventuali altri provider di autenticazione eventualmente integrati in futuro.",
          ),
          p(
            "L'accesso tramite tali sistemi implica che alcune informazioni relative all'identità dell'account possano essere gestite tramite i rispettivi provider esterni, secondo i loro termini di servizio e le loro informative sulla privacy.",
          ),
          p(
            "L'Utente riconosce di essere esclusivamente responsabile della sicurezza del proprio account Google, Facebook o altro provider utilizzato per l'autenticazione.",
          ),
          p(
            "Lo Sviluppatore non gestisce, non conosce e non conserva le password o le credenziali di accesso degli account esterni utilizzati dall'Utente.",
          ),
          p(
            "Qualsiasi attività effettuata tramite tali account rimane sotto la responsabilità del relativo titolare dell'account, salvo quanto previsto dalla normativa applicabile.",
          ),
          p("Lo Sviluppatore non è responsabile per:"),
          bullet(
            "accessi abusivi derivanti dalla compromissione dell'account dell'Utente;",
          ),
          bullet("perdita delle credenziali presso provider esterni;"),
          bullet("violazioni della sicurezza del dispositivo dell'Utente;"),
          bullet(
            "malfunzionamenti, modifiche, sospensioni o cessazioni dei servizi di autenticazione forniti da Google, Facebook o altri provider terzi.",
          ),

          h2("7.2 Richiesta di cancellazione dell'account"),
          p(
            "L'Utente può richiedere la cancellazione del proprio account e dei dati associati attraverso:",
          ),
          bullet(
            "gli strumenti eventualmente disponibili direttamente nell'App;",
          ),
          bullet(
            "i canali ufficiali di supporto indicati nei presenti Termini.",
          ),
          p(
            "Lo Sviluppatore provvederà a gestire la richiesta nei limiti tecnicamente disponibili e nel rispetto degli eventuali obblighi legali applicabili.",
          ),
          p(
            "La cancellazione dell'account può comportare la perdita definitiva delle funzionalità associate allo stesso e dei contributi eventualmente collegati all'account.",
          ),

          h2("7.3 Segnalazioni degli Utenti"),
          p(
            "Gli utenti autenticati possono contribuire al miglioramento del servizio inviando segnalazioni relative ai prodotti presenti nel database di G-Scanner.",
          ),
          p("Le segnalazioni possono consistere esclusivamente in:"),
          bullet("testi;"),
          bullet("informazioni descrittive;"),
          bullet("dati;"),
          bullet("note relative ai prodotti."),
          p(
            "L'App non consente il caricamento di fotografie o immagini tramite tali segnalazioni, salvo eventuali modifiche future comunicate dallo Sviluppatore.",
          ),
          p("L'Utente si impegna a inviare esclusivamente informazioni:"),
          bullet("veritiere;"),
          bullet("pertinenti;"),
          bullet("formulate in buona fede."),
          p("È espressamente vietato:"),
          bullet("inviare segnalazioni false;"),
          bullet("inserire informazioni deliberatamente errate;"),
          bullet("inviare contenuti ingannevoli;"),
          bullet("effettuare attività di spam;"),
          bullet("compromettere la qualità del database;"),
          bullet("utilizzare linguaggio offensivo o illecito;"),
          bullet("arrecare danno all'App o alla community."),

          h2("7.4 Licenza sui contenuti inviati dagli Utenti"),
          p(
            "Con l'invio di segnalazioni tramite l'App, l'Utente concede allo Sviluppatore una licenza gratuita, non esclusiva, valida per la durata necessaria alla gestione, manutenzione e miglioramento dell'Applicazione e del database di G-Scanner, e utilizzabile nei limiti consentiti dalla legge, sui contenuti testuali e informativi forniti.",
          ),
          p(
            "Tale licenza è limitata alle finalità sopra indicate e non potrà essere utilizzata per scopi diversi.",
          ),
          p("A tale scopo, lo Sviluppatore potrà:"),
          bullet("archiviare tali contenuti;"),
          bullet("analizzarli;"),
          bullet("modificarli ove necessario per finalità tecniche;"),
          bullet("integrarli nel database dell'Applicazione;"),
          bullet("utilizzarli per migliorare il funzionamento del servizio."),
          p("La presente licenza non comporta:"),
          bullet("trasferimento della proprietà dei contenuti;"),
          bullet("rinuncia ai diritti eventualmente spettanti all'Utente;"),
          bullet(
            "autorizzazione a utilizzare tali contenuti per finalità estranee alla gestione e al miglioramento di G-Scanner.",
          ),

          h2("7.5 Diritto di sospensione e rimozione account"),
          p("Lo Sviluppatore si riserva il diritto esclusivo di:"),
          bullet("sospendere temporaneamente un account;"),
          bullet("limitare determinate funzionalità;"),
          bullet("eliminare un account;"),
          bullet("rimuovere segnalazioni;"),
          bullet("impedire ulteriori contributi;"),
          p(
            "qualora ritenga, secondo valutazione ragionevole e discrezionale, che il comportamento dell'Utente sia:",
          ),
          bullet("contrario ai presenti Termini;"),
          bullet("fraudolento;"),
          bullet("dannoso per la community;"),
          bullet("dannoso per il funzionamento tecnico dell'App;"),
          bullet("idoneo a compromettere la qualità del database."),
          p(
            "Tale decisione potrà essere adottata anche senza preavviso nei casi in cui ciò sia necessario per proteggere sicurezza, integrità o corretto funzionamento del servizio.",
          ),
          divider(),

          h1("8. Proprietà Intellettuale dell'Applicazione"),
          p(
            "Tutti i diritti di proprietà intellettuale relativi a G-Scanner, inclusi, a titolo esemplificativo:",
          ),
          bullet("codice sorgente;"),
          bullet("codice compilato;"),
          bullet("algoritmi;"),
          bullet("strutture dati;"),
          bullet("interfaccia grafica;"),
          bullet("elementi visivi;"),
          bullet("logiche applicative;"),
          bullet("architettura software;"),
          bullet("denominazione dell'App;"),
          p(
            "appartengono esclusivamente a **Emanuele Ciotola**, salvo eventuali componenti appartenenti a terze parti secondo le rispettive licenze.",
          ),
          p(
            "Il fatto che il codice sorgente dell'App sia pubblicamente consultabile tramite GitHub ha esclusivamente finalità di:",
          ),
          bullet("trasparenza;"),
          bullet("verifica tecnica;"),
          bullet("studio del funzionamento."),
          p("La pubblicazione del codice non costituisce:"),
          bullet("concessione di licenza Open Source;"),
          bullet("autorizzazione al riutilizzo libero;"),
          bullet("rinuncia ai diritti di proprietà intellettuale;"),
          bullet("trasferimento di diritti a terzi."),
          divider(),

          h1("9. Licenza del Codice e Limitazioni d'Uso"),
          p(
            "Il codice dell'App è distribuito secondo un modello **Source-Available** con licenza proprietaria **\"All Rights Reserved\"**.",
          ),
          p(
            "La possibilità di consultare il codice sorgente non attribuisce all'Utente alcun diritto di:",
          ),
          bullet("utilizzare liberamente il software;"),
          bullet("modificarlo;"),
          bullet("distribuirlo;"),
          bullet("creare opere derivate;"),
          bullet("commercializzarlo."),
          p(
            "Salvo preventiva autorizzazione scritta dello Sviluppatore, è vietato:",
          ),
          bullet("copiare integralmente o parzialmente il codice;"),
          bullet("clonare il progetto;"),
          bullet("riprodurre l'algoritmo;"),
          bullet("replicare la logica di funzionamento;"),
          bullet("riprodurre la UI;"),
          bullet("creare versioni derivate;"),
          bullet("distribuire copie dell'App;"),
          bullet("utilizzare componenti del codice per altri progetti;"),
          bullet("sfruttare commercialmente il software."),
          p("È inoltre vietato effettuare:"),
          bullet("reverse engineering;"),
          bullet("decompilazione;"),
          bullet("disassemblaggio;"),
          bullet(
            "analisi del codice finalizzata alla ricostruzione delle logiche interne;",
          ),
          bullet("scraping degli algoritmi;"),
          bullet("estrazione automatizzata di componenti software;"),
          bullet("ricostruzione del funzionamento interno dell'Applicazione."),
          p(
            "Qualsiasi utilizzo non autorizzato potrà comportare l'esercizio dei rimedi previsti dalla normativa applicabile, inclusa la richiesta di risarcimento dei danni eventualmente subiti.",
          ),
          p(
            "Le presenti limitazioni si applicano nei limiti massimi consentiti dalla normativa applicabile e non intendono limitare eventuali diritti inderogabili riconosciuti dalla legge, inclusi quelli relativi all'interoperabilità del software ove applicabili.",
          ),
          divider(),

          h1("10. Licenza Limitata di Utilizzo dell'Applicazione"),
          p("Lo Sviluppatore concede all'Utente una licenza:"),
          bullet("personale;"),
          bullet("limitata;"),
          bullet("non esclusiva;"),
          bullet("revocabile;"),
          bullet("non trasferibile;"),
          p(
            "per utilizzare G-Scanner esclusivamente per finalità personali e lecite.",
          ),
          p("La licenza consente esclusivamente:"),
          bullet("l'accesso alle funzionalità disponibili;"),
          bullet("l'utilizzo dell'App secondo i presenti Termini;"),
          bullet("la consultazione delle informazioni fornite."),
          p("La presente licenza non comporta alcun trasferimento di:"),
          bullet("proprietà dell'App;"),
          bullet("diritti sul codice;"),
          bullet("diritti sugli algoritmi;"),
          bullet("diritti sulla UI;"),
          bullet("diritti di sfruttamento economico."),
          p(
            "Ogni diritto non espressamente concesso rimane riservato allo Sviluppatore.",
          ),
          divider(),

          h1("11. Disponibilità, Aggiornamenti ed Evoluzione del Software"),
          p(
            "L'Utente riconosce che G-Scanner è un software in continua evoluzione.",
          ),
          p(
            "Lo Sviluppatore può modificare, aggiornare, migliorare, sospendere o interrompere funzionalità dell'App in qualsiasi momento, anche senza preavviso, quando ciò sia necessario per motivi tecnici, organizzativi, di sicurezza o sviluppo.",
          ),
          p("A titolo esemplificativo, lo Sviluppatore può:"),
          bullet("modificare algoritmi;"),
          bullet("aggiornare componenti;"),
          bullet("cambiare modalità di funzionamento;"),
          bullet("introdurre nuove funzioni;"),
          bullet("rimuovere funzioni esistenti;"),
          bullet("sospendere temporaneamente il servizio."),
          p("Lo Sviluppatore non garantisce:"),
          bullet("disponibilità continua;"),
          bullet("assenza assoluta di errori;"),
          bullet("compatibilità permanente con ogni dispositivo;"),
          bullet("mantenimento indefinito di tutte le funzionalità."),
          p(
            "Tali modifiche non attribuiscono automaticamente all'Utente diritto a compensazioni, rimborsi o risarcimenti, nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore.",
          ),
          divider(),

          h1(
            "12. Uso Corretto dell'Applicazione, Sicurezza e Divieto di Abuso Tecnico",
          ),
          p(
            "L'Utente si impegna a utilizzare G-Scanner in modo corretto, conforme alla legge, ai presenti Termini e ai principi di buona fede.",
          ),
          p(
            "L'Utente è tenuto a non utilizzare l'App in modo tale da compromettere:",
          ),
          bullet("la sicurezza del servizio;"),
          bullet("la disponibilità dell'Applicazione;"),
          bullet("l'integrità dei sistemi informatici;"),
          bullet("l'esperienza degli altri utenti;"),
          bullet("la qualità dei dati gestiti."),
          p(
            "È espressamente vietato, salvo preventiva autorizzazione scritta dello Sviluppatore:",
          ),
          bullet(
            "effettuare attività di scraping automatizzato dei dati, delle interfacce o delle funzionalità dell'App;",
          ),
          bullet(
            "utilizzare bot, crawler o strumenti automatici per accedere al servizio;",
          ),
          bullet(
            "inviare un numero eccessivo o irragionevole di richieste verso sistemi o API;",
          ),
          bullet(
            "tentare di sovraccaricare server, database o infrastrutture utilizzate dall'App;",
          ),
          bullet(
            "aggirare sistemi di sicurezza, autenticazione o limitazioni tecniche;",
          ),
          bullet(
            "tentare di ottenere accessi non autorizzati a dati o componenti riservati;",
          ),
          bullet("interferire con il normale funzionamento dell'Applicazione;"),
          bullet(
            "introdurre codice dannoso, malware o componenti potenzialmente dannosi;",
          ),
          bullet(
            "effettuare reverse engineering, decompilazione o attività finalizzate alla ricostruzione del funzionamento interno dell'App.",
          ),
          p(
            "Qualsiasi comportamento idoneo a compromettere sicurezza, stabilità o disponibilità del servizio potrà comportare la sospensione o cessazione dell'accesso dell'Utente, oltre all'eventuale esercizio dei rimedi previsti dalla normativa applicabile.",
          ),
          divider(),

          h1("13. Comunicazioni Elettroniche"),
          p(
            "L'Utente accetta di ricevere comunicazioni elettroniche strettamente necessarie alla gestione del rapporto con lo Sviluppatore e al corretto funzionamento dell'App.",
          ),
          p("Tali comunicazioni possono riguardare:"),
          bullet("aggiornamenti tecnici;"),
          bullet("informazioni relative alla sicurezza;"),
          bullet("modifiche ai presenti Termini;"),
          bullet("modifiche rilevanti alle funzionalità dell'App;"),
          bullet("comunicazioni amministrative relative all'account;"),
          bullet("informazioni necessarie alla gestione del servizio."),
          p(
            "Tali comunicazioni hanno esclusivamente finalità tecniche, amministrative o di servizio e non costituiscono automaticamente comunicazioni commerciali o promozionali.",
          ),
          p(
            "Eventuali comunicazioni promozionali saranno soggette agli eventuali consensi richiesti dalla normativa applicabile.",
          ),
          divider(),

          h1("14. Servizi Esterni, Infrastrutture di Terze Parti e Provider"),
          p(
            "Per il funzionamento dell'App possono essere utilizzati servizi forniti da soggetti terzi, inclusi, a titolo esemplificativo:",
          ),
          bullet("servizi di autenticazione;"),
          bullet("servizi cloud;"),
          bullet("database esterni;"),
          bullet("servizi di hosting;"),
          bullet("GitHub Pages;"),
          bullet("Firebase;"),
          bullet("API e infrastrutture tecnologiche di terze parti."),
          p(
            "L'Utente riconosce che tali servizi sono gestiti autonomamente dai rispettivi fornitori e soggetti ai relativi termini contrattuali, condizioni d'uso e informative sulla privacy.",
          ),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, lo Sviluppatore non è responsabile per:",
          ),
          bullet("interruzioni temporanee dei servizi esterni;"),
          bullet("malfunzionamenti dei provider;"),
          bullet("modifiche tecniche effettuate da soggetti terzi;"),
          bullet("sospensione o cessazione di API;"),
          bullet("variazioni delle condizioni dei servizi esterni;"),
          bullet(
            "perdita di disponibilità di infrastrutture non controllate direttamente dallo Sviluppatore.",
          ),
          divider(),

          h1("15. Limitazione Generale di Responsabilità"),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, G-Scanner viene fornita:\n**\"così com'è\" (\"AS IS\")**\ne\n**\"come disponibile\" (\"AS AVAILABLE\")**.",
          ),
          p("Lo Sviluppatore non garantisce che:"),
          bullet("l'App sia disponibile senza interruzioni;"),
          bullet("il servizio sia privo di errori;"),
          bullet("tutte le funzionalità siano sempre operative;"),
          bullet("i dati utilizzati siano sempre completi o aggiornati;"),
          bullet("i risultati prodotti siano sempre privi di inesattezze;"),
          bullet(
            "l'App sia compatibile con ogni dispositivo o configurazione tecnica.",
          ),
          p(
            "Lo Sviluppatore non potrà essere ritenuto responsabile per danni derivanti dall'utilizzo dell'App, salvo nei casi in cui tale responsabilità non possa essere esclusa o limitata ai sensi della normativa applicabile.",
          ),
          p("In particolare, nulla nei presenti Termini limita o esclude:"),
          bullet(
            "i diritti inderogabili riconosciuti ai consumatori dalla normativa italiana ed europea;",
          ),
          bullet(
            "la responsabilità derivante da condotte dolose o gravemente colpose nei casi previsti dalla legge;",
          ),
          bullet(
            "qualsiasi altra responsabilità che non possa essere legalmente esclusa.",
          ),
          divider(),

          h1("16. Privacy Policy e Cookie Policy"),
          p(
            "Il trattamento dei dati personali degli Utenti è disciplinato da una specifica **Privacy Policy**, documento separato e indipendente rispetto ai presenti Termini.",
          ),
          p("La Privacy Policy disciplina, tra gli altri aspetti:"),
          bullet("quali dati personali vengono raccolti;"),
          bullet("le finalità del trattamento;"),
          bullet(
            "le modalità di utilizzo dei dati e le architetture cloud coinvolte;",
          ),
          bullet("gli eventuali servizi terzi coinvolti;"),
          bullet(
            "i diritti riconosciuti agli interessati ai sensi della normativa applicabile.",
          ),
          p(
            "All'interno della medesima Privacy Policy sono inoltre fornite tutte le informazioni relative all'utilizzo di cookie tecnici e tecnologie di archiviazione locale (es. *SharedPreferences* o *LocalStorage*), utilizzati dall'App esclusivamente per necessità tecniche e di funzionamento, senza alcun tracciamento a fini pubblicitari.",
          ),
          p("I presenti Termini e Condizioni d'Uso:"),
          bullet("non sostituiscono la Privacy Policy;"),
          bullet("non costituiscono un'informativa privacy;"),
          bullet(
            "non disciplinano integralmente il trattamento dei dati personali.",
          ),
          p(
            "L'Utente è invitato a consultare tali documenti prima dell'utilizzo dell'App.",
          ),
          divider(),

          h1("17. Modifiche ai Termini"),
          p(
            "Lo Sviluppatore si riserva il diritto di modificare, integrare o aggiornare i presenti Termini in qualsiasi momento.",
          ),
          p(
            "Le modifiche possono rendersi necessarie, a titolo esemplificativo, per:",
          ),
          bullet("evoluzione tecnica dell'App;"),
          bullet("modifiche normative;"),
          bullet("introduzione di nuove funzionalità;"),
          bullet("esigenze di sicurezza;"),
          bullet("aggiornamenti organizzativi."),
          p(
            "La versione aggiornata dei Termini sarà identificata mediante indicazione della relativa versione e della data di ultimo aggiornamento.",
          ),
          p(
            "Le modifiche avranno efficacia dalla loro pubblicazione attraverso i canali ufficiali dell'App.",
          ),
          p(
            "L'utilizzo continuato dell'Applicazione successivamente alla pubblicazione delle modifiche costituisce accettazione della nuova versione dei Termini.",
          ),
          p(
            "Qualora l'Utente non intenda accettare le modifiche, dovrà interrompere l'utilizzo dell'App e potrà richiedere la cancellazione del proprio account secondo le modalità previste.",
          ),
          divider(),

          h1("18. Lingua dei Termini e delle Informative"),
          p(
            "I presenti Termini e Condizioni d'Uso, nonché la Privacy Policy e gli eventuali ulteriori documenti legali relativi all'Applicazione, sono redatti originariamente in **lingua italiana**. Eventuali traduzioni in altre lingue sono fornite esclusivamente a fini di cortesia e per agevolare la comprensione da parte degli Utenti. In caso di discrepanze, incongruenze, ambiguità o conflitti interpretativi tra la versione in lingua italiana e qualsiasi versione tradotta, prevarrà la versione in lingua italiana, nei limiti massimi consentiti dalla normativa applicabile.",
          ),
          divider(),

          h1("19. Disposizioni Finali"),
          p(
            "Qualora una qualsiasi disposizione dei presenti Termini venga dichiarata nulla, invalida o inefficace da un'autorità competente, tale circostanza non comprometterà la validità delle restanti disposizioni.",
          ),
          p(
            "Le disposizioni rimanenti continueranno a produrre pieno effetto nella misura massima consentita dalla normativa applicabile.",
          ),
          p(
            "L'eventuale mancato esercizio da parte dello Sviluppatore di un diritto previsto dai presenti Termini non costituisce rinuncia definitiva allo stesso.",
          ),
          p(
            "I presenti Termini costituiscono l'accordo completo tra l'Utente e lo Sviluppatore relativamente all'utilizzo dell'App, limitatamente agli aspetti disciplinati nel presente documento.",
          ),
          divider(),

          h1("20. Legge Applicabile e Foro Competente"),
          p(
            "I presenti Termini sono disciplinati dalla **legge italiana**, fatto salvo quanto previsto dalle norme imperative applicabili dell'Unione Europea e dalla normativa italiana a tutela dei consumatori.",
          ),
          p(
            "Per gli Utenti qualificabili come consumatori ai sensi della normativa applicabile, restano applicabili le norme inderogabili relative alla competenza territoriale e alla tutela del consumatore.",
          ),
          p(
            "Per gli Utenti che non rivestano tale qualifica, eventuali controversie derivanti dall'interpretazione, esecuzione o validità dei presenti Termini saranno disciplinate secondo la legge italiana e sottoposte al foro competente secondo le disposizioni applicabili.",
          ),
          divider(),

          h1("Contatti"),
          p("**Applicazione:** G-Scanner"),
          p("**Sviluppatore:** Emanuele Ciotola"),
          p("**Email di supporto:**\n**supporto-gscanner@googlegroups.com**"),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}

Widget buildNativePrivacyPolicy(Color textColor) {
  // Helper per creare le parti in grassetto automaticamente e velocemente
  Widget pContent(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        children: spans,
      ),
    );
  }

  Widget h1(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget h2(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: pContent(text),
  );

  Widget bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        ),
        Expanded(child: pContent(text)),
      ],
    ),
  );

  Widget divider() => const Divider(height: 32);

  return SingleChildScrollView(
    child: SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          h2("Privacy Policy di G-Scanner"),
          p(
            "**Versione:** 1.0\n**Data di entrata in vigore:** 17 luglio 2026\n**Data di ultimo aggiornamento:** 17 luglio 2026",
          ),
          divider(),

          p(
            "La presente Privacy Policy descrive le modalità di trattamento dei dati personali effettuato attraverso l'applicazione mobile e web **G-Scanner**, sviluppata nel rispetto del **Regolamento (UE) 2016/679 (GDPR)** e della normativa italiana applicabile in materia di protezione dei dati personali.",
          ),
          divider(),

          h1("Finalità dell'applicazione"),
          p(
            "G-Scanner è un'applicazione che consente agli utenti di consultare informazioni relative ai prodotti alimentari mediante la scansione dei codici a barre, con particolare attenzione alle esigenze delle persone affette da celiachia o intolleranza al lattosio.",
          ),
          p(
            "L'applicazione permette inoltre agli utenti di configurare specifiche preferenze alimentari, ricevere indicazioni basate su filtri informativi preimpostati e partecipare a una community attraverso la condivisione di segnalazioni relative ai prodotti.",
          ),
          p("**Importante – Limitazione di responsabilità**"),
          p(
            "Le informazioni fornite da G-Scanner hanno esclusivamente finalità informative e di supporto all'utente.",
          ),
          p(
            "L'applicazione **non costituisce un dispositivo medico**, **non fornisce consulenze mediche**, **non ha valore diagnostico o terapeutico** e **non produce effetti o valutazioni aventi valore legale**.",
          ),
          p("Le informazioni visualizzate non sostituiscono in alcun modo:"),
          bullet(
            "il parere di un medico o di altro professionista sanitario qualificato;",
          ),
          bullet(
            "la consultazione delle etichette ufficiali dei prodotti alimentari;",
          ),
          bullet("le informazioni fornite direttamente dal produttore."),
          p(
            "Le valutazioni generate dall'applicazione si basano esclusivamente sui dati disponibili nel database e sulle impostazioni configurate dall'utente e potrebbero non riflettere variazioni nella composizione dei prodotti, aggiornamenti delle ricette da parte dei produttori o informazioni non disponibili.",
          ),
          p(
            "L'utente è sempre tenuto a verificare autonomamente la composizione e l'etichettatura dei prodotti prima del consumo.",
          ),
          divider(),

          h1("1. Titolare del Trattamento"),
          p("Il Titolare del Trattamento dei dati personali è:"),
          p("**Emanuele Ciotola**"),
          p("E-mail:\n**supporto-gscanner@googlegroups.com**"),
          p(
            "Per qualsiasi richiesta relativa al trattamento dei dati personali o all'esercizio dei diritti previsti dal GDPR è possibile contattare il Titolare al suddetto indirizzo.",
          ),
          divider(),

          h1("2. Tipologie di dati trattati"),
          p(
            "L'applicazione tratta esclusivamente i dati necessari al proprio funzionamento e all'erogazione delle funzionalità offerte.",
          ),

          h2("2.1 Utenti anonimi"),
          p(
            "Quando G-Scanner viene utilizzata senza effettuare l'accesso, i dati personali dell'utente e le preferenze configurate rimangono esclusivamente sul dispositivo e vengono memorizzati localmente tramite **SharedPreferences**.",
          ),
          p("Tra questi rientrano:"),
          bullet("cronologia delle scansioni;"),
          bullet("impostazioni dell'applicazione;"),
          bullet(
            "preferenze relative alle funzionalità alimentari e sanitarie selezionate dall'utente.",
          ),
          p(
            "Tali dati personali **non vengono trasmessi ai server del Titolare**.",
          ),
          p(
            "Resta tuttavia inteso che le **segnalazioni relative ai prodotti**, qualora inviate tramite l'applicazione, vengono memorizzate nel database cloud dell'applicazione e rese disponibili agli altri utenti della community al fine di migliorare il servizio.",
          ),
          p(
            "Le segnalazioni pubblicate nella community possono contenere esclusivamente:",
          ),
          bullet("informazioni relative all'alimento o prodotto segnalato;"),
          bullet("eventuali note inserite dall'utente;"),
          bullet("il motivo della segnalazione."),
          p(
            "L'identità dell'utente che effettua la segnalazione, inclusi **nome, cognome, indirizzo e-mail o altri dati identificativi**, **non viene mai resa pubblica né associata visibilmente alla segnalazione in nessuna circostanza**.",
          ),
          p(
            "Anche le segnalazioni effettuate da altri utenti possono essere consultate dagli utilizzatori dell'applicazione, indipendentemente dall'autenticazione.",
          ),
          divider(),

          h2("2.2 Utenti autenticati"),
          p(
            "L'utente può autenticarsi mediante **Firebase Authentication** utilizzando un account:",
          ),
          bullet("Google;"),
          bullet("Facebook."),
          p(
            "A seguito dell'autenticazione vengono acquisiti dal provider i dati necessari all'identificazione dell'utente, che possono comprendere:",
          ),
          bullet("nome;"),
          bullet("cognome;"),
          bullet("indirizzo e-mail;"),
          bullet(
            "numero di telefono, ove disponibile o associato al profilo utilizzato per l'autenticazione.",
          ),
          p(
            "A tali informazioni viene associato un identificativo univoco dell'utente (**User ID**).",
          ),
          p(
            "G-Scanner non accede alle credenziali di autenticazione dell'utente, quali password o strumenti equivalenti, e non tratta tali informazioni.",
          ),
          divider(),

          h2("2.3 Dati memorizzati nel database cloud"),
          p(
            "Per gli utenti autenticati vengono memorizzati su **Firebase Firestore**, associati all'identificativo dell'utente:",
          ),
          bullet("cronologia delle scansioni;"),
          bullet("elenco delle segnalazioni inviate;"),
          bullet("impostazioni relative alle preferenze alimentari:"),
          bullet("Avvertimento Additivi;"),
          bullet("Filtro Rigido Contaminazioni;"),
          bullet("Intolleranza al Lattosio;"),
          bullet(
            "eventuali impostazioni relative agli avvisi sulle contaminazioni;",
          ),
          bullet("lingua selezionata;"),
          bullet("tema grafico scelto."),
          p(
            "I dati identificativi ottenuti mediante l'autenticazione (nome, cognome, indirizzo e-mail ed eventuale numero di telefono, ove disponibile) sono utilizzati esclusivamente per:",
          ),
          bullet("consentire la gestione dell'account;"),
          bullet(
            "associare correttamente i dati dell'utente al relativo profilo;",
          ),
          bullet("fornire le funzionalità riservate agli utenti autenticati."),
          divider(),

          h2("2.4 Cookie e Tecnologie di Archiviazione Locale"),
          p(
            "G-Scanner (sia nella versione Web App che come applicazione Mobile) non utilizza cookie di profilazione, strumenti di tracciamento pubblicitario o sistemi di analytics di terze parti.",
          ),
          p(
            "L'applicazione utilizza esclusivamente tecnologie di archiviazione locale strettamente necessarie (come *SharedPreferences* su dispositivi mobili e *LocalStorage / Cookie tecnici* su browser) al solo fine di:",
          ),
          bullet(
            "Mantenere la sessione utente attiva in modo sicuro tramite Firebase Authentication;",
          ),
          bullet(
            "Memorizzare localmente le preferenze dell'utente (es. lingua, tema grafico) e la conferma di accettazione dei documenti legali.",
          ),
          p(
            "Poiché si tratta esclusivamente di strumenti tecnici indispensabili per l'erogazione del servizio richiesto dall'utente, ai sensi della normativa europea (Direttiva ePrivacy) e dei provvedimenti del Garante Privacy italiano, non è richiesto il preventivo consenso dell'utente per il loro utilizzo. L'utente viene informato della loro presenza tramite la presente Privacy Policy, senza necessità di banner o documenti separati.",
          ),
          p(
            "I dati memorizzati localmente rimangono sul dispositivo dell'utente fino alla loro eliminazione o alla disinstallazione dell'applicazione.",
          ),
          divider(),

          h1("3. Dati appartenenti a categorie particolari (Art. 9 GDPR)"),
          p(
            "G-Scanner consente all'utente di configurare specifiche preferenze personali finalizzate alla consultazione delle informazioni sui prodotti alimentari. Tali impostazioni possono riflettere lo stato di salute o particolari esigenze alimentari dell'utente e, pertanto, possono costituire **categorie particolari di dati personali**, ai sensi dell'**art. 9 del Regolamento (UE) 2016/679 (GDPR)**.",
          ),
          p("Le impostazioni disponibili nell'applicazione sono le seguenti:"),
          bullet(
            "**Avvertimento Additivi**: genera un avviso in presenza di ingredienti quali amidi modificati o aromi la cui origine non sia specificata, affinché l'utente possa effettuare ulteriori verifiche.",
          ),
          bullet(
            "**Filtro Rigido Contaminazioni**: considera come **\"Vietato\"** qualsiasi alimento la cui etichetta riporti diciture quali **\"può contenere tracce di glutine\"** o formulazioni equivalenti relative alla possibile contaminazione da glutine.",
          ),
          bullet(
            "**Intolleranza al Lattosio**: verifica la presenza di ingredienti quali lattosio, burro, latte in polvere o siero del latte, segnalandone l'eventuale presenza secondo le funzionalità dell'applicazione.",
          ),
          p(
            "Al **primo avvio dell'applicazione** risultano abilitate per impostazione predefinita esclusivamente le seguenti opzioni:",
          ),
          bullet("Avvertimento Additivi;"),
          bullet("Filtro Rigido Contaminazioni."),
          p(
            "L'opzione **Intolleranza al Lattosio** è inizialmente disabilitata e può essere attivata dall'utente in qualsiasi momento.",
          ),
          p(
            "Il trattamento di tali informazioni avviene **esclusivamente previo consenso esplicito dell'utente**, ai sensi dell'**art. 9, paragrafo 2, lettera a) del GDPR**.",
          ),
          p(
            "L'utente è libero di modificare, attivare o disattivare in qualsiasi momento le suddette impostazioni secondo le proprie esigenze personali.",
          ),
          p(
            "Tali scelte sono effettuate sotto la responsabilità dell'utente, il quale riconosce che G-Scanner costituisce esclusivamente uno **strumento di supporto informativo** e non sostituisce:",
          ),
          bullet("la verifica delle etichette dei prodotti;"),
          bullet("le informazioni fornite dal produttore;"),
          bullet(
            "il parere di un medico o di altro professionista sanitario qualificato.",
          ),
          p(
            "L'eventuale modifica delle impostazioni e l'utilizzo delle informazioni fornite dall'applicazione avvengono pertanto **a esclusivo rischio dell'utente**.",
          ),
          p(
            "L'utente può in ogni momento modificare le proprie preferenze o revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca.",
          ),
          divider(),

          h1("4. Finalità del trattamento"),
          p(
            "I dati personali raccolti attraverso G-Scanner sono trattati per le seguenti finalità:",
          ),
          bullet(
            "consentire la scansione dei codici a barre e la consultazione delle informazioni relative ai prodotti alimentari;",
          ),
          bullet(
            "permettere la personalizzazione dell'esperienza dell'utente tramite la configurazione delle preferenze alimentari e delle impostazioni dell'applicazione;",
          ),
          bullet(
            "consentire agli utenti autenticati la sincronizzazione dei dati tra dispositivi diversi;",
          ),
          bullet(
            "permettere la partecipazione alla community attraverso l'invio, la gestione e la consultazione delle segnalazioni relative ai prodotti;",
          ),
          bullet(
            "gestire l'autenticazione tramite provider esterni quali Google e Facebook;",
          ),
          bullet(
            "garantire il corretto funzionamento tecnico dell'applicazione, la sicurezza dei servizi e la protezione dei dati trattati.",
          ),
          divider(),

          h1("5. Base giuridica del trattamento"),
          p("Il trattamento dei dati personali si fonda su:"),
          bullet(
            "consenso esplicito dell'interessato per il trattamento delle **categorie particolari di dati personali** relative alla salute (art. 9, par. 2, lett. a GDPR);",
          ),
          bullet(
            "esecuzione del servizio richiesto dall'utente e delle funzionalità offerte dall'applicazione;",
          ),
          bullet(
            "adempimento degli obblighi previsti dalla normativa vigente;",
          ),
          bullet(
            "interesse legittimo del Titolare relativamente alla sicurezza tecnica dell'applicazione e alla prevenzione di utilizzi impropri del servizio, ove applicabile.",
          ),
          divider(),

          h1("6. Minori"),
          p("L'utilizzo di G-Scanner è vietato ai minori di **14 anni**."),
          p(
            "In conformità alla normativa italiana sul consenso digitale, l'applicazione non è destinata a utenti di età inferiore ai 14 anni e non raccoglie consapevolmente dati personali riferibili a tali soggetti.",
          ),
          p(
            "Qualora il Titolare venga a conoscenza della presenza di dati appartenenti a un minore di 14 anni, provvederà alla loro tempestiva cancellazione.",
          ),
          divider(),

          h1("7. Permessi richiesti dall'applicazione"),
          p(
            "Per garantire il corretto funzionamento delle funzionalità offerte, G-Scanner può richiedere alcuni permessi del dispositivo dell'utente.",
          ),

          h2("Fotocamera"),
          p(
            "La fotocamera viene utilizzata esclusivamente per consentire la scansione dei codici a barre dei prodotti.",
          ),
          p(
            "Le immagini acquisite tramite fotocamera non vengono salvate, trasmesse o utilizzate per finalità diverse dalla scansione del codice a barre.",
          ),
          divider(),

          h2("Connessione Internet"),
          p("La connessione Internet è necessaria per:"),
          bullet("effettuare l'autenticazione tramite i provider supportati;"),
          bullet("sincronizzare i dati degli utenti autenticati;"),
          bullet("accedere ai servizi cloud utilizzati dall'applicazione;"),
          bullet(
            "consentire il funzionamento delle funzionalità basate sui dati della community.",
          ),
          divider(),

          h2("Tema di sistema"),
          p(
            "Il permesso relativo al tema di sistema viene utilizzato esclusivamente per adattare automaticamente l'interfaccia grafica dell'applicazione alla modalità chiara o scura configurata sul dispositivo dell'utente.",
          ),
          divider(),

          h2("Posizione geografica approssimativa di sistema"),
          p(
            "L'applicazione utilizza esclusivamente la posizione geografica approssimativa fornita dal sistema operativo **soltanto al primo avvio dell'applicazione**, esclusivamente allo scopo di determinare automaticamente la lingua dell'interfaccia.",
          ),
          p("Tale informazione:"),
          bullet("viene elaborata esclusivamente sul dispositivo;"),
          bullet("non comporta l'accesso alla posizione GPS precisa;"),
          bullet("non viene salvata;"),
          bullet("non viene trasmessa ai server;"),
          bullet(
            "non viene utilizzata per attività di profilazione o tracciamento.",
          ),
          divider(),

          h1(
            "8. Assenza di pubblicità, tracciamento e raccolta dati analitici",
          ),
          p(
            "G-Scanner adotta una politica di tutela della riservatezza degli utenti.",
          ),
          p("L'applicazione:"),
          bullet("è completamente gratuita;"),
          bullet("non contiene pubblicità;"),
          bullet("non utilizza strumenti di analytics;"),
          bullet("non utilizza Google Analytics;"),
          bullet("non utilizza Firebase Crashlytics;"),
          bullet("non effettua profilazione degli utenti;"),
          bullet("non svolge attività di tracciamento degli utenti;"),
          bullet("non vende dati personali;"),
          bullet(
            "non comunica né cede dati personali a terzi per finalità commerciali.",
          ),
          p(
            "In particolare, **G-Scanner non raccoglie identificativi pubblicitari, informazioni di utilizzo dell'applicazione, dati diagnostici o dati tecnici del dispositivo per finalità analitiche o di profilazione**.",
          ),
          p(
            "L'applicazione non effettua processi di monitoraggio comportamentale dell'utente né crea profili commerciali o pubblicitari.",
          ),
          divider(),

          h1("9. Conservazione dei dati"),
          h2("9.1 Utenti anonimi"),
          p(
            "Quando l'utente utilizza G-Scanner senza autenticazione, i dati personali e le preferenze configurate rimangono esclusivamente memorizzati localmente sul dispositivo tramite **SharedPreferences**.",
          ),
          p("Tali dati vengono conservati fino a quando:"),
          bullet(
            "l'utente li elimina tramite le funzionalità disponibili nell'applicazione;",
          ),
          bullet("l'applicazione viene disinstallata;"),
          bullet(
            "il dispositivo viene ripristinato o i dati locali vengono cancellati.",
          ),
          p(
            "Le segnalazioni relative ai prodotti inviate alla community costituiscono un trattamento distinto e vengono invece conservate nel database cloud dell'applicazione per consentirne la consultazione da parte degli altri utenti.",
          ),
          divider(),

          h2("9.2 Utenti autenticati"),
          p(
            "Per gli utenti autenticati i dati vengono conservati mediante una modalità di **doppia memorizzazione**:",
          ),
          bullet(
            "localmente sul dispositivo dell'utente, per consentire un utilizzo rapido dell'applicazione;",
          ),
          bullet(
            "nel database cloud Firebase Firestore, per consentire la sincronizzazione delle informazioni tra dispositivi diversi e il mantenimento delle funzionalità associate all'account.",
          ),
          p(
            "I dati associati all'account rimangono conservati fino alla loro eliminazione secondo le modalità descritte nel successivo articolo relativo alla cancellazione dei dati.",
          ),
          divider(),

          h1(
            "10. Diritto alla cancellazione e gestione dell'account (Art. 17 GDPR)",
          ),
          p(
            "L'utente dispone di due modalità distinte per la gestione della cancellazione dei propri dati.",
          ),

          h2(
            "10.1 Eliminazione dell'account tramite funzione interna dell'applicazione",
          ),
          p(
            "Qualora l'utente utilizzi l'apposita funzione interna di eliminazione dell'account disponibile in G-Scanner, viene effettuata la cancellazione del relativo **profilo di autenticazione Firebase Authentication**.",
          ),
          p("Tale operazione comporta:"),
          bullet(
            "la rimozione definitiva dell'associazione tra l'account e i dati identificativi utilizzati per l'autenticazione;",
          ),
          bullet(
            "la cancellazione dei riferimenti relativi a email, nome, cognome ed eventuali dati del provider associati al profilo.",
          ),
          p(
            "Tuttavia, l'eliminazione del profilo di autenticazione **non comporta automaticamente la distruzione fisica immediata dei documenti presenti su Firebase Firestore**.",
          ),
          p("I dati eventualmente presenti nel database cloud, quali:"),
          bullet("cronologia delle scansioni;"),
          bullet("impostazioni dell'applicazione;"),
          bullet("dati associati all'identificativo utente;"),
          p(
            "non risultano più collegabili all'identità dell'utente e diventano tecnicamente inaccessibili tramite il normale utilizzo dell'applicazione.",
          ),
          p(
            "Il collegamento tra tali dati e l'identità dell'utente viene eliminato definitivamente.",
          ),
          divider(),

          h2(
            "10.2 Cancellazione completa e definitiva dei dati (Wipe dei dati)",
          ),
          p(
            "Qualora l'utente desideri la cancellazione fisica completa e definitiva di tutti i record associati al proprio identificativo presente nei sistemi cloud, deve inoltrare una richiesta esplicita al Titolare tramite:",
          ),
          p("**supporto-gscanner@googlegroups.com**"),
          p(
            "La richiesta deve essere effettuata **prima di procedere all'eliminazione del profilo tramite l'applicazione**, utilizzando lo stesso indirizzo e-mail associato all'account utilizzato per l'accesso.",
          ),
          p(
            "Questa procedura è necessaria affinché il Titolare possa verificare l'identità del richiedente e individuare correttamente i record associati all'account.",
          ),
          p(
            "Qualora l'utente elimini preventivamente il proprio profilo dall'applicazione senza aver inviato la richiesta di cancellazione completa, potrebbe non essere più possibile verificare l'identità del richiedente e individuare i dati precedentemente associati all'account eliminato.",
          ),
          p(
            "A seguito della verifica dell'identità, il Titolare procederà alla cancellazione definitiva dei dati presenti nei sistemi cloud associati all'identificativo dell'utente, nei limiti tecnicamente disponibili e previsti dalla normativa applicabile.",
          ),
          divider(),

          h1("11. Diritti dell'interessato"),
          p(
            "Ai sensi degli articoli 15 e seguenti del GDPR, l'interessato può esercitare il diritto di:",
          ),
          bullet("ottenere conferma dell'esistenza dei propri dati personali;"),
          bullet("accedere ai dati personali trattati;"),
          bullet("richiedere la rettifica dei dati inesatti;"),
          bullet(
            "richiedere la cancellazione dei dati nei casi previsti dalla normativa;",
          ),
          bullet("ottenere la limitazione del trattamento;"),
          bullet("opporsi al trattamento nei casi consentiti;"),
          bullet(
            "revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca;",
          ),
          bullet(
            "ricevere i propri dati in formato strutturato, ove applicabile;",
          ),
          bullet(
            "proporre reclamo all'Autorità Garante per la Protezione dei Dati Personali.",
          ),
          p(
            "Per l'esercizio dei propri diritti è possibile contattare il Titolare:",
          ),
          p("**supporto-gscanner@googlegroups.com**"),
          divider(),

          h1("12. Sicurezza dei dati"),
          p(
            "I dati personali sono trattati mediante strumenti informatici e misure tecniche e organizzative adeguate a garantirne:",
          ),
          bullet("riservatezza;"),
          bullet("integrità;"),
          bullet("disponibilità;"),
          bullet("protezione contro accessi non autorizzati."),
          p(
            "In particolare, per i dati conservati tramite infrastruttura Firebase, l'accesso ai dati in cloud è limitato esclusivamente ai soggetti autorizzati ed è protetto mediante le misure tecniche e di sicurezza messe a disposizione dall'infrastruttura Firebase.",
          ),
          p(
            "Il Titolare adotta misure proporzionate alla natura dei dati trattati, tenendo conto dei rischi connessi al trattamento, in conformità all'art. 32 GDPR.",
          ),
          divider(),

          h1("13. Modifiche alla presente Privacy Policy"),
          p(
            "Il Titolare si riserva il diritto di modificare o aggiornare la presente Privacy Policy per adeguarla a:",
          ),
          bullet("modifiche normative;"),
          bullet("evoluzioni tecniche dell'applicazione;"),
          bullet(
            "variazioni delle modalità di trattamento dei dati personali.",
          ),
          p(
            "La versione aggiornata sarà resa disponibile all'interno dell'applicazione e/o attraverso gli eventuali canali ufficiali di G-Scanner, con indicazione della data di ultimo aggiornamento.",
          ),
          divider(),

          h1("14. Fornitori di Servizi e Trasferimento dei Dati"),
          p(
            "Per l'erogazione delle funzionalità offerte da G-Scanner, il Titolare si avvale di fornitori di servizi tecnologici che trattano dati personali esclusivamente nei limiti necessari all'esecuzione dei servizi richiesti.",
          ),
          divider(),

          h2("14.1 Infrastruttura Cloud (Google Firebase)"),
          p(
            "Per le funzionalità di autenticazione e archiviazione dei dati, G-Scanner utilizza la piattaforma **Google Firebase**, fornita da **Google Ireland Limited**, con sede in Gordon House, Barrow Street, Dublin 4, Irlanda.",
          ),
          p("In particolare, l'applicazione utilizza:"),
          bullet(
            "**Firebase Authentication**, per la gestione dell'autenticazione degli utenti;",
          ),
          bullet(
            "**Cloud Firestore**, per la memorizzazione e sincronizzazione dei dati degli utenti autenticati.",
          ),
          p(
            "Per i trattamenti effettuati per conto del Titolare nell'ambito dei servizi Firebase utilizzati dall'applicazione, **Google Ireland Limited opera quale Responsabile del Trattamento ai sensi dell'art. 28 GDPR**.",
          ),
          p(
            "Restano ferme le eventuali attività di trattamento per le quali Google agisce quale autonomo titolare secondo quanto previsto dalla documentazione privacy del servizio Firebase.",
          ),
          divider(),

          h2("14.2 Localizzazione dei dati e trasferimenti verso Paesi terzi"),
          p(
            "Il database **Cloud Firestore** utilizzato da G-Scanner è configurato nella regione:",
          ),
          p("**eur3 – Francoforte (Germania)**"),
          p(
            "corrispondente a infrastrutture localizzate all'interno dell'Unione Europea.",
          ),
          p(
            "Il Titolare adotta tale configurazione con l'obiettivo di favorire la conservazione dei dati personali all'interno dello Spazio Economico Europeo (SEE).",
          ),
          p(
            "Qualora Google dovesse effettuare trasferimenti tecnici di dati personali verso Paesi situati al di fuori dello Spazio Economico Europeo, tali trasferimenti saranno effettuati nel rispetto degli articoli 44 e seguenti del GDPR e garantiti mediante strumenti legalmente riconosciuti, tra cui:",
          ),
          bullet("il **Data Privacy Framework UE-USA**, ove applicabile;"),
          bullet(
            "le **Clausole Contrattuali Tipo (Standard Contractual Clauses – SCC)** approvate dalla Commissione Europea.",
          ),
          divider(),

          h2(
            "14.3 Servizi di autenticazione tramite provider esterni (Social Login)",
          ),
          p("L'utente può scegliere di autenticarsi tramite:"),
          bullet("Google;"),
          bullet("Facebook."),
          p("Durante la procedura di autenticazione:"),
          bullet("**Google Ireland Limited**;"),
          bullet("**Meta Platforms Ireland Limited**"),
          p(
            "agiscono in qualità di **Titolari Autonomi del Trattamento**, limitatamente alle attività necessarie alla verifica delle credenziali, alla gestione dell'identità digitale e all'erogazione del servizio di autenticazione.",
          ),
          p(
            "G-Scanner riceve esclusivamente i dati necessari alla creazione e gestione dell'account, che possono comprendere:",
          ),
          bullet("nome;"),
          bullet("cognome;"),
          bullet("indirizzo e-mail;"),
          bullet("eventuale numero di telefono disponibile."),
          p(
            "Per ogni ulteriore trattamento effettuato direttamente dai provider esterni si rinvia alle rispettive informative privacy ufficiali:",
          ),
          bullet("Google Privacy Policy;"),
          bullet("Meta Privacy Policy."),
          p(
            "Il Titolare non è responsabile dei trattamenti effettuati autonomamente da tali provider per finalità proprie.",
          ),
          divider(),

          h1("15. Assenza di decisioni automatizzate (Art. 22 GDPR)"),
          p(
            "G-Scanner utilizza filtri e criteri informativi configurati dall'applicazione per fornire indicazioni relative ai prodotti alimentari.",
          ),
          p(
            "Le classificazioni generate dall'applicazione, quali ad esempio **\"Vietato\"**, **\"Consentito\"**, **\"Attenzione\"** o indicazioni equivalenti, costituiscono esclusivamente informazioni di supporto basate sui dati disponibili e sulle impostazioni selezionate dall'utente.",
          ),
          p(
            "**L'applicazione non effettua processi decisionali automatizzati aventi effetti giuridici o analogamente significativi sull'utente ai sensi dell'art. 22 GDPR.**",
          ),
          divider(),

          h1("16. Lingua delle Informative e dei Termini"),
          p(
            "La presente Privacy Policy, nonché i Termini e Condizioni d'Uso e gli eventuali ulteriori documenti legali relativi all'Applicazione, sono redatti originariamente in **lingua italiana**. Eventuali traduzioni in altre lingue sono fornite esclusivamente a fini di cortesia e per agevolare la comprensione da parte dell'Utente. In caso di discrepanze, incongruenze o difformità interpretative tra la versione in lingua italiana e qualsiasi versione tradotta, prevarrà la versione in lingua italiana, nei limiti massimi consentiti dalla normativa applicabile.",
          ),
          divider(),

          h1("Contatti del Titolare del Trattamento"),
          p("**Emanuele Ciotola**"),
          p("**Email:**\n**supporto-gscanner@googlegroups.com**"),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
