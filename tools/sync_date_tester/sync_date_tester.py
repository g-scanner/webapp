#!/usr/bin/env python3
# Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
# PROJECT: G-Scanner — See LICENSE file in root for terms.

"""
G-Scanner Sync Date Tester (ADB Tool)

Permette di modificare a runtime o a freddo:
1. La data dell'ultimo sync del Database Offline (offlineDbLastSyncedAt in celiac_settings)
2. La data dell'ultimo sync generale (celiac_app_last_sync_time in SharedPreferences)

Valori rapidi supportati:
- -10 giorni (Soft Stale -> Pillola Gialla "Aggiornamento consigliato")
- -40 giorni (Hard Stale -> Pillola Rossa "Obsoleto (>30 gg)")
- now (Data attuale / Sincronizzato)
- null (Nessun sync precedente)
"""

import sys
import os
import re
import json
import time
import argparse
import tempfile
import subprocess
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta

PACKAGE_NAME = "it.emanueleciotola.gscanner"
SETTINGS_KEY = "flutter.celiac_settings"
LAST_SYNC_KEY = "flutter.celiac_app_last_sync_time"

# ANSI Colors
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"


def run_adb_cmd(args, device_serial=None, check=True):
    cmd = ["adb"]
    if device_serial:
        cmd.extend(["-s", device_serial])
    cmd.extend(args)
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Comando ADB fallito: {' '.join(cmd)}\n{res.stderr.strip()}")
    return res


def get_connected_devices():
    res = run_adb_cmd(["devices"])
    lines = res.stdout.strip().splitlines()
    devices = []
    for line in lines[1:]:
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "device":
            devices.append(parts[0])
    return devices


def read_shared_prefs_xml(device_serial=None):
    res = run_adb_cmd(
        ["shell", f"run-as {PACKAGE_NAME} cat shared_prefs/FlutterSharedPreferences.xml"],
        device_serial=device_serial,
    )
    return res.stdout


def write_shared_prefs_xml(xml_content, device_serial=None):
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".xml") as f:
        f.write(xml_content)
        temp_path = f.name

    try:
        run_adb_cmd(["push", temp_path, "/data/local/tmp/FlutterSharedPreferences.xml"], device_serial=device_serial)
        run_adb_cmd(
            ["shell", f"run-as {PACKAGE_NAME} cp /data/local/tmp/FlutterSharedPreferences.xml shared_prefs/FlutterSharedPreferences.xml"],
            device_serial=device_serial,
        )
        run_adb_cmd(["shell", "rm /data/local/tmp/FlutterSharedPreferences.xml"], device_serial=device_serial)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


def restart_app(device_serial=None):
    print(f"{CYAN}Riavvio dell'app {PACKAGE_NAME}...{RESET}")
    run_adb_cmd(["shell", f"am force-stop {PACKAGE_NAME}"], device_serial=device_serial)
    run_adb_cmd(["shell", f"am start -n {PACKAGE_NAME}/.MainActivity"], device_serial=device_serial)
    print(f"{GREEN}✓ App riavviata con successo.{RESET}")


def get_current_status(xml_content):
    root = ET.fromstring(xml_content)
    now_epoch = int(time.time())

    # 1. Offline DB
    offline_db_epoch = None
    offline_db_str = None
    for elem in root.findall("string"):
        if elem.get("name") == SETTINGS_KEY and elem.text:
            try:
                data = json.loads(elem.text)
                offline_db_epoch = data.get("offlineDbLastSyncedAt")
            except Exception:
                pass
            break

    if offline_db_epoch and offline_db_epoch > 0:
        dt = datetime.fromtimestamp(offline_db_epoch)
        diff_days = (now_epoch - offline_db_epoch) // 86400
        status_tag = ""
        if diff_days <= 7:
            status_tag = f"{GREEN}[Sincronizzato]{RESET}"
        elif diff_days <= 30:
            status_tag = f"{YELLOW}[Soft Stale -> Pillola Gialla]{RESET}"
        else:
            status_tag = f"{RED}[Hard Stale -> Pillola Rossa]{RESET}"
        offline_db_str = f"{dt.strftime('%d/%m/%Y %H:%M')} ({diff_days} giorni fa) {status_tag}"
    else:
        offline_db_str = f"{RED}Nessuna data / null [Hard Stale]{RESET}"

    # 2. General Sync
    general_sync_val = None
    for elem in root.findall("string"):
        if elem.get("name") == LAST_SYNC_KEY:
            general_sync_val = elem.text
            break

    if general_sync_val:
        try:
            dt = datetime.fromisoformat(general_sync_val.replace("Z", "+00:00"))
            diff_days = (datetime.now(timezone.utc) - dt).days
            general_sync_str = f"{general_sync_val} ({diff_days} giorni fa)"
        except Exception:
            general_sync_str = general_sync_val
    else:
        general_sync_str = f"{RED}Nessuna data / null{RESET}"

    return offline_db_str, general_sync_str


