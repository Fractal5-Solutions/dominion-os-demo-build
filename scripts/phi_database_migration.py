#!/usr/bin/env python3
"""
PHI Financial Database Migration
Migrates expenditure database to full enterprise financial schema

Purpose: Upgrade SQLite database to support multi-company accounting
Features: Adds companies, accounts, transactions, revenue tables
Security: Maintains data integrity and PHI sovereignty
"""

import json
import os
import sqlite3
from datetime import datetime
from pathlib import Path


class FinancialDatabaseMigrator:
    """Migrates PHI database to enterprise financial schema"""

    def __init__(self, db_path: str = None):
        if db_path is None:
            # Default to scripts directory
            script_dir = Path(__file__).parent
            db_path = script_dir / "data" / "expenditures.db"

        self.db_path = Path(db_path)
        self.backup_path = self.db_path.with_suffix(f".backup_{int(datetime.now().timestamp())}")

    def create_backup(self):
        """Create backup before migration"""
        if self.db_path.exists():
            print(f"📦 Creating backup: {self.backup_path}")
            import shutil

            shutil.copy2(self.db_path, self.backup_path)
            print("✅ Backup created")
        else:
            print("⚠️  No existing database to backup")

    def migrate_database(self):
        """Perform database migration"""
        print("🚀 Starting PHI Financial Database Migration")
        print("=" * 50)

        self.create_backup()

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            # Check current schema
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            existing_tables = [row[0] for row in cursor.fetchall()]
            print(f"📊 Existing tables: {existing_tables}")

            # Create new tables
            self._create_companies_table(cursor)
            self._create_accounts_table(cursor)
            self._create_transactions_table(cursor)
            self._create_revenue_tables(cursor)

            # Migrate existing data
            self._migrate_expenditure_data(cursor, conn)

            # Create default company and accounts
            self._create_default_data(cursor, conn)

            conn.commit()
            print("✅ Migration completed successfully")

        except Exception as e:
            conn.rollback()
            print(f"❌ Migration failed: {e}")
            # Restore backup
            if self.backup_path.exists():
                print("🔄 Restoring backup...")
                import shutil

                shutil.copy2(self.backup_path, self.db_path)
                print("✅ Backup restored")
            raise
        finally:
            conn.close()

    def _create_companies_table(self, cursor):
        """Create companies table"""
        print("🏢 Creating companies table...")
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

    def _create_accounts_table(self, cursor):
        """Create chart of accounts"""
        print("📋 Creating accounts table...")
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

        # Create indexes
        cursor.execute(
            "CREATE INDEX IF NOT EXISTS idx_company_account ON accounts(company_id, account_number)"
        )

    def _create_transactions_table(self, cursor):
        """Create general ledger transactions"""
        print("📈 Creating transactions table...")
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

        # Create indexes
        cursor.execute(
            "CREATE INDEX IF NOT EXISTS idx_company_date ON transactions(company_id, transaction_date)"
        )
        cursor.execute(
            "CREATE INDEX IF NOT EXISTS idx_account_date ON transactions(account_id, transaction_date)"
        )

    def _create_revenue_tables(self, cursor):
        """Create revenue recognition tables"""
        print("💰 Creating revenue tables...")

        # Revenue streams
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
                ai_forecast_model TEXT,  -- JSON
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies(id)
            )
        """
        )

        # Revenue recognitions
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS revenue_recognitions (
                id TEXT PRIMARY KEY,
                revenue_stream_id TEXT NOT NULL,
                recognition_date TEXT NOT NULL,
                amount REAL NOT NULL,
                period_start TEXT,
                period_end TEXT,
                verification_sources TEXT,  -- JSON
                ai_verification_score REAL,
                blockchain_hash TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (revenue_stream_id) REFERENCES revenue_streams(id)
            )
        """
        )

    def _migrate_expenditure_data(self, cursor, conn):
        """Migrate existing expenditure data"""
        print("🔄 Migrating existing expenditure data...")

        # Check if expenditures table exists and has data
        cursor.execute(
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='expenditures'"
        )
        if cursor.fetchone()[0] == 0:
            print("ℹ️  No existing expenditures table to migrate")
            return

        cursor.execute("SELECT COUNT(*) FROM expenditures")
        count = cursor.fetchone()[0]
        if count == 0:
            print("ℹ️  No expenditure data to migrate")
            return

        print(f"📊 Migrating {count} expenditure records...")

        # Add company_id column to expenditures if it doesn't exist
        try:
            cursor.execute("ALTER TABLE expenditures ADD COLUMN company_id TEXT")
        except sqlite3.OperationalError:
            pass  # Column might already exist

        # For now, assign all existing expenditures to default company
        # In production, this would be more sophisticated
        cursor.execute(
            "UPDATE expenditures SET company_id = 'default-company-id' WHERE company_id IS NULL"
        )

        print("✅ Expenditure data migration completed")

    def _create_default_data(self, cursor, conn):
        """Create default company and chart of accounts"""
        print("🏗️  Creating default company and accounts...")

        # Default company
        default_company_id = "550e8400-e29b-41d4-a716-446655440000"  # UUID-like
        cursor.execute(
            """
            INSERT OR IGNORE INTO companies (id, company_name, legal_name, industry, currency)
            VALUES (?, 'Fractal5 Solutions Inc', 'Fractal5 Solutions Incorporated', 'Technology', 'USD')
        """,
            (default_company_id,),
        )

        # Create basic chart of accounts
        coa_data = [
            ("1000", "Cash", "Asset", "Current Asset"),
            ("1100", "Accounts Receivable", "Asset", "Current Asset"),
            ("1200", "Inventory", "Asset", "Current Asset"),
            ("2000", "Accounts Payable", "Liability", "Current Liability"),
            ("3000", "Common Stock", "Equity", "Common Stock"),
            ("3100", "Retained Earnings", "Equity", "Retained Earnings"),
            ("4000", "Service Revenue", "Revenue", "Operating Revenue"),
            ("4100", "Product Sales", "Revenue", "Operating Revenue"),
            ("5000", "Cost of Goods Sold", "Expense", "Cost of Goods Sold"),
            ("5100", "Operating Expenses", "Expense", "Operating Expense"),
            ("5200", "Marketing Expenses", "Expense", "Operating Expense"),
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

        # Update existing expenditures to use default company
        cursor.execute(
            "UPDATE expenditures SET company_id = ? WHERE company_id IS NULL OR company_id = ''",
            (default_company_id,),
        )

        print("✅ Default data created")


def main():
    """Main migration function"""
    migrator = FinancialDatabaseMigrator()
    migrator.migrate_database()

    print("\n" + "=" * 50)
    print("🎉 PHI FINANCIAL DATABASE MIGRATION COMPLETE")
    print("=" * 50)
    print("✅ Multi-company support enabled")
    print("✅ Chart of accounts implemented")
    print("✅ General ledger ready")
    print("✅ Revenue recognition prepared")
    print("✅ Data integrity maintained")
    print("\n🚀 Ready for enterprise financial operations!")


if __name__ == "__main__":
    main()
