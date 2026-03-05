-- PHI BIMS-Aligned Financial Database Schema
-- SQLite version for initial implementation

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
    ai_forecast_model TEXT, -- JSON
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
    verification_sources TEXT, -- JSON
    ai_verification_score REAL,
    bims_completeness_check INTEGER DEFAULT 0,
    blockchain_hash TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (revenue_stream_id) REFERENCES revenue_streams(id)
);

-- BIMS audit logs
CREATE TABLE IF NOT EXISTS bims_audit_logs (
    id TEXT PRIMARY KEY,
    company_id TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    old_values TEXT, -- JSON
    new_values TEXT, -- JSON
    performed_by TEXT NOT NULL,
    performed_at TEXT DEFAULT CURRENT_TIMESTAMP,
    bims_authority_level TEXT,
    FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_companies_bims_name ON companies(bims_name);
CREATE INDEX IF NOT EXISTS idx_company_accounts_company ON company_accounts(company_id);
CREATE INDEX IF NOT EXISTS idx_transactions_company_date ON transactions(company_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_revenue_streams_company ON revenue_streams(company_id);
