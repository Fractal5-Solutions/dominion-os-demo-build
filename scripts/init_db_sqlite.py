#!/usr/bin/env python3
import os

from sqlalchemy import create_engine, text

db_url = os.environ.get("EXPENDITURE_DB", "sqlite:///./data/expenditures.db")
engine = create_engine(db_url)

with engine.connect() as conn:
    # Expenditures table
    conn.execute(
        text(
            """
        CREATE TABLE IF NOT EXISTS expenditures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendor TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            invoice_number TEXT,
            category TEXT DEFAULT 'Uncategorized',
            confidence TEXT DEFAULT 'LOW',
            confidence_score REAL DEFAULT 0.5,
            verified INTEGER DEFAULT 0,
            verified_by TEXT,
            verified_at TEXT,
            tax_amount REAL,
            tax_type TEXT,
            ai_metadata TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """
        )
    )

    # Vendors table
    conn.execute(
        text(
            """
        CREATE TABLE IF NOT EXISTS vendors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            category TEXT,
            contact_email TEXT,
            notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """
        )
    )

    conn.commit()
    print("✓ Database initialized successfully")
