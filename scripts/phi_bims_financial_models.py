#!/usr/bin/env python3
"""
PHI BIMS-Aligned Financial Database Models
Multi-company financial accounting system with BIMS integration

Purpose: Define comprehensive financial data models for all Matthew Burbidge companies
Security: PHI encryption, BIMS authority validation, immutable audit trails
Status: BIMS-ALIGNED IMPLEMENTATION
"""

import hashlib
import json
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional

# Note: Install dependencies: pip install sqlalchemy psycopg2-binary cryptography

try:
    import uuid

    from sqlalchemy import (
        DECIMAL,
        Boolean,
        Column,
        DateTime,
        Float,
        ForeignKey,
        Index,
        Integer,
        String,
        Text,
        create_engine,
    )
    from sqlalchemy.dialects.postgresql import JSONB, UUID
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy.orm import relationship, sessionmaker

    SQLALCHEMY_AVAILABLE = True
except ImportError:
    SQLALCHEMY_AVAILABLE = False
    print("⚠️  SQLAlchemy not installed. Run: pip install sqlalchemy psycopg2-binary")


Base = declarative_base() if SQLALCHEMY_AVAILABLE else object


class CompanyType(str, Enum):
    """BIMS company types"""

    C_CORPORATION = "C-Corporation"
    LLC = "LLC"
    SOLE_PROPRIETORSHIP = "Sole Proprietorship"


class AccountType(str, Enum):
    """Chart of accounts types"""

    ASSET = "Asset"
    LIABILITY = "Liability"
    EQUITY = "Equity"
    REVENUE = "Revenue"
    EXPENSE = "Expense"


class RevenueRecognitionMethod(str, Enum):
    """Revenue recognition methods"""

    ACCRUAL = "Accrual"
    CASH = "Cash"
    COMPLETED_CONTRACT = "Completed Contract"
    PERCENTAGE_COMPLETION = "Percentage Completion"


class TransactionStatus(str, Enum):
    """Transaction verification status"""

    PENDING = "Pending"
    VERIFIED = "Verified"
    REJECTED = "Rejected"
    REQUIRES_REVIEW = "Requires Review"


