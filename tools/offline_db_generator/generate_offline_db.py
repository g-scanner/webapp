#!/usr/bin/env python3
"""
G-Scanner Offline Database Generator (DuckDB + SQLite)
Conformità ODbL 1.0 (Open Food Facts Database)

Estrae i dump compressi di Open Food Facts (JSONL.GZ) in modalità streaming
a basso consumo di memoria RAM (< 4 GB) e controllo rigoroso del disco,
applica i filtri per i 4 Macro-Pacchetti (gluten_free, euro_core, america_core, global_top),
applica troncamenti di igiene dati (product_name <= 150, brands <= 80, ingredients <= 1000),
filtra codici a barre standard (8-14 caratteri) ed esclude record vuoti.
Genera database SQLite ottimizzati con page_size=4096, indici (code, last_modified_t)
e compattazione VACUUM, creando pacchetti rolling delta (7d, 30d) e full compattati .db.gz.
"""

import os
import sys
import json
import gzip
import shutil
import hashlib
import sqlite3
import argparse
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import duckdb
except ImportError:
    print("DuckDB non trovato. Installare con: pip install duckdb", file=sys.stderr)
    sys.exit(1)

def compute_sha256(file_path: Path) -> str:
    sha = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha.update(chunk)
    return sha.hexdigest()

def compress_gzip(src_path: Path, dest_path: Path) -> int:
    with open(src_path, "rb") as f_in:
        with gzip.open(dest_path, "wb", compresslevel=9) as f_out:
            shutil.copyfileobj(f_in, f_out)
    return dest_path.stat().st_size

def export_package(
    con: duckdb.DuckDBPyConnection,
    package_name: str,
    package_query: str,
    output_sqlite_path: Path,
    time_cutoff: int = None
) -> dict:
    if output_sqlite_path.exists():
        output_sqlite_path.unlink()

    # 1. Prepara lo schema SQLite iniziale con page_size 4096
    sqlite_conn = sqlite3.connect(output_sqlite_path)
    sqlite_conn.execute("PRAGMA page_size = 4096;")
    sqlite_conn.execute("""
    CREATE TABLE IF NOT EXISTS products (
        code TEXT PRIMARY KEY,
        product_name TEXT,
        brands TEXT,
        ingredients_text TEXT,
        allergens_tags TEXT,
        labels_tags TEXT,
        traces_tags TEXT,
        last_modified_t INTEGER
    );
    """)
    sqlite_conn.close()

    if time_cutoff is not None:
        filtered_query = f"SELECT * FROM ({package_query}) base_pkg WHERE last_modified_t >= {time_cutoff}"
    else:
        filtered_query = package_query

    # Inserimento atomico da DuckDB in SQLite con deduplicazione analitica
    # garantendo che 'code' sia univoco e che rimanga la revisione più recente.
    insert_query = f"""
    INSERT INTO sqlite_db.products (
        code, product_name, brands, ingredients_text,
        allergens_tags, labels_tags, traces_tags, last_modified_t
    )
    SELECT
        code, product_name, brands, ingredients_text,
        allergens_tags, labels_tags, traces_tags, last_modified_t
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY code ORDER BY last_modified_t DESC) as rn
        FROM ({filtered_query}) candidates
    ) sub
    WHERE rn = 1;
    """

    con.execute(f"ATTACH '{output_sqlite_path.as_posix()}' AS sqlite_db (TYPE SQLITE);")
    con.execute(insert_query)
    con.execute("DETACH sqlite_db;")

    # 2. Ottimizzazione SQLite post-insert: Indici, VACUUM compattazione, PRAGMA optimize
    sqlite_conn = sqlite3.connect(output_sqlite_path)
    sqlite_conn.execute("CREATE INDEX IF NOT EXISTS idx_code ON products(code);")
    sqlite_conn.execute("CREATE INDEX IF NOT EXISTS idx_last_mod ON products(last_modified_t);")
    sqlite_conn.execute("PRAGMA page_size = 4096;")
    sqlite_conn.execute("PRAGMA journal_mode = DELETE;")
    sqlite_conn.execute("VACUUM;")
    sqlite_conn.execute("PRAGMA optimize;")

    cursor = sqlite_conn.cursor()
    cursor.execute("SELECT count(*) FROM products;")
    record_count = cursor.fetchone()[0]
    sqlite_conn.close()

    # 3. Compressione Gzip e cancellazione immediata del file SQLite non compresso
    gz_path = output_sqlite_path.with_suffix(".db.gz")
    compressed_size = compress_gzip(output_sqlite_path, gz_path)
    sha256 = compute_sha256(gz_path)
    output_sqlite_path.unlink()

    return {
        "file": gz_path.name,
        "size_bytes": compressed_size,
        "sha256": sha256,
        "record_count": record_count
    }

