#!/usr/bin/env python3
"""
Simple PHI Database Migration Script
"""

import os
import sqlite3
from pathlib import Path


def migrate_database():
    db_path = Path("/workspaces/dominion-os-demo-build/scripts/data/expenditures.db")

    if not db_path.exists():
        print("Database not found, creating new one...")
        db_path.parent.mkdir(exist_ok=True)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Create companies table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS companies (
                id TEXT PRIMARY KEY,
                company_name TEXT NOT NULL UNIQUE,
                legal_name TEXT,
                tax_id TEXT,
                address TEXT,
                phone TEXT,
                email TEXT,
                website TEXT,
                industry TEXT,
                fiscal_year_end TEXT,
                currency TEXT DEFAULT 'USD',
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """
        )

        # Create accounts table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS accounts (
                id TEXT PRIMARY KEY,
                company_id TEXT NOT NULL,
                account_number TEXT NOT NULL,
                account_name TEXT NOT NULL,
                account_type TEXT NOT NULL,
                subtype TEXT,
                description TEXT,
                is_active INTEGER DEFAULT 1,
                parent_account_id TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies(id),
                FOREIGN KEY (parent_account_id) REFERENCES accounts(id)
            )
        """
        )

        # Create transactions table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                company_id TEXT NOT NULL,
                transaction_date TEXT NOT NULL,
                account_id TEXT NOT NULL,
                amount REAL NOT NULL,
                debit_credit TEXT NOT NULL,
                description TEXT NOT NULL,
                reference_number TEXT,
                transaction_type TEXT DEFAULT 'Journal Entry',
                source_document TEXT,
                currency TEXT DEFAULT 'USD',
                exchange_rate REAL DEFAULT 1.0,
                ai_confidence REAL,
                verified INTEGER DEFAULT 0,
                verified_by TEXT,
                verified_at TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies(id),
                FOREIGN KEY (account_id) REFERENCES accounts(id)
            )
        """
        )

        # Create revenue tables
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS revenue_streams (
                id TEXT PRIMARY KEY,
                company_id TEXT NOT NULL,
                stream_name TEXT NOT NULL,
                stream_type TEXT,
                recognition_method TEXT DEFAULT 'Accrual',
                contract_value REAL,
                start_date TEXT,
                end_date TEXT,
                payment_terms TEXT,
                ai_forecast_model TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies(id)
            )
        """
        )

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS revenue_recognitions (
                id TEXT PRIMARY KEY,
                revenue_stream_id TEXT NOT NULL,
                recognition_date TEXT NOT NULL,
                amount REAL NOT NULL,
                period_start TEXT,
                period_end TEXT,
                verification_sources TEXT,
                ai_verification_score REAL,
                blockchain_hash TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (revenue_stream_id) REFERENCES revenue_streams(id)
            )
        """
        )

        # Insert default company
        default_company_id = "550e8400-e29b-41d4-a716-446655440000"
        cursor.execute(
            """
            INSERT OR IGNORE INTO companies (id, company_name, legal_name, industry, currency)
            VALUES (?, 'Fractal5 Solutions Inc', 'Fractal5 Solutions Incorporated', 'Technology', 'USD')
        """,
            (default_company_id,),
        )

        # Insert default chart of accounts
        coa_data = [
            ("1000", "Cash", "ASSET", "Current Asset"),
            ("1100", "Accounts Receivable", "ASSET", "Current Asset"),
            ("1200", "Inventory", "ASSET", "Current Asset"),
            ("2000", "Accounts Payable", "LIABILITY", "Current Liability"),
            ("3000", "Common Stock", "EQUITY", "Common Stock"),
            ("3100", "Retained Earnings", "EQUITY", "Retained Earnings"),
            ("4000", "Service Revenue", "REVENUE", "Operating Revenue"),
            ("4100", "Product Sales", "REVENUE", "Operating Revenue"),
            ("5000", "Cost of Goods Sold", "EXPENSE", "Cost of Goods Sold"),
            ("5100", "Operating Expenses", "EXPENSE", "Operating Expense"),
            ("5200", "Marketing Expenses", "EXPENSE", "Operating Expense"),
        ]

        for account_num, name, acc_type, subtype in coa_data:
            account_id = f"account-{account_num}"
            cursor.execute(
                """
                INSERT OR IGNORE INTO accounts (id, company_id, account_number, account_name, account_type, subtype)
                VALUES (?, ?, ?, ?, ?, ?)
            """,
                (account_id, default_company_id, account_num, name, acc_type, subtype),
            )

        conn.commit()
        print("✅ Database migration completed successfully!")

    except Exception as e:
        print(f"❌ Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    migrate_database()