def update_sync_dates(xml_content, offline_db_days=None, general_sync_days=None, offline_db_null=False, general_sync_null=False):
    root = ET.fromstring(xml_content)
    now_epoch = int(time.time())

    # 1. Aggiorna offlineDbLastSyncedAt in flutter.celiac_settings
    if offline_db_null or offline_db_days is not None:
        settings_elem = None
        for elem in root.findall("string"):
            if elem.get("name") == SETTINGS_KEY:
                settings_elem = elem
                break

        if settings_elem is not None and settings_elem.text:
            try:
                data = json.loads(settings_elem.text)
                if offline_db_null:
                    data["offlineDbLastSyncedAt"] = None
                else:
                    data["offlineDbLastSyncedAt"] = now_epoch - (offline_db_days * 86400)
                settings_elem.text = json.dumps(data, separators=(",", ":"))
            except Exception as e:
                print(f"{RED}Errore nel parsing di {SETTINGS_KEY}: {e}{RESET}")

    # 2. Aggiorna flutter.celiac_app_last_sync_time
    if general_sync_null or general_sync_days is not None:
        general_elem = None
        for elem in root.findall("string"):
            if elem.get("name") == LAST_SYNC_KEY:
                general_elem = elem
                break

        if general_sync_null:
            if general_elem is not None:
                root.remove(general_elem)
        else:
            target_dt = datetime.now(timezone.utc) - timedelta(days=general_sync_days)
            target_iso = target_dt.isoformat()
            if general_elem is not None:
                general_elem.text = target_iso
            else:
                new_elem = ET.SubElement(root, "string")
                new_elem.set("name", LAST_SYNC_KEY)
                new_elem.text = target_iso

    # Serializza di nuovo l'XML
    xml_declaration = "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
    xml_body = ET.tostring(root, encoding="utf-8").decode("utf-8")
    return xml_declaration + xml_body


def print_status(xml_content):
    off_str, gen_str = get_current_status(xml_content)
    print(f"\n{BOLD}=== STATO ATTUALE SINCRONIZZAZIONE (DEVICE) ==={RESET}")
    print(f"• Database Offline ({BOLD}offlineDbLastSyncedAt{RESET}):")
    print(f"  └─ {off_str}")
    print(f"• Sync Generale ({BOLD}{LAST_SYNC_KEY}{RESET}):")
    print(f"  └─ {gen_str}")
    print("=" * 48)


def interactive_menu(device_serial):
    while True:
        try:
            xml_content = read_shared_prefs_xml(device_serial)
        except Exception as e:
            print(f"{RED}Errore di lettura shared_prefs: {e}{RESET}")
            return

        print_status(xml_content)

        print(f"\n{BOLD}Seleziona un'operazione:{RESET}")
        print(f" {CYAN}[1]{RESET} Database Offline: {YELLOW}-10 giorni{RESET} (Soft Stale -> Pillola Gialla)")
        print(f" {CYAN}[2]{RESET} Database Offline: {RED}-40 giorni{RESET} (Hard Stale -> Pillola Rossa)")
        print(f" {CYAN}[3]{RESET} Database Offline: {GREEN}Oggi (Now){RESET} (Sincronizzato)")
        print(f" {CYAN}[4]{RESET} Database Offline: {RED}Reset (null){RESET} (Mai sincronizzato)")
        print(" ───────────────────────────────────────────────")
        print(f" {CYAN}[5]{RESET} Sync Generale SharedPreferences: {YELLOW}-10 giorni{RESET}")
        print(f" {CYAN}[6]{RESET} Sync Generale SharedPreferences: {RED}-40 giorni{RESET}")
        print(f" {CYAN}[7]{RESET} Sync Generale SharedPreferences: {GREEN}Oggi (Now){RESET}")
        print(f" {CYAN}[8]{RESET} Sync Generale SharedPreferences: {RED}Reset (null){RESET}")
        print(" ───────────────────────────────────────────────")
        print(f" {CYAN}[9]{RESET} {BOLD}ENTRAMBI: -10 giorni{RESET} (Soft Stale)")
        print(f" {CYAN}[10]{RESET} {BOLD}ENTRAMBI: -40 giorni{RESET} (Hard Stale)")
        print(" ───────────────────────────────────────────────")
        print(f" {CYAN}[r]{RESET} Riavvia solo l'applicazione")
        print(f" {CYAN}[q]{RESET} Esci")

        choice = input(f"\n{BOLD}Scelta > {RESET}").strip().lower()

        if choice in ["q", "exit", "quit"]:
            print("Arrivederci!")
            break
        elif choice == "r":
            restart_app(device_serial)
            continue

        off_days = None
        gen_days = None
        off_null = False
        gen_null = False

        if choice == "1":
            off_days = 10
        elif choice == "2":
            off_days = 40
        elif choice == "3":
            off_days = 0
        elif choice == "4":
            off_null = True
        elif choice == "5":
            gen_days = 10
        elif choice == "6":
            gen_days = 40
        elif choice == "7":
            gen_days = 0
        elif choice == "8":
            gen_null = True
        elif choice == "9":
            off_days = 10
            gen_days = 10
        elif choice == "10":
            off_days = 40
            gen_days = 40
        else:
            print(f"{RED}Scelta non valida.{RESET}")
            continue

        new_xml = update_sync_dates(
            xml_content,
            offline_db_days=off_days,
            general_sync_days=gen_days,
            offline_db_null=off_null,
            general_sync_null=gen_null,
        )
        write_shared_prefs_xml(new_xml, device_serial)
        print(f"{GREEN}✓ SharedPreferences aggiornate con successo!{RESET}")
        restart_app(device_serial)
        time.sleep(1)