def main():
    parser = argparse.ArgumentParser(description="Generatore DB Offline G-Scanner (4 Macro-Pacchetti)")
    parser.add_argument("--input", required=True, help="Percorso del dump OFF (.jsonl o .jsonl.gz)")
    parser.add_argument("--outdir", default="./dist", help="Directory di output per gli archivi")
    parser.add_argument("--delete-input", action="store_true", help="Elimina il file dump sorgente subito dopo l'ingestione DuckDB per liberare spazio disco")
    args = parser.parse_args()

    input_path = Path(args.input)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        print(f"File di input non trovato: {input_path}", file=sys.stderr)
        sys.exit(1)

    now_epoch = int(time.time())
    delta_7d_since = now_epoch - (7 * 86400)
    delta_30d_since = now_epoch - (30 * 86400)

    temp_duckdb_path = outdir / "temp_extract.duckdb"
    if temp_duckdb_path.exists():
        temp_duckdb_path.unlink()

    print(f"[{datetime.now(timezone.utc).isoformat()}] Inizializzazione DuckDB con limite memoria 4GB e disco temporaneo...")
    con = duckdb.connect(str(temp_duckdb_path))
    con.execute("INSTALL sqlite; LOAD sqlite;")
    con.execute("SET preserve_insertion_order = false;")
    con.execute("SET max_memory = '4GB';")
    con.execute("SET threads = 2;")

    print(f"[{datetime.now(timezone.utc).isoformat()}] Estrazione, filtraggio e igiene dati da {input_path}...")
    con.execute(f"""
        CREATE TABLE all_products AS
        SELECT
            TRIM(CAST(code AS VARCHAR)) AS code,
            SUBSTRING(COALESCE(product_name, ''), 1, 150) AS product_name,
            SUBSTRING(COALESCE(brands, ''), 1, 80) AS brands,
            SUBSTRING(COALESCE(ingredients_text, ''), 1, 1000) AS ingredients_text,
            COALESCE(array_to_string(allergens_tags, ','), '') AS allergens_tags,
            COALESCE(array_to_string(labels_tags, ','), '') AS labels_tags,
            COALESCE(array_to_string(traces_tags, ','), '') AS traces_tags,
            COALESCE(array_to_string(categories_tags, ','), '') AS categories_tags,
            COALESCE(array_to_string(countries_tags, ','), '') AS countries_tags,
            COALESCE(TRY_CAST(unique_scans_n AS BIGINT), 0) AS unique_scans_n,
            COALESCE(TRY_CAST(last_modified_t AS BIGINT), 0) AS last_modified_t
        FROM read_json(
            '{input_path.as_posix()}',
            format = 'newline_delimited',
            ignore_errors = true,
            columns = {{
                'code': 'VARCHAR',
                'product_name': 'VARCHAR',
                'brands': 'VARCHAR',
                'ingredients_text': 'VARCHAR',
                'allergens_tags': 'VARCHAR[]',
                'labels_tags': 'VARCHAR[]',
                'traces_tags': 'VARCHAR[]',
                'categories_tags': 'VARCHAR[]',
                'countries_tags': 'VARCHAR[]',
                'unique_scans_n': 'VARCHAR',
                'last_modified_t': 'VARCHAR'
            }}
        )
        WHERE code IS NOT NULL
          AND length(TRIM(CAST(code AS VARCHAR))) BETWEEN 8 AND 14
          AND (
              (product_name IS NOT NULL AND TRIM(product_name) != '')
              OR (ingredients_text IS NOT NULL AND TRIM(ingredients_text) != '')
          );
    """)

    total_valid = con.execute("SELECT count(*) FROM all_products;").fetchone()[0]
    print(f"[{datetime.now(timezone.utc).isoformat()}] Prodotti validi estratti: {total_valid}")

    # Pulizia disco preventiva se richiesta: elimina il dump originale da ~2GB
    if args.delete_input:
        print(f"[{datetime.now(timezone.utc).isoformat()}] Eliminazione file sorgente {input_path} per liberare spazio su disco runner...")
        try:
            input_path.unlink()
            print(f"[{datetime.now(timezone.utc).isoformat()}] File sorgente eliminato con successo. Spazio disco liberato: ~2 GB.")
        except Exception as e:
            print(f"Avviso: impossibile eliminare {input_path}: {e}", file=sys.stderr)

    # Definizione filtri per i 4 Macro-Pacchetti
    filter_gluten_free = """
        labels_tags ILIKE '%gluten-free%' 
        OR labels_tags ILIKE '%sans-gluten%' 
        OR labels_tags ILIKE '%spiga-sbarrata%' 
        OR labels_tags ILIKE '%senza-glutine%'
        OR categories_tags ILIKE '%gluten-free%' 
        OR product_name ILIKE '%senza glutine%' 
        OR product_name ILIKE '%gluten free%'
    """

    filter_euro_market = """
        regexp_matches(LOWER(countries_tags), 'italy|france|germany|spain|united-kingdom')
        AND ingredients_text != ''
        AND unique_scans_n >= 1
    """

    filter_america_market = """
        regexp_matches(LOWER(countries_tags), 'united-states|canada|mexico|argentina|brazil')
        AND ingredients_text != ''
        AND unique_scans_n >= 1
    """

    packages_config = {
        "gluten_free": f"""
            SELECT * FROM all_products
            WHERE {filter_gluten_free}
        """,
        "euro_core": f"""
            SELECT * FROM all_products
            WHERE ({filter_gluten_free})
               OR ({filter_euro_market})
        """,
        "america_core": f"""
            SELECT * FROM all_products
            WHERE ({filter_gluten_free})
               OR ({filter_america_market})
        """,
        "global_top": f"""
            SELECT * FROM all_products
            WHERE ({filter_gluten_free})
            UNION
            (SELECT * FROM all_products
             WHERE ingredients_text != ''
             ORDER BY unique_scans_n DESC
             LIMIT 800000)
        """
    }

    manifest = {
        "version": 2,
        "published_at": now_epoch,
        "delta_7d_since": delta_7d_since,
        "delta_30d_since": delta_30d_since,
        "packages": {}
    }

    for pkg_name, query in packages_config.items():
        print(f"\n=======================================================")
        print(f"[{datetime.now(timezone.utc).isoformat()}] Generazione pacchetto: {pkg_name.upper()}")
        print(f"=======================================================")
        pkg_info = {}

        # 1. Full Package
        raw_full = outdir / f"{pkg_name}_full.db"
        print(f"Esportazione Full DB ({raw_full.name})...")
        pkg_info["full"] = export_package(con, pkg_name, query, raw_full)
        print(f"-> Full completato: {pkg_info['full']['record_count']} record, {pkg_info['full']['size_bytes']} bytes compressi")

        # 2. Delta 7 giorni
        raw_7d = outdir / f"{pkg_name}_delta_7d.db"
        print(f"Esportazione Delta 7D ({raw_7d.name})...")
        pkg_info["delta_7d"] = export_package(con, pkg_name, query, raw_7d, time_cutoff=delta_7d_since)
        print(f"-> Delta 7D completato: {pkg_info['delta_7d']['record_count']} record, {pkg_info['delta_7d']['size_bytes']} bytes compressi")

        # 3. Delta 30 giorni
        raw_30d = outdir / f"{pkg_name}_delta_30d.db"
        print(f"Esportazione Delta 30D ({raw_30d.name})...")
        pkg_info["delta_30d"] = export_package(con, pkg_name, query, raw_30d, time_cutoff=delta_30d_since)
        print(f"-> Delta 30D completato: {pkg_info['delta_30d']['record_count']} record, {pkg_info['delta_30d']['size_bytes']} bytes compressi")

        manifest["packages"][pkg_name] = pkg_info

    version_file = outdir / "version.json"
    with open(version_file, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    con.close()
    if temp_duckdb_path.exists():
        temp_duckdb_path.unlink()

    print(f"\n[{datetime.now(timezone.utc).isoformat()}] Pipeline completata con successo!")
    print(f"File manifest generato in: {version_file}")
    for pkg_name, info in manifest["packages"].items():
        print(f" - {pkg_name}: full={info['full']['size_bytes']//1024} KB ({info['full']['record_count']} rec), delta_30d={info['delta_30d']['size_bytes']//1024} KB, delta_7d={info['delta_7d']['size_bytes']//1024} KB")

if __name__ == "__main__":
    main()