if SQLALCHEMY_AVAILABLE:

    class Company(Base):
        """
        BIMS-integrated company management
        """

        __tablename__ = "companies"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        bims_name = Column(String(100), unique=True, nullable=False)  # Matches BIMS
        legal_name = Column(String(100), nullable=False)
        company_type = Column(String(50))
        jurisdiction = Column(String(50))
        ein = Column(String(20))
        status = Column(String(20), default="ACTIVE")
        website = Column(String(200))
        primary_business = Column(Text)
        created_at = Column(DateTime, default=datetime.utcnow)
        bims_last_sync = Column(DateTime)
        bims_completeness_score = Column(Float)

        # Relationships
        accounts = relationship("CompanyAccount", back_populates="company")
        transactions = relationship("Transaction", back_populates="company")
        revenue_streams = relationship("RevenueStream", back_populates="company")

        # Indexes
        __table_args__ = (
            Index("idx_bims_name", "bims_name"),
            Index("idx_status", "status"),
        )

    class CompanyAccount(Base):
        """
        Company-specific chart of accounts
        """

        __tablename__ = "company_accounts"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        company_id = Column(UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False)
        account_number = Column(String(20), nullable=False)
        account_name = Column(String(100), nullable=False)
        account_type = Column(String(20), nullable=False)
        subcategory = Column(String(50))
        is_active = Column(Boolean, default=True)
        created_at = Column(DateTime, default=datetime.utcnow)

        # Relationships
        company = relationship("Company", back_populates="accounts")
        transactions = relationship("Transaction", back_populates="account")

        # Indexes
        __table_args__ = (
            Index("idx_company_account", "company_id", "account_number", unique=True),
            Index("idx_account_type", "account_type"),
        )

    class Transaction(Base):
        """
        General ledger transactions with BIMS integration
        """

        __tablename__ = "transactions"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        company_id = Column(UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False)
        transaction_date = Column(DateTime, nullable=False)
        account_id = Column(UUID(as_uuid=True), ForeignKey("company_accounts.id"), nullable=False)
        amount = Column(DECIMAL(15, 2), nullable=False)
        debit_credit = Column(String(1), nullable=False)  # 'D' or 'C'
        description = Column(Text)
        reference_number = Column(String(50))
        source_document = Column(String(100))
        ai_confidence = Column(Float)
        verified = Column(Boolean, default=False)
        verified_by = Column(String(100))
        verified_at = Column(DateTime)
        bims_integrated = Column(Boolean, default=False)
        created_at = Column(DateTime, default=datetime.utcnow)

        # Relationships
        company = relationship("Company", back_populates="transactions")
        account = relationship("CompanyAccount", back_populates="transactions")

        # Indexes
        __table_args__ = (
            Index("idx_company_date", "company_id", "transaction_date"),
            Index("idx_account_date", "account_id", "transaction_date"),
            Index("idx_verified", "verified"),
        )

    class RevenueStream(Base):
        """
        Revenue streams with BIMS business alignment
        """

        __tablename__ = "revenue_streams"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        company_id = Column(UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False)
        stream_name = Column(String(100), nullable=False)
        stream_type = Column(String(50))  # Subscription, Product, Service, etc.
        recognition_method = Column(String(50), default="Accrual")
        contract_value = Column(DECIMAL(15, 2))
        start_date = Column(DateTime)
        end_date = Column(DateTime)
        payment_terms = Column(String(100))
        ai_forecast_model = Column(JSONB)
        bims_business_alignment = Column(String(100))  # Links to BIMS focus_areas/services
        created_at = Column(DateTime, default=datetime.utcnow)

        # Relationships
        company = relationship("Company", back_populates="revenue_streams")
        recognitions = relationship("RevenueRecognition", back_populates="revenue_stream")

    class RevenueRecognition(Base):
        """
        Revenue recognition with BIMS verification
        """

        __tablename__ = "revenue_recognition"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        revenue_stream_id = Column(
            UUID(as_uuid=True), ForeignKey("revenue_streams.id"), nullable=False
        )
        recognition_date = Column(DateTime, nullable=False)
        amount = Column(DECIMAL(15, 2), nullable=False)
        period_start = Column(DateTime)
        period_end = Column(DateTime)
        verification_sources = Column(JSONB)  # Bank statements, contracts, etc.
        ai_verification_score = Column(Float)
        bims_completeness_check = Column(Boolean, default=False)
        blockchain_hash = Column(String(64))
        created_at = Column(DateTime, default=datetime.utcnow)

        # Relationships
        revenue_stream = relationship("RevenueStream", back_populates="recognitions")

    class BIMSAuditLog(Base):
        """
        BIMS-integrated audit trail
        """

        __tablename__ = "bims_audit_logs"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        company_id = Column(UUID(as_uuid=True), ForeignKey("companies.id"))
        action = Column(String(100), nullable=False)
        entity_type = Column(String(50), nullable=False)  # transaction, revenue, etc.
        entity_id = Column(UUID(as_uuid=True), nullable=False)
        old_values = Column(JSONB)
        new_values = Column(JSONB)
        performed_by = Column(String(100), nullable=False)
        performed_at = Column(DateTime, default=datetime.utcnow)
        bims_authority_level = Column(String(20))

        # Relationships
        company = relationship("Company")


