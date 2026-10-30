# Sync Date Tester Tool

Strumento di utilità per modificare **a runtime o a freddo** le date di sincronizzazione salvate nelle `SharedPreferences` dell'applicazione Android tramite **ADB (Android Debug Bridge)**.

---

## 🎯 Scopo

Consente di simulare date di sincronizzazione passate per verificare istantaneamente il comportamento dell'interfaccia utente di G-Scanner senza dover attendere giorni reali o manipolare manualmente l'orologio di sistema del dispositivo:

- **`-10 giorni` (Soft Stale)**: verifica la comparsa della **pillola gialla** *"Aggiornamento consigliato"* sulla card del Database Offline e all'interno del modal.
- **`-40 giorni` (Hard Stale)**: verifica la comparsa della **pillola rossa** *"Obsoleto (>30 gg)"*.
- **`now` (Sincronizzato)**: ripristina la data a oggi per verificare la scomparsa delle pillole di avviso.
- **`null` (Mai sincronizzato)**: resetta il campo per verificare lo stato di primo avvio.
- **Sync Generale (`celiac_app_last_sync_time`)**: testa le query di delta sync per i prodotti modificati su Firestore.

---

## 🛠️ Prerequisiti

1. **ADB (Android Debug Bridge)** installato e accessibile da terminale (incluso nell'Android SDK / Platform Tools).
2. Un dispositivo Android fisico o un emulatore collegato con il **Debug USB** abilitato (`adb devices`).
3. L'app G-Scanner installata in modalità debug sul dispositivo (`it.emanueleciotola.gscanner`).
4. **Python 3.x** oppure **PowerShell** (Windows).

---

## 📂 File inclusi

| File | Descrizione |
| :--- | :--- |
| `sync_date_tester.py` | Script Python multipiattaforma (Linux, macOS, Windows). |
| `sync_date_tester.ps1` | Script nativo PowerShell per Windows (senza dipendenze esterne). |
| `sync_date_tester.bat` | Launcher batch per Windows CMD o doppio click. |

---

## 🚀 Utilizzo

### 1. Menu Interattivo da Terminale
Lanciare lo script senza argomenti per aprire il menu con selezione numerata:

```bash
# Con Python:
python tools/sync_date_tester/sync_date_tester.py

# Con PowerShell (Windows):
.\tools\sync_date_tester\sync_date_tester.ps1

# Da Prompt dei Comandi (CMD):
tools\sync_date_tester\sync_date_tester.bat
```

### 2. Comandi Rapidi da Riga di Comando (CLI)

#### Database Offline (`offlineDbLastSyncedAt`)
```bash
# Imposta a 10 giorni fa (Pillola Gialla)
python tools/sync_date_tester/sync_date_tester.py --offline-db -10
.\tools\sync_date_tester\sync_date_tester.ps1 -OfflineDb -10

# Imposta a 40 giorni fa (Pillola Rossa)
python tools/sync_date_tester/sync_date_tester.py --offline-db -40
.\tools\sync_date_tester\sync_date_tester.ps1 -OfflineDb -40

# Ripristina a oggi (Sincronizzato)
python tools/sync_date_tester/sync_date_tester.py --offline-db now

# Resetta a null (Mai sincronizzato)
python tools/sync_date_tester/sync_date_tester.py --offline-db null
```

#### Sync Generale SharedPreferences (`celiac_app_last_sync_time`)
```bash
# Imposta a 10 o 40 giorni fa
python tools/sync_date_tester/sync_date_tester.py --general -10
python tools/sync_date_tester/sync_date_tester.py --general -40
```

#### Entrambi Contemporaneamente
```bash
python tools/sync_date_tester/sync_date_tester.py --both -10
python tools/sync_date_tester/sync_date_tester.py --both -40
```

#### Visualizza Stato Attuale (Sola Lettura)
```bash
python tools/sync_date_tester/sync_date_tester.py --status
.\tools\sync_date_tester\sync_date_tester.ps1 -Status
```

---

## ⚙️ Dettagli Tecnici

1. **Lettura/Scrittura**: utilizza `run-as it.emanueleciotola.gscanner` per accedere in modo sicuro al file privato `/data/data/it.emanueleciotola.gscanner/shared_prefs/FlutterSharedPreferences.xml`.
2. **Ricarica a Runtime**: poiché Android tiene in cache in RAM le SharedPreferences durante l'esecuzione del processo, lo script esegue automaticamente un riavvio istantaneo dell'attività principale (`am force-stop` + `am start`), rendendo la modifica visibile a schermo in meno di un secondo. È possibile disattivare il riavvio passando il flag `--no-restart` / `-NoRestart`.
