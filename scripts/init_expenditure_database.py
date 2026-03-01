#!/usr/bin/env python3
"""
PHI Expenditure Database Initialization Script
Creates all required tables and indexes for the expenditure tracking system.

Usage:
    python3 init_expenditure_database.py

Environment Variables:
    EXPENDITURE_DB - PostgreSQL connection string
    Example: postgresql://phi_admin:password@localhost:5432/expenditures
"""

import os
import sys
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from expenditure_models import ExpenditureDatabase

def init_database():
    """Initialize the expenditure tracking database."""

    # Get database connection from environment
    db_connection = os.environ.get(
        'EXPENDITURE_DB',
        'postgresql://phi_admin:secure_password@localhost:5432/expenditures'
    )

    print("=" * 70)
    print("PHI EXPENDITURE TRACKING SYSTEM - DATABASE INITIALIZATION")
    print("=" * 70)
    print()

    # Parse connection string to hide password
    import re
    safe_connection = re.sub(r'://([^:]+):([^@]+)@', r'://\1:****@', db_connection)
    print(f"📊 Database: {safe_connection}")
    print()

    try:
        # Create database connection
        print("🔌 Connecting to database...")
        db = ExpenditureDatabase(db_connection)
        print("✓ Connected successfully")
        print()

        # Create all tables
        print("🏗️  Creating database schema...")
        print()

        tables_created = db.create_tables()

        if tables_created:
            print("✓ All tables created successfully:")
            print("  • expenditures")
            print("  • expenditure_audit_log")
            print("  • vendors")
            print("  • recurring_expenditures")
            print("  • budget_allocations")
            print()

            # Create indexes for performance
            print("📇 Creating indexes for performance...")
            create_indexes(db)
            print("✓ Indexes created")
            print()

            # Verify tables exist
            print("🔍 Verifying database schema...")
            verify_tables(db)
            print()

            print("=" * 70)
            print("✅ DATABASE INITIALIZATION COMPLETE")
            print("=" * 70)
            print()
            print("Next steps:")
            print("  1. Configure Gmail OAuth credentials")
            print("  2. Run phi_expenditure_extractor.py to populate data")
            print("  3. Launch expenditure_dashboard.py to view data")
            print()

            return True

        else:
            print("⚠️  Tables already exist (skipping creation)")
            print()
            return True

    except Exception as e:
        print()
        print("❌ ERROR: Database initialization failed")
        print(f"   {str(e)}")
        print()
        print("Troubleshooting:")
        print("  • Ensure PostgreSQL is running")
        print("  • Verify connection string is correct")
        print("  • Check database user has CREATE TABLE permissions")
        print()
        return False


def create_indexes(db):
    """Create performance indexes on expenditure tables."""

    indexes = [
        # Expenditures table indexes
        "CREATE INDEX IF NOT EXISTS idx_expenditures_date ON expenditures(date DESC)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_company ON expenditures(company)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_vendor ON expenditures(vendor)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_category ON expenditures(category)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_verified ON expenditures(verified)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_confidence ON expenditures(confidence)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_amount ON expenditures(amount DESC)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_created_at ON expenditures(created_at DESC)",

        # Composite indexes for common queries
        "CREATE INDEX IF NOT EXISTS idx_expenditures_company_date ON expenditures(company, date DESC)",
        "CREATE INDEX IF NOT EXISTS idx_expenditures_verified_confidence ON expenditures(verified, confidence)",

        # Audit log indexes
        "CREATE INDEX IF NOT EXISTS idx_audit_log_expenditure_id ON expenditure_audit_log(expenditure_id)",
        "CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON expenditure_audit_log(timestamp DESC)",

        # Vendors table indexes
        "CREATE INDEX IF NOT EXISTS idx_vendors_name ON vendors(name)",
        "CREATE INDEX IF NOT EXISTS idx_vendors_total_spent ON vendors(total_spent DESC)",

        # Recurring expenses indexes
        "CREATE INDEX IF NOT EXISTS idx_recurring_active ON recurring_expenditures(active)",
        "CREATE INDEX IF NOT EXISTS idx_recurring_next_expected ON recurring_expenditures(next_expected)",

        # Budget allocations indexes
        "CREATE INDEX IF NOT EXISTS idx_budget_company_category ON budget_allocations(company, category)",
    ]

    for idx_sql in indexes:
        try:
            db.session.execute(idx_sql)
        except Exception as e:
            print(f"  Warning: {e}")

    db.session.commit()


def verify_tables(db):
    """Verify all required tables exist."""

    required_tables = [
        'expenditures',
        'expenditure_audit_log',
        'vendors',
        'recurring_expenditures',
        'budget_allocations'
    ]

    for table in required_tables:
        try:
            result = db.session.execute(
                f"SELECT COUNT(*) FROM {table}"
            ).fetchone()
            print(f"  ✓ {table}: {result[0]} rows")
        except Exception as e:
            print(f"  ✗ {table}: ERROR - {e}")


if __name__ == '__main__':
    success = init_database()
    sys.exit(0 if success else 1)