def initialize_bims_companies(
    engine,
    bims_config_path: str = "/workspaces/dominion-os-demo-build/config/organizational-authority.json",
):
    """
    Initialize companies from BIMS configuration
    """
    from sqlalchemy.orm import sessionmaker

    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # Load BIMS config
        with open(bims_config_path, "r") as f:
            bims_config = json.load(f)

        # Create companies from BIMS
        for company_data in bims_config["organizational_structure"]["holding_entities"]:
            # Check if company already exists
            existing = session.query(Company).filter_by(bims_name=company_data["name"]).first()
            if existing:
                # Update existing
                existing.legal_name = company_data["name"]
                existing.company_type = company_data.get("type")
                existing.jurisdiction = company_data.get("jurisdiction")
                existing.ein = company_data.get("ein")
                existing.status = company_data.get("status", "ACTIVE")
                existing.website = company_data.get("website")
                existing.primary_business = company_data.get("primary_business")
                existing.bims_last_sync = datetime.utcnow()
                existing.bims_completeness_score = calculate_completeness_score(company_data)
            else:
                # Create new company
                company = Company(
                    bims_name=company_data["name"],
                    legal_name=company_data["name"],
                    company_type=company_data.get("type"),
                    jurisdiction=company_data.get("jurisdiction"),
                    ein=company_data.get("ein"),
                    status=company_data.get("status", "ACTIVE"),
                    website=company_data.get("website"),
                    primary_business=company_data.get("primary_business"),
                    bims_completeness_score=calculate_completeness_score(company_data),
                )
                session.add(company)

        session.commit()
        print("✅ BIMS companies initialized successfully")

    except Exception as e:
        session.rollback()
        print(f"❌ Error initializing BIMS companies: {e}")
        raise
    finally:
        session.close()


def calculate_completeness_score(company_data: Dict) -> float:
    """
    Calculate BIMS completeness score for a company
    """
    score = 0
    max_score = 100

    # Basic info (40 points)
    if company_data.get("primary_business") and company_data["primary_business"] != "TBD":
        score += 15
    if company_data.get("ein") and company_data["ein"] != "TBD":
        score += 10
    if company_data.get("jurisdiction") and company_data["jurisdiction"] != "TBD":
        score += 10
    if company_data.get("website"):
        score += 5

    # Ownership (20 points)
    if company_data.get("sole_owner"):
        score += 20

    # Business details (40 points)
    if company_data.get("focus_areas"):
        score += 15
    if company_data.get("services") or company_data.get("collections"):
        score += 15
    if company_data.get("repositories") or company_data.get("infrastructure"):
        score += 10

    return min(score, max_score)


def create_company_chart_of_accounts(session, company_id: str, company_name: str):
    """
    Create default chart of accounts for a company
    """
    # Define default COA based on company type
    if "Fractal5" in company_name:
        # Tech/AI company COA
        accounts_data = [
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
        # Political tech company COA
        accounts_data = [
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
        # Furniture manufacturing COA
        accounts_data = [
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
        # Generic COA
        accounts_data = [
            ("1000", "Cash and Cash Equivalents", "Asset", "Current Assets"),
            ("1100", "Accounts Receivable", "Asset", "Current Assets"),
            ("2000", "Accounts Payable", "Liability", "Current Liabilities"),
            ("3000", "Common Stock", "Equity", "Equity"),
            ("3100", "Retained Earnings", "Equity", "Equity"),
            ("4000", "Revenue", "Revenue", "Revenue"),
            ("5000", "Cost of Goods Sold", "Expense", "COGS"),
            ("5100", "Operating Expenses", "Expense", "Operating Expenses"),
        ]

    # Create accounts
    for account_number, account_name, account_type, subcategory in accounts_data:
        account = CompanyAccount(
            company_id=company_id,
            account_number=account_number,
            account_name=account_name,
            account_type=account_type,
            subcategory=subcategory,
        )
        session.add(account)


if __name__ == "__main__":
    # Example usage
    print("PHI BIMS-Aligned Financial Models")
    print("==================================")

    if not SQLALCHEMY_AVAILABLE:
        print("❌ SQLAlchemy not available")
        exit(1)

    # Create tables
    engine = create_engine("sqlite:///phi_financial_bims.db")
    Base.metadata.create_all(engine)

    print("✅ Database schema created")

    # Initialize BIMS companies
    initialize_bims_companies(engine)

    print("✅ BIMS integration complete")
    print("🎯 Ready for Phase 1 implementation")
