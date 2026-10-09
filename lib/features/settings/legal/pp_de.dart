// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

const String ppDe = r'''
# Datenschutzerklärung von G-Scanner

**Version:** 1.0

**Datum des Inkrafttretens:** 9. Oktober 2026

**Letzte Aktualisierung:** 9. Oktober 2026

---

Diese Datenschutzerklärung beschreibt die Modalitäten der Verarbeitung personenbezogener Daten, die über die mobile und webbasierte Anwendung **G-Scanner** erfolgt, entwickelt in Übereinstimmung mit der **Verordnung (EU) 2016/679 (DSGVO)** sowie dem anwendbaren italienischen Datenschutzrecht.

---

## Zweck der Anwendung

G-Scanner ist eine Anwendung, die es den Nutzern ermöglicht, durch Scannen von Barcodes Informationen über Lebensmittel abzurufen, mit besonderem Augenmerk auf die Bedürfnisse von Personen, die an Zöliakie oder Laktoseintoleranz leiden.

Die Anwendung ermöglicht es den Nutzern zudem, spezifische Ernährungspräferenzen zu konfigurieren, Hinweise basierend auf voreingestellten Informationsfiltern zu erhalten und durch das Teilen von Produktmeldungen an einer Community teilzunehmen.

**Wichtig – Haftungsbeschränkung**

Die von G-Scanner bereitgestellten Informationen dienen ausschließlich informativen Zwecken und zur Unterstützung des Nutzers.

Die Anwendung **stellt kein Medizinprodukt dar**, **bietet keine medizinische Beratung**, **hat keinen diagnostischen oder therapeutischen Wert** und **erzeugt keine rechtlich bindenden Wirkungen oder Bewertungen**.

Die angezeigten Informationen ersetzen in keinem Fall:

* den Rat eines Arztes oder einer anderen qualifizierten medizinischen Fachkraft;

* die Konsultation der offiziellen Lebensmitteletiketten;

* die direkt vom Hersteller bereitgestellten Informationen.

Die von der Anwendung generierten Bewertungen basieren ausschließlich auf den in der Datenbank verfügbaren Daten und den vom Nutzer konfigurierten Einstellungen und spiegeln möglicherweise keine Änderungen in der Produktzusammensetzung, Rezepturaktualisierungen durch die Hersteller oder nicht verfügbare Informationen wider.

Der Nutzer ist stets verpflichtet, die Zusammensetzung und Kennzeichnung der Produkte vor dem Verzehr selbstständig zu überprüfen.

---

## 1. Verantwortlicher

Der Verantwortliche für die Verarbeitung der personenbezogenen Daten ist:

**Emanuele Ciotola**

E-Mail:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

Für jegliche Anfragen bezüglich der Verarbeitung personenbezogener Daten oder zur Ausübung der durch die DSGVO gewährten Rechte kann der Verantwortliche unter der oben genannten Adresse kontaktiert werden.

---

## 2. Arten der verarbeiteten Daten

Die Anwendung verarbeitet ausschließlich die Daten, die für ihren Betrieb und die Bereitstellung der angebotenen Funktionen erforderlich sind.

### 2.1 Anonyme Nutzer

Wird G-Scanner genutzt, ohne dass eine Anmeldung (Login) erfolgt, verbleiben die personenbezogenen Daten und die konfigurierten Präferenzen des Nutzers ausschließlich auf dem Gerät und werden lokal mittels **SharedPreferences** gespeichert.

Dazu gehören:

* der Scan-Verlauf;

* die Einstellungen der Anwendung;

* die Präferenzen bezüglich der vom Nutzer ausgewählten ernährungs- und gesundheitsspezifischen Funktionen.

Diese personenbezogenen Daten **werden nicht an die Server des Verantwortlichen übermittelt**.

Es versteht sich jedoch, dass **Meldungen (Reports) zu Produkten**, sofern sie über die Anwendung gesendet werden, in der Cloud-Datenbank der Anwendung gespeichert und den anderen Nutzern der Community zur Verfügung gestellt werden, um den Dienst zu verbessern.

Die in der Community veröffentlichten Meldungen dürfen ausschließlich Folgendes enthalten:

* Informationen zu dem gemeldeten Lebensmittel oder Produkt;

* etwaige vom Nutzer eingegebene Notizen;

* den Grund für die Meldung.

Die Identität des Nutzers, der die Meldung erstattet, einschließlich **Vorname, Nachname, E-Mail-Adresse oder andere Identifikationsdaten**, **wird niemals veröffentlicht oder unter keinen Umständen sichtbar mit der Meldung verknüpft**.

Auch die von anderen Nutzern erstellten Meldungen können von den Nutzern der Anwendung eingesehen werden, unabhängig davon, ob sie authentifiziert sind oder nicht.

### 2.2 Authentifizierte Nutzer

Der Nutzer kann sich über **Firebase Authentication** authentifizieren, unter Verwendung eines Kontos von:

* Google;

* Facebook.

Im Zuge der Authentifizierung werden die zur Identifizierung des Nutzers erforderlichen Daten vom Provider abgerufen, die Folgendes umfassen können:

* Vorname;

* Nachname;

* E-Mail-Adresse;

* Telefonnummer, sofern verfügbar oder mit dem für die Authentifizierung verwendeten Profil verknüpft.

Diesen Informationen wird eine eindeutige Benutzerkennung (**User ID**) zugeordnet.

G-Scanner hat keinen Zugriff auf die Authentifizierungsdaten des Nutzers, wie Passwörter oder gleichwertige Mittel, und verarbeitet diese Informationen nicht.

### 2.3 In der Cloud-Datenbank gespeicherte Daten

Für authentifizierte Nutzer werden die folgenden Daten, verknüpft mit der Benutzerkennung, auf **Firebase Firestore** gespeichert:

* Scan-Verlauf;

* Liste der gesendeten Meldungen;

* Einstellungen bezüglich der Ernährungspräferenzen:

Zusatzstoff-Warnung;

* Strikter Kontaminationsfilter;

* Laktoseintoleranz;

* etwaige Einstellungen zu Kontaminationswarnungen;

* ausgewählte Sprache;

* gewähltes grafisches Design (Theme).

Die durch die Authentifizierung erhaltenen Identifikationsdaten (Vorname, Nachname, E-Mail-Adresse und gegebenenfalls verfügbare Telefonnummer) werden ausschließlich für folgende Zwecke verwendet:

* um die Kontoverwaltung zu ermöglichen;

* um die Daten des Nutzers korrekt seinem Profil zuzuordnen;

* um die Funktionen bereitzustellen, die authentifizierten Nutzern vorbehalten sind.

### 2.4 Cookies und lokale Speichertechnologien

G-Scanner verwendet (sowohl in der Web-App-Version als auch als mobile Anwendung) keine Profiling-Cookies, Werbe-Tracking-Tools oder Analysesysteme von Drittanbietern.

Die Anwendung verwendet ausschließlich unbedingt erforderliche lokale Speichertechnologien (wie SharedPreferences auf Mobilgeräten und LocalStorage / Technische Cookies in Browsern), und zwar ausschließlich zu folgenden Zwecken:

* Sichere Aufrechterhaltung der aktiven Benutzersitzung über Firebase Authentication;

* Lokale Speicherung der Nutzerpräferenzen (z. B. Sprache, grafisches Design) sowie der Bestätigung der Annahme rechtlicher Dokumente.

Da es sich hierbei ausschließlich um technische Instrumente handelt, die für die Bereitstellung des vom Nutzer angeforderten Dienstes zwingend erforderlich sind, ist gemäß den europäischen Vorschriften (ePrivacy-Richtlinie) und den Beschlüssen der italienischen Datenschutzbehörde keine vorherige Einwilligung des Nutzers für deren Verwendung erforderlich. Der Nutzer wird durch diese Datenschutzerklärung über deren Vorhandensein informiert, ohne dass Banner oder separate Dokumente erforderlich sind.

Die lokal gespeicherten Daten verbleiben auf dem Gerät des Nutzers, bis sie gelöscht werden oder die Anwendung deinstalliert wird.

### 2.5 Lokale Datenbank für die Offline-Nutzung

G-Scanner kann es dem Nutzer ermöglichen, eine lokale Kopie von Daten zu Lebensmitteln auf sein Gerät herunterzuladen, um das Einsehen und Scannen von Produkten auch ohne Internetverbindung zu ermöglichen.

Die Offline-Datenbank enthält ausschließlich Lebensmittelinformationen, die für den Betrieb der Offline-Funktionen erforderlich sind, und enthält keine personenbezogenen Daten des Nutzers.

Der Nutzer kann zwischen verschiedenen Konfigurationen der Offline-Datenbank wählen, die sich durch einen unterschiedlichen Abdeckungsgrad und eine dementsprechend unterschiedliche Menge an auf dem Gerät gespeicherten Daten auszeichnen.

Die in der Offline-Datenbank enthaltenen Daten stellen eine lokale Kopie der zum Zeitpunkt der jeweiligen Aktualisierung verfügbaren Daten dar und spiegeln daher spätere Änderungen oder Aktualisierungen der Produktinformationen möglicherweise nicht wider.

Über die Offline-Datenbank abgerufene Daten werden nicht automatisch mit dem persönlichen Profil des Nutzers verknüpft oder zur Erstellung oder Aktualisierung seines Profils verwendet.

Die Offline-Datenbank kann vom Nutzer über die von der Anwendung bereitgestellten Funktionen aktualisiert oder gelöscht werden.

---

## 3. Besondere Kategorien personenbezogener Daten (Art. 9 DSGVO)

G-Scanner ermöglicht es dem Nutzer, spezifische persönliche Präferenzen für das Abrufen von Informationen über Lebensmittel zu konfigurieren. Diese Einstellungen können den Gesundheitszustand oder besondere Ernährungsbedürfnisse des Nutzers widerspiegeln und stellen somit unter Umständen **besondere Kategorien personenbezogener Daten** im Sinne von **Art. 9 der Verordnung (EU) 2016/679 (DSGVO)** dar.

Die in der Anwendung verfügbaren Einstellungen sind die folgenden:

* **Zusatzstoff-Warnung**: Erzeugt eine Warnung beim Vorhandensein von Zutaten wie modifizierten Stärken oder Aromen, deren Herkunft nicht spezifiziert ist, damit der Nutzer weitere Überprüfungen vornehmen kann.

* **Strikter Kontaminationsfilter**: Stuft jedes Lebensmittel als **"Verboten"** ein, dessen Etikett Angaben wie **"kann Spuren von Gluten enthalten"** oder gleichwertige Formulierungen bezüglich einer möglichen Kontamination mit Gluten aufweist.

* **Laktoseintoleranz**: Überprüft das Vorhandensein von Zutaten wie Laktose, Butter, Milchpulver oder Molke und meldet deren potenzielles Vorhandensein entsprechend den Funktionen der Anwendung.

Beim **ersten Start der Anwendung** sind standardmäßig ausschließlich die folgenden Optionen aktiviert:

* Zusatzstoff-Warnung;

* Strikter Kontaminationsfilter.

Die Option **Laktoseintoleranz** ist zunächst deaktiviert und kann vom Nutzer jederzeit aktiviert werden.

Die Verarbeitung dieser Informationen erfolgt **ausschließlich nach vorheriger ausdrücklicher Einwilligung des Nutzers** gemäß **Art. 9 Abs. 2 lit. a DSGVO**.

Es steht dem Nutzer frei, die oben genannten Einstellungen jederzeit entsprechend seinen persönlichen Bedürfnissen zu ändern, zu aktivieren oder zu deaktivieren.

Diese Entscheidungen werden in der Verantwortung des Nutzers getroffen, der anerkennt, dass G-Scanner ausschließlich ein **informatives Hilfsmittel** darstellt und Folgendes nicht ersetzt:

* die Überprüfung der Produktetiketten;

* die vom Hersteller bereitgestellten Informationen;

* den Rat eines Arztes oder einer anderen qualifizierten medizinischen Fachkraft.

Jegliche Änderung der Einstellungen und die Nutzung der von der Anwendung bereitgestellten Informationen erfolgen daher **auf alleiniges Risiko des Nutzers**.

Der Nutzer kann seine Präferenzen jederzeit ändern oder die zuvor erteilte Einwilligung widerrufen, ohne dass die Rechtmäßigkeit der aufgrund der Einwilligung bis zum Widerruf erfolgten Verarbeitung berührt wird.

---

## 4. Zwecke der Verarbeitung

Die über G-Scanner erhobenen personenbezogenen Daten werden für die folgenden Zwecke verarbeitet:

* um das Scannen von Barcodes und das Abrufen von Informationen zu Lebensmitteln zu ermöglichen;

* das Abrufen von Informationen zu Produkten auch ohne Internetverbindung über eine etwaige vom Nutzer heruntergeladene lokale Datenbank zu ermöglichen;

* um die Personalisierung der Nutzererfahrung durch die Konfiguration von Ernährungspräferenzen und Anwendungseinstellungen zu ermöglichen;

* um authentifizierten Nutzern die Datensynchronisation zwischen verschiedenen Geräten zu ermöglichen;

* um die Teilnahme an der Community durch das Senden, Verwalten und Einsehen von Produktmeldungen zu ermöglichen;

* um die Authentifizierung über externe Provider wie Google und Facebook zu verwalten;

* um den korrekten technischen Betrieb der Anwendung, die Sicherheit der Dienste und den Schutz der verarbeiteten Daten zu gewährleisten.

---

## 5. Rechtsgrundlage der Verarbeitung

Die Verarbeitung der personenbezogenen Daten basiert auf:

* der ausdrücklichen Einwilligung der betroffenen Person für die Verarbeitung **besonderer Kategorien personenbezogener Daten** im Zusammenhang mit der Gesundheit (Art. 9 Abs. 2 lit. a DSGVO);

* der Erfüllung des vom Nutzer angeforderten Dienstes und der von der Anwendung angebotenen Funktionen;

* der Erfüllung rechtlicher Verpflichtungen, die nach geltendem Recht vorgesehen sind;

* dem berechtigten Interesse des Verantwortlichen hinsichtlich der technischen Sicherheit der Anwendung und der Verhinderung einer missbräuchlichen Nutzung des Dienstes, soweit anwendbar.

---

## 6. Minderjährige

Die Nutzung von G-Scanner ist für Personen unter **14 Jahren** untersagt.

In Übereinstimmung mit dem italienischen Gesetz zur digitalen Einwilligung richtet sich die Anwendung nicht an Nutzer unter 14 Jahren und erhebt nicht wissentlich personenbezogene Daten von solchen Personen.

Sollte der Verantwortliche Kenntnis davon erlangen, dass Daten von Personen unter 14 Jahren vorhanden sind, wird er diese umgehend löschen.

---

## 7. Zugriff auf Gerätefunktionen und -informationen

Um das ordnungsgemäße Funktionieren der angebotenen Funktionen zu gewährleisten, kann G-Scanner auf bestimmte Funktionen und Informationen des Geräts des Nutzers zugreifen.

### Kamera

Die Kamera wird ausschließlich verwendet, um das Scannen der Produkt-Barcodes zu ermöglichen.

Die über die Kamera erfassten Bilder werden nicht gespeichert, übertragen oder für andere Zwecke als das Barcode-Scannen verwendet.

### Internetverbindung

Die Anwendung überprüft, sofern erforderlich, die Verfügbarkeit der Internetverbindung, um festzustellen, ob Funktionen genutzt werden können, die den Zugriff auf Online-Dienste erfordern.

Die Internetverbindung ist insbesondere erforderlich, um:

* die Authentifizierung über die unterstützten Provider durchzuführen;

* die Daten der authentifizierten Nutzer zu synchronisieren;

* auf die von der Anwendung genutzten Cloud-Dienste zuzugreifen;

* Produktinformationen über Online-Dienste abzurufen und zu aktualisieren;

* die Funktionen zu ermöglichen, die auf den Community-Daten basieren.

Der Verbindungsstatus wird ausschließlich für die technische Verwaltung der Anwendungsfunktionen verwendet und weder erfasst noch gespeichert oder für Profiling- bzw. Tracking-Zwecke genutzt.

### System-Design (Theme)

Die Berechtigung bezüglich des System-Designs wird ausschließlich verwendet, um die grafische Benutzeroberfläche der Anwendung automatisch an den auf dem Gerät des Nutzers konfigurierten hellen oder dunklen Modus (Light/Dark Mode) anzupassen.

### Gerätesprache und Sprache der Benutzeroberfläche

Beim ersten Start kann die Anwendung die auf dem Gerät konfigurierte Sprache auslesen, um die Sprache der Benutzeroberfläche der Anwendung automatisch festzulegen.

Die so ermittelte Sprache wird zur Konfiguration der Benutzeroberfläche der Anwendung verwendet und kann bei authentifizierten Nutzern in der mit dem Konto verknüpften Datenbank gespeichert werden, um die Präferenz beizubehalten und über verschiedene Geräte hinweg zu synchronisieren.

Die Sprache der Benutzeroberfläche wird nicht für Profiling-, Tracking- oder Werbezwecke verwendet.

---

## 8. Keine Werbung, kein Tracking und keine Erfassung von Analysedaten

G-Scanner wendet eine Richtlinie zum Schutz der Privatsphäre der Nutzer an.

Die Anwendung:

* ist völlig kostenlos;

* enthält keine Werbung;

* verwendet keine Analysetools;

* verwendet kein Google Analytics;

* verwendet kein Firebase Crashlytics;

* führt kein Nutzer-Profiling durch;

* führt keine Nutzer-Tracking-Aktivitäten durch;

* verkauft keine personenbezogenen Daten;

* übermittelt oder überträgt keine personenbezogenen Daten an Dritte für kommerzielle Zwecke.

Insbesondere erfasst **G-Scanner keine Werbekennungen, Informationen zur Anwendungsnutzung, Diagnosedaten oder technische Gerätedaten für Analyse- oder Profilingzwecke**.

Die Anwendung führt keine Prozesse zur Verhaltensüberwachung des Nutzers durch und erstellt keine kommerziellen oder werblichen Profile.

---

## 9. Speicherdauer

### 9.1 Anonyme Nutzer

Wenn der Nutzer G-Scanner ohne Authentifizierung nutzt, verbleiben die personenbezogenen Daten und die konfigurierten Präferenzen ausschließlich lokal auf dem Gerät und werden über **SharedPreferences** gespeichert.

Diese Daten werden gespeichert, bis:

* der Nutzer sie über die in der Anwendung verfügbaren Funktionen löscht;

* die Anwendung deinstalliert wird;

* das Gerät zurückgesetzt wird oder die lokalen Daten gelöscht werden.

Produktmeldungen, die an die Community gesendet werden, stellen eine separate Verarbeitung dar und werden stattdessen in der Cloud-Datenbank der Anwendung gespeichert, um anderen Nutzern die Einsichtnahme zu ermöglichen.

### 9.2 Lokale Datenbank für die Offline-Nutzung

Die in der Offline-Datenbank enthaltenen Produktdaten werden lokal auf dem Gerät gespeichert, bis der Nutzer:

* die Datenbank über die in der Anwendung verfügbaren Funktionen löscht;

* die Datenbank durch eine andere Konfiguration ersetzt;

* die Anwendung deinstalliert;

* die entsprechenden lokalen Daten löscht, sofern dies vom Betriebssystem vorgesehen ist.

Die Offline-Datenbank kann regelmäßig aktualisiert werden. Die auf dem Gerät verfügbare Version stimmt daher möglicherweise nicht mit der aktuellsten Version der online verfügbaren Daten überein.

### 9.3 Authentifizierte Nutzer

Für authentifizierte Nutzer werden die Daten mithilfe einer **dualen Speichermethode** aufbewahrt:

* lokal auf dem Gerät des Nutzers, um eine schnelle Nutzung der Anwendung zu ermöglichen;

* in der Cloud-Datenbank Firebase Firestore, um die Datensynchronisation zwischen verschiedenen Geräten sowie die Aufrechterhaltung der mit dem Konto verbundenen Funktionen zu ermöglichen.

Die mit dem Konto verknüpften Daten bleiben gespeichert, bis sie gemäß den im folgenden Abschnitt zur Datenlöschung beschriebenen Verfahren entfernt werden.

---

## 10. Recht auf Löschung und Kontoverwaltung (Art. 17 DSGVO)

Der Nutzer verfügt über zwei verschiedene Methoden zur Verwaltung der Löschung seiner Daten.

### 10.1 Kontolöschung über die interne Funktion der Anwendung

Wenn der Nutzer die entsprechende interne Funktion zur Kontolöschung verwendet, die in G-Scanner verfügbar ist, wird das zugehörige **Firebase Authentication-Profil** gelöscht.

Dieser Vorgang führt zu:

* der dauerhaften Entfernung der Verknüpfung zwischen dem Konto und den für die Authentifizierung verwendeten Identifikationsdaten;

* der Löschung von Verweisen auf E-Mail, Vorname, Nachname und etwaige Providerdaten, die mit dem Profil verbunden sind.

Jedoch führt die Löschung des Authentifizierungsprofils **nicht automatisch zur sofortigen physischen Vernichtung der in Firebase Firestore vorhandenen Dokumente**.

Eventuell in der Cloud-Datenbank vorhandene Daten, wie z.B.:

* Scan-Verlauf;

* Einstellungen der Anwendung;

* mit der Benutzerkennung verknüpfte Daten;

können der Identität des Nutzers nicht mehr zugeordnet werden und werden durch die normale Nutzung der Anwendung technisch unzugänglich.

Die Verbindung zwischen diesen Daten und der Identität des Nutzers wird dauerhaft gelöscht.

### 10.2 Vollständige und endgültige Löschung der Daten (Data Wipe)

Sollte der Nutzer die vollständige und endgültige physische Löschung aller Datensätze verlangen, die seiner Kennung in den Cloud-Systemen zugeordnet sind, muss er eine ausdrückliche Anfrage an den Verantwortlichen richten über:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

Die Anfrage muss **vor der Löschung des Profils über die Anwendung** erfolgen, und zwar unter Verwendung derselben E-Mail-Adresse, die mit dem für den Zugang genutzten Konto verknüpft ist.

Dieses Verfahren ist notwendig, damit der Verantwortliche die Identität des Antragstellers überprüfen und die mit dem Konto verknüpften Datensätze korrekt auffinden kann.

Sollte der Nutzer sein Profil zuvor aus der Anwendung löschen, ohne den Antrag auf vollständige Löschung gestellt zu haben, ist es möglicherweise nicht mehr möglich, die Identität des Antragstellers zu überprüfen und die zuvor mit dem gelöschten Konto verknüpften Daten zu finden.

Nach erfolgreicher Überprüfung der Identität wird der Verantwortliche die endgültige Löschung der in den Cloud-Systemen gespeicherten Daten, die mit der Benutzerkennung verknüpft sind, im Rahmen der technischen Möglichkeiten und der anwendbaren rechtlichen Vorgaben vornehmen.

---

## 11. Rechte der betroffenen Person

Gemäß den Artikeln 15 ff. DSGVO kann die betroffene Person das Recht ausüben auf:

* Bestätigung darüber, ob sie betreffende personenbezogene Daten verarbeitet werden;

* Auskunft über die verarbeiteten personenbezogenen Daten;

* Berichtigung unrichtiger Daten;

* Löschung der Daten in den gesetzlich vorgesehenen Fällen;

* Einschränkung der Verarbeitung;

* Widerspruch gegen die Verarbeitung in den zulässigen Fällen;

* Widerruf der zuvor erteilten Einwilligung, ohne dass die Rechtmäßigkeit der aufgrund der Einwilligung bis zum Widerruf erfolgten Verarbeitung berührt wird;

* Erhalt ihrer Daten in einem strukturierten Format, sofern anwendbar (Datenübertragbarkeit);

* Einreichung einer Beschwerde bei der zuständigen Datenschutzaufsichtsbehörde.

Zur Ausübung ihrer Rechte kann die betroffene Person den Verantwortlichen kontaktieren unter:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

---

## 12. Datensicherheit

Personenbezogene Daten werden mittels IT-Tools und geeigneter technischer und organisatorischer Maßnahmen verarbeitet, um Folgendes zu gewährleisten:

* Vertraulichkeit;

* Integrität;

* Verfügbarkeit;

* Schutz vor unbefugtem Zugriff.

Insbesondere ist für die über die Firebase-Infrastruktur gespeicherten Daten der Zugriff auf die Cloud-Daten ausschließlich auf autorisierte Personen beschränkt und wird durch die von der Firebase-Infrastruktur bereitgestellten technischen und Sicherheitsmaßnahmen geschützt.

Der Verantwortliche ergreift Maßnahmen, die in einem angemessenen Verhältnis zur Art der verarbeiteten Daten stehen, wobei die mit der Verarbeitung verbundenen Risiken gemäß Art. 32 DSGVO berücksichtigt werden.

---

## 13. Änderungen dieser Datenschutzerklärung

Der Verantwortliche behält sich das Recht vor, diese Datenschutzerklärung zu ändern oder zu aktualisieren, um sie anzupassen an:

* gesetzliche Änderungen;

* technische Weiterentwicklungen der Anwendung;

* Änderungen der Modalitäten bei der Verarbeitung personenbezogener Daten.

Die aktualisierte Version wird innerhalb der Anwendung und/oder über etwaige offizielle Kanäle von G-Scanner unter Angabe des Datums der letzten Aktualisierung zur Verfügung gestellt.

---

## 14. Dienstleister und Datenübermittlung

Zur Bereitstellung der von G-Scanner angebotenen Funktionen bedient sich der Verantwortliche technologischer Dienstleister, die personenbezogene Daten ausschließlich im Rahmen des für die Durchführung der angeforderten Dienste erforderlichen Umfangs verarbeiten.

### 14.1 Cloud-Infrastruktur (Google Firebase)

Für Authentifizierungs- und Datenspeicherungsfunktionen verwendet G-Scanner die Plattform **Google Firebase**, bereitgestellt von **Google Ireland Limited**, mit Sitz in Gordon House, Barrow Street, Dublin 4, Irland.

Die Anwendung nutzt insbesondere:

* **Firebase Authentication**, zur Verwaltung der Nutzerauthentifizierung;

* **Cloud Firestore**, zur Speicherung und Synchronisierung der Daten der authentifizierten Nutzer.

Für die Verarbeitungen, die im Auftrag des Verantwortlichen im Rahmen der von der Anwendung genutzten Firebase-Dienste durchgeführt werden, agiert **Google Ireland Limited als Auftragsverarbeiter gemäß Art. 28 DSGVO**.

Unberührt bleiben etwaige Verarbeitungstätigkeiten, für die Google gemäß den Angaben in der Datenschutzdokumentation des Firebase-Dienstes als unabhängiger Verantwortlicher handelt.

### 14.2 Datenlokalisierung und Übermittlung in Drittländer

Die von G-Scanner genutzte **Cloud Firestore**-Datenbank ist in folgender Region konfiguriert:

**eur3 – Frankfurt (Deutschland)**

was Infrastrukturen entspricht, die sich innerhalb der Europäischen Union befinden.

Der Verantwortliche wählt diese Konfiguration mit dem Ziel, die Speicherung personenbezogener Daten innerhalb des Europäischen Wirtschaftsraums (EWR) zu fördern.

Sollte Google technische Übermittlungen personenbezogener Daten in Länder außerhalb des Europäischen Wirtschaftsraums durchführen, erfolgen diese Übermittlungen in Übereinstimmung mit den Artikeln 44 ff. DSGVO und werden durch gesetzlich anerkannte Instrumente abgesichert, darunter:

* das **EU-US Data Privacy Framework**, soweit anwendbar;

* die von der Europäischen Kommission genehmigten **Standardvertragsklauseln (Standard Contractual Clauses – SCC)**.

### 14.3 Authentifizierungsdienste über externe Anbieter (Social Login)

Der Nutzer kann sich authentifizieren über:

* Google;

* Facebook.

Während des Authentifizierungsvorgangs agieren:

* **Google Ireland Limited**;

* **Meta Platforms Ireland Limited**

als **unabhängige Verantwortliche**, beschränkt auf die Aktivitäten, die zur Überprüfung der Anmeldedaten, zur Verwaltung der digitalen Identität und zur Bereitstellung des Authentifizierungsdienstes erforderlich sind.

G-Scanner erhält ausschließlich die Daten, die für die Erstellung und Verwaltung des Kontos erforderlich sind, diese können umfassen:

* Vorname;

* Nachname;

* E-Mail-Adresse;

* gegebenenfalls verfügbare Telefonnummer.

Für jede weitere Verarbeitung, die direkt durch die externen Anbieter erfolgt, wird auf die jeweiligen offiziellen Datenschutzerklärungen verwiesen:

* Google Datenschutzerklärung;

* Meta Datenschutzerklärung.

Der Verantwortliche haftet nicht für Verarbeitungen, die von diesen Anbietern eigenverantwortlich für eigene Zwecke durchgeführt werden.

---

## 15. Keine automatisierte Entscheidungsfindung (Art. 22 DSGVO)

G-Scanner verwendet Filter und Informationskriterien, die von der Anwendung konfiguriert werden, um Hinweise zu Lebensmitteln zu geben.

Die von der Anwendung generierten Klassifizierungen, wie beispielsweise **"Verboten"**, **"Erlaubt"**, **"Achtung"** oder gleichwertige Angaben, stellen ausschließlich Unterstützungsinformationen dar, die auf den verfügbaren Daten und den vom Nutzer ausgewählten Einstellungen basieren.

**Die Anwendung führt keine automatisierte Entscheidungsfindung durch, die rechtliche Wirkungen für den Nutzer entfaltet oder ihn in ähnlicher Weise erheblich beeinträchtigt (gemäß Art. 22 DSGVO).**

---

## 16. Sprache der Richtlinien und Bedingungen

Diese Datenschutzerklärung sowie die Nutzungsbedingungen und alle weiteren rechtlichen Dokumente im Zusammenhang mit der Anwendung wurden ursprünglich in italienischer Sprache verfasst. Etwaige Übersetzungen in andere Sprachen werden ausschließlich aus Höflichkeit und zum besseren Verständnis für den Nutzer bereitgestellt. Im Falle von Unstimmigkeiten, Widersprüchen oder Auslegungsunterschieden zwischen der italienischen Fassung und einer übersetzten Fassung hat die italienische Fassung im größtmöglichen gesetzlich zulässigen Umfang strikten Vorrang.

---

## Kontakt des Verantwortlichen

**Emanuele Ciotola**

E-Mail:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**
''';