def parse_day_arg(val):
    if val is None:
        return None, False
    val_str = str(val).strip().lower()
    if val_str in ["null", "none", "reset"]:
        return None, True
    if val_str in ["now", "today", "0"]:
        return 0, False
    # Rimuove eventuale segno meno se specificato (-10 -> 10 giorni fa)
    try:
        num = abs(int(val_str))
        return num, False
    except ValueError:
        raise argparse.ArgumentTypeError(f"Valore giorni non valido: '{val}'. Usa -10, -40, now o null.")


def main():
    parser = argparse.ArgumentParser(
        description="G-Scanner Tool: Modifica a runtime/a freddo le date di sincronizzazione in SharedPreferences via ADB."
    )
    parser.add_argument("-s", "--serial", help="Serial del device ADB da usare.")
    parser.add_argument("--offline-db", help="Imposta offlineDbLastSyncedAt: -10, -40, now, null, o numero di giorni fa.")
    parser.add_argument("--general", help="Imposta celiac_app_last_sync_time: -10, -40, now, null, o numero di giorni fa.")
    parser.add_argument("--both", help="Imposta sia offline-db che general: -10, -40, now, o numero di giorni fa.")
    parser.add_argument("--status", action="store_true", help="Mostra solo lo stato attuale delle date e termina.")
    parser.add_argument("--no-restart", action="store_true", help="Non riavviare l'app dopo l'aggiornamento.")

    args = parser.parse_args()

    # Controlla device ADB
    devices = get_connected_devices()
    if not devices:
        print(f"{RED}Nessun dispositivo ADB connesso. Assicurati che il telefono/emulatore sia collegato e abbia il debug USB attivo.{RESET}")
        sys.exit(1)

    device_serial = args.serial or devices[0]
    if len(devices) > 1 and not args.serial:
        print(f"{YELLOW}Più dispositivi connessi. Uso il primo: {device_serial}{RESET}")

    xml_content = read_shared_prefs_xml(device_serial)

    # Solo status
    if args.status:
        print_status(xml_content)
        sys.exit(0)

    # Argomenti CLI
    if args.both or args.offline_db is not None or args.general is not None:
        off_days = None
        off_null = False
        gen_days = None
        gen_null = False

        if args.both:
            both_days, both_null = parse_day_arg(args.both)
            off_days, off_null = both_days, both_null
            gen_days, gen_null = both_days, both_null
        else:
            if args.offline_db is not None:
                off_days, off_null = parse_day_arg(args.offline_db)
            if args.general is not None:
                gen_days, gen_null = parse_day_arg(args.general)

        new_xml = update_sync_dates(
            xml_content,
            offline_db_days=off_days,
            general_sync_days=gen_days,
            offline_db_null=off_null,
            general_sync_null=gen_null,
        )
        write_shared_prefs_xml(new_xml, device_serial)
        print(f"{GREEN}✓ SharedPreferences aggiornate con successo.{RESET}")

        if not args.no_restart:
            restart_app(device_serial)

        # Mostra nuovo stato
        updated_xml = read_shared_prefs_xml(device_serial)
        print_status(updated_xml)
        sys.exit(0)

    # Altrimenti entra nel menu interattivo
    interactive_menu(device_serial)


if __name__ == "__main__":
    main()
