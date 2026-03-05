#!/usr/bin/env python3
"""
Simple BIMS Financial Database Initialization
"""

import json
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path


def create_database():
    """Create BIMS financial database"""

    # Ensure data directory exists
    data_dir = Path("./data")
    data_dir.mkdir(exist_ok=True)

    # Connect to database
    conn = sqlite3.connect("./data/phi_financial_bims.db")
    cursor = conn.cursor()

    # Create schema
    schema_sql = """
    -- Companies table (BIMS-integrated)
    CREATE TABLE IF NOT EXISTS companies (
        id TEXT PRIMARY KEY,
        bims_name TEXT UNIQUE NOT NULL,
        legal_name TEXT NOT NULL,
        company_type TEXT,
        jurisdiction TEXT,
        ein TEXT,
        status TEXT DEFAULT 'ACTIVE',
        website TEXT,
        primary_business TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        bims_last_sync TEXT,
        bims_completeness_score REAL
    );

    -- Company-specific chart of accounts
    CREATE TABLE IF NOT EXISTS company_accounts (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        account_number TEXT NOT NULL,
        account_name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        subcategory TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (company_id) REFERENCES companies(id),
        UNIQUE(company_id, account_number)
    );

    -- General ledger transactions
    CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        debit_credit TEXT NOT NULL,
        description TEXT,
        reference_number TEXT,
        source_document TEXT,
        ai_confidence REAL,
        verified INTEGER DEFAULT 0,
        verified_by TEXT,
        verified_at TEXT,
        bims_integrated INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (company_id) REFERENCES companies(id),
        FOREIGN KEY (account_id) REFERENCES company_accounts(id)
    );

    -- Revenue streams
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
        bims_business_alignment TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (company_id) REFERENCES companies(id)
    );

    -- Revenue recognition
    CREATE TABLE IF NOT EXISTS revenue_recognition (
        id TEXT PRIMARY KEY,
        revenue_stream_id TEXT NOT NULL,
        recognition_date TEXT NOT NULL,
        amount REAL NOT NULL,
        period_start TEXT,
        period_end TEXT,
        verification_sources TEXT,
        ai_verification_score REAL,
        bims_completeness_check INTEGER DEFAULT 0,
        blockchain_hash TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (revenue_stream_id) REFERENCES revenue_streams(id)
    );

    -- Indexes
    CREATE INDEX IF NOT EXISTS idx_companies_bims_name ON companies(bims_name);
    CREATE INDEX IF NOT EXISTS idx_company_accounts_company ON company_accounts(company_id);
    CREATE INDEX IF NOT EXISTS idx_transactions_company_date ON transactions(company_id, transaction_date);
    """

    cursor.executescript(schema_sql)
    print("✅ Database schema created")

    # Load BIMS config and initialize companies
    try:
        with open("../config/organizational-authority.json", "r") as f:
            bims_config = json.load(f)

        companies = bims_config["organizational_structure"]["holding_entities"]

        for company_data in companies:
            company_id = str(uuid.uuid4())

            # Calculate completeness score
            completeness = calculate_completeness_score(company_data)

            cursor.execute(
                """
                INSERT OR REPLACE INTO companies
                (id, bims_name, legal_name, company_type, jurisdiction, ein, status, website, primary_business, bims_completeness_score)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
                (
                    company_id,
                    company_data["name"],
                    company_data["name"],
                    company_data.get("type"),
                    company_data.get("jurisdiction"),
                    company_data.get("ein"),
                    company_data.get("status", "ACTIVE"),
                    company_data.get("website"),
                    company_data.get("primary_business"),
                    completeness,
                ),
            )

            # Create chart of accounts for company
            create_company_coa(cursor, company_id, company_data["name"])

        conn.commit()
        print(f"✅ Initialized {len(companies)} BIMS companies")

    except Exception as e:
        print(f"❌ Error initializing companies: {e}")
        conn.rollback()

    conn.close()
    print("🎯 BIMS Financial Database Ready!")


def calculate_completeness_score(company_data):
    """Calculate BIMS completeness score"""
    score = 0

    if company_data.get("primary_business") and company_data["primary_business"] != "TBD":
        score += 15
    if company_data.get("ein") and company_data["ein"] != "TBD":
        score += 10
    if company_data.get("jurisdiction") and company_data["jurisdiction"] != "TBD":
        score += 10
    if company_data.get("website"):
        score += 5
    if company_data.get("sole_owner"):
        score += 20
    if company_data.get("focus_areas"):
        score += 15
    if company_data.get("services") or company_data.get("collections"):
        score += 15
    if company_data.get("repositories") or company_data.get("infrastructure"):
        score += 10

    return min(score, 100)


def create_company_coa(cursor, company_id, company_name):
    """Create chart of accounts for a company"""

    if "Fractal5" in company_name:
        accounts = [
            ("1000", "Cash and Cash Equivalents", "Asset", "Current Assets"),
            ("1100", "Accounts Receivable", "Asset", "Current Assets"),
            ("1200", "Inventory", "Asset", "Current Assets"),
            ("2000", "Accounts Payable", "Liability", "Current Liabilities"),
            ("3000", "Common Stock", "Equity", "Equity"),
            ("3100", "Retained Earnings", "Equity", "Equity"),
            ("4000", "Software Development Revenue", "Revenue", "Revenue"),
            ("4100", "Service Revenue", "Revenue", "Revenue"),
            ("5000", "Cost of Goods Sold", "Expense", "COGS"),
            ("5100", "Research and Development", "Expense", "Operating Expenses"),
            ("5200", "Cloud Infrastructure Costs", "Expense", "Operating Expenses"),
        ]
    elif "Blue Wave" in company_name:
        accounts = [
            ("1000", "Cash and Cash Equivalents", "Asset", "Current Assets"),
            ("1100", "Accounts Receivable", "Asset", "Current Assets"),
            ("2000", "Accounts Payable", "Liability", "Current Liabilities"),
            ("3000", "Common Stock", "Equity", "Equity"),
            ("3100", "Retained Earnings", "Equity", "Equity"),
            ("4000", "Campaign Technology Revenue", "Revenue", "Revenue"),
            ("4100", "Consulting Services Revenue", "Revenue", "Revenue"),
            ("5000", "Technology Development Costs", "Expense", "Operating Expenses"),
            ("5100", "Campaign Operations", "Expense", "Operating Expenses"),
            ("5200", "Compliance and Legal", "Expense", "Operating Expenses"),
        ]
    elif "Plane4" in company_name:
        accounts = [
            ("1000", "Cash and Cash Equivalents", "Asset", "Current Assets"),
            ("1100", "Accounts Receivable", "Asset", "Current Assets"),
            ("1200", "Inventory - Raw Materials", "Asset", "Current Assets"),
            ("1210", "Inventory - Work in Progress", "Asset", "Current Assets"),
            ("1220", "Inventory - Finished Goods", "Asset", "Current Assets"),
            ("2000", "Accounts Payable", "Liability", "Current Liabilities"),
            ("3000", "Common Stock", "Equity", "Equity"),
            ("3100", "Retained Earnings", "Equity", "Equity"),
            ("4000", "Custom Furniture Sales", "Revenue", "Revenue"),
            ("4100", "Product Sales", "Revenue", "Revenue"),
            ("5000", "Cost of Goods Sold", "Expense", "COGS"),
            ("5100", "Materials and Supplies", "Expense", "Operating Expenses"),
            ("5200", "Labor Costs", "Expense", "Operating Expenses"),
            ("5300", "Facility Costs", "Expense", "Operating Expenses"),
        ]
    else:
        accounts = [
            ("1000", "Cash and Cash Equivalents", "Asset", "Current Assets"),
            ("1100", "Accounts Receivable", "Asset", "Current Assets"),
            ("2000", "Accounts Payable", "Liability", "Current Liabilities"),
            ("3000", "Common Stock", "Equity", "Equity"),
            ("3100", "Retained Earnings", "Equity", "Equity"),
            ("4000", "Revenue", "Revenue", "Revenue"),
            ("5000", "Cost of Goods Sold", "Expense", "COGS"),
            ("5100", "Operating Expenses", "Expense", "Operating Expenses"),
        ]

    # Insert accounts
    for account_number, account_name, account_type, subcategory in accounts:
        account_id = str(uuid.uuid4())
        cursor.execute(
            """
            INSERT INTO company_accounts
            (id, company_id, account_number, account_name, account_type, subcategory)
            VALUES (?, ?, ?, ?, ?, ?)
        """,
            (account_id, company_id, account_number, account_name, account_type, subcategory),
        )


if __name__ == "__main__":
    create_database()
