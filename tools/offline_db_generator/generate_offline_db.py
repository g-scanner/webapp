#!/usr/bin/env python3
"""
G-Scanner Offline Database Generator (DuckDB + SQLite)
Conformità ODbL 1.0 (Open Food Facts Database)

Estrae i dump compressi di Open Food Facts (JSONL.GZ) in modalità streaming
a basso consumo di memoria RAM (< 1.5 GB), applica i filtri per i 3 Tier,
genera database SQLite con indici primari su 'code' e crea pacchetti rolling
delta (7 giorni, 30 giorni) e completi in formato .db.gz.
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

def export_tier(
    con: duckdb.DuckDBPyConnection,
    where_clause: str,
    output_sqlite_path: Path,
    time_cutoff: int = None
):
    if output_sqlite_path.exists():
        output_sqlite_path.unlink()

    # Prepara la tabella in SQLite prima del popolamento
    sqlite_conn = sqlite3.connect(output_sqlite_path)
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

    full_where = where_clause
    if time_cutoff is not None:
        full_where = f"({where_clause}) AND last_modified_t >= {time_cutoff}"

    # Utilizziamo INSERT INTO standard (pienamente supportato dal driver SQLite di DuckDB).
    # Per garantire unicità assoluta della PRIMARY KEY ed evitare conflitti,
    # deduplichiamo preventivamente via finestra analitica (mantenendo la revisione più recente).
    query = f"""
    INSERT INTO sqlite_db.products (
        code, product_name, brands, ingredients_text,
        allergens_tags, labels_tags, traces_tags, last_modified_t
    )
    SELECT
        code, product_name, brands, ingredients_text,
        allergens_tags, labels_tags, traces_tags, last_modified_t
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY code ORDER BY last_modified_t DESC) as rn
        FROM all_products
        WHERE {full_where}
    ) sub
    WHERE rn = 1;
    """

    con.execute(f"ATTACH '{output_sqlite_path.as_posix()}' AS sqlite_db (TYPE SQLITE);")
    con.execute(query)
    con.execute("DETACH sqlite_db;")

    # Crea indice secondario direttamente con sqlite3 nativo dopo l'inserimento bulk (massima velocità)
    sqlite_conn = sqlite3.connect(output_sqlite_path)
    sqlite_conn.execute("CREATE INDEX IF NOT EXISTS idx_products_last_modified ON products(last_modified_t);")
    sqlite_conn.execute("PRAGMA optimize;")
    sqlite_conn.close()

def main():
    parser = argparse.ArgumentParser(description="Generatore DB Offline G-Scanner")
    parser.add_argument("--input", required=True, help="Percorso del dump OFF (.jsonl o .jsonl.gz)")
    parser.add_argument("--outdir", default="./dist", help="Directory di output per gli archivi")
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

    print(f"[{datetime.now(timezone.utc).isoformat()}] Inizializzazione DuckDB con storage su disco...")
    con = duckdb.connect(str(temp_duckdb_path))
    con.execute("INSTALL sqlite; LOAD sqlite;")
    con.execute("SET preserve_insertion_order = false;")

    print(f"[{datetime.now(timezone.utc).isoformat()}] Estrazione e normalizzazione da {input_path} (singolo passaggio)...")
    con.execute(f"""
        CREATE TABLE all_products AS
        SELECT
            CAST(code AS VARCHAR) AS code,
            COALESCE(product_name, '') AS product_name,
            COALESCE(brands, '') AS brands,
            COALESCE(ingredients_text, '') AS ingredients_text,
            COALESCE(array_to_string(allergens_tags, ','), '') AS allergens_tags,
            COALESCE(array_to_string(labels_tags, ','), '') AS labels_tags,
            COALESCE(array_to_string(traces_tags, ','), '') AS traces_tags,
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
                'last_modified_t': 'BIGINT'
            }}
        )
        WHERE code IS NOT NULL AND TRIM(CAST(code AS VARCHAR)) != '';
    """)

    count = con.execute("SELECT count(*) FROM all_products;").fetchone()[0]
    print(f"[{datetime.now(timezone.utc).isoformat()}] Prodotti estratti con successo: {count}")

    # Definizione filtri Tier
    filter_tier1 = """
        labels_tags ILIKE '%gluten-free%' 
        OR labels_tags ILIKE '%sans-gluten%' 
        OR labels_tags ILIKE '%spiga-sbarrata%' 
        OR labels_tags ILIKE '%senza-glutine%'
    """

    filter_tier2 = f"""
        ({filter_tier1})
        OR allergens_tags ILIKE '%gluten%'
        OR traces_tags ILIKE '%gluten%'
        OR ingredients_text ILIKE '%glutine%'
        OR ingredients_text ILIKE '%frumento%'
        OR ingredients_text ILIKE '%orzo%'
        OR ingredients_text ILIKE '%segale%'
        OR ingredients_text ILIKE '%avena%'
    """

    filter_tier3 = "1 = 1"

    tiers_config = {
        "tier1": filter_tier1,
        "tier2": filter_tier2,
        "tier3": filter_tier3,
    }

    manifest = {
        "version": 1,
        "published_at": now_epoch,
        "delta_7d_since": delta_7d_since,
        "delta_30d_since": delta_30d_since,
        "tiers": {}
    }

    for tier_name, where_clause in tiers_config.items():
        print(f"\n--- Generazione {tier_name.upper()} ---")
        tier_info = {}

        # 1. Full DB
        raw_full = outdir / f"{tier_name}_full.db"
        gz_full = outdir / f"{tier_name}_full.db.gz"
        print(f"Estrazione {raw_full.name}...")
        export_tier(con, where_clause, raw_full)
        print(f"Compressione {gz_full.name}...")
        size = compress_gzip(raw_full, gz_full)
        sha = compute_sha256(gz_full)
        raw_full.unlink()
        tier_info["full"] = {
            "file": gz_full.name,
            "size_bytes": size,
            "sha256": sha
        }

        # 2. Delta 7 giorni
        raw_7d = outdir / f"{tier_name}_delta_7d.db"
        gz_7d = outdir / f"{tier_name}_delta_7d.db.gz"
        print(f"Estrazione {raw_7d.name}...")
        export_tier(con, where_clause, raw_7d, time_cutoff=delta_7d_since)
        print(f"Compressione {gz_7d.name}...")
        size_7d = compress_gzip(raw_7d, gz_7d)
        sha_7d = compute_sha256(gz_7d)
        raw_7d.unlink()
        tier_info["delta_7d"] = {
            "file": gz_7d.name,
            "size_bytes": size_7d,
            "sha256": sha_7d
        }

        # 3. Delta 30 giorni
        raw_30d = outdir / f"{tier_name}_delta_30d.db"
        gz_30d = outdir / f"{tier_name}_delta_30d.db.gz"
        print(f"Estrazione {raw_30d.name}...")
        export_tier(con, where_clause, raw_30d, time_cutoff=delta_30d_since)
        print(f"Compressione {gz_30d.name}...")
        size_30d = compress_gzip(raw_30d, gz_30d)
        sha_30d = compute_sha256(gz_30d)
        raw_30d.unlink()
        tier_info["delta_30d"] = {
            "file": gz_30d.name,
            "size_bytes": size_30d,
            "sha256": sha_30d
        }

        manifest["tiers"][tier_name] = tier_info

    version_file = outdir / "version.json"
    with open(version_file, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    con.close()
    if temp_duckdb_path.exists():
        temp_duckdb_path.unlink()

    print(f"\n[{datetime.now(timezone.utc).isoformat()}] Generazione completata con successo! File manifest creato in {version_file}")

if __name__ == "__main__":
    main()
