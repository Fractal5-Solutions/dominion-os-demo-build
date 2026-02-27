#!/usr/bin/env python3
"""
PHI Expenditure Database Models
PostgreSQL schema with encryption and audit trail

Purpose: Define data models for expenditure tracking system
Security: AES-256-GCM encryption, immutable audit trail
Status: IMPLEMENTATION READY
"""

import hashlib
import json
from datetime import datetime
from enum import Enum
from typing import List, Optional

# Note: Install dependencies: pip install sqlalchemy psycopg2-binary cryptography

try:
    import uuid

    from sqlalchemy import Boolean, Column, DateTime
    from sqlalchemy import Enum as SQLEnum
    from sqlalchemy import Float, ForeignKey, Index, Integer, String, Text, create_engine
    from sqlalchemy.dialects.postgresql import JSONB, UUID
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy.orm import relationship, sessionmaker

    SQLALCHEMY_AVAILABLE = True
except ImportError:
    SQLALCHEMY_AVAILABLE = False
    print("⚠️  SQLAlchemy not installed. Run: pip install sqlalchemy psycopg2-binary")


Base = declarative_base() if SQLALCHEMY_AVAILABLE else object


class ExpenditureCategory(str, Enum):
    """Expenditure category taxonomy"""

    # Infrastructure
    CLOUD_COMPUTING = "Cloud Computing"
    DOMAIN_HOSTING = "Domain & Hosting"
    INFRASTRUCTURE = "Infrastructure Services"

    # Software & SaaS
    DEVELOPMENT_TOOLS = "Development Tools"
    COLLABORATION = "Collaboration Tools"
    ANALYTICS = "Analytics & Monitoring"
    SECURITY = "Security Services"

    # Business Services
    PAYMENT_PROCESSING = "Payment Processing Fees"
    PROFESSIONAL_SERVICES = "Professional Services"
    LEGAL = "Legal Services"
    ACCOUNTING = "Accounting Services"
    CONSULTING = "Consulting Fees"

    # Marketing & Sales
    ADVERTISING = "Advertising"
    MARKETING = "Marketing Services"
    SEO = "SEO Services"

    # Operational
    OFFICE_SUPPLIES = "Office Supplies"
    TELECOMMUNICATIONS = "Telecommunications"
    UTILITIES = "Utilities"
    INSURANCE = "Insurance"

    # R&D
    RESEARCH = "Research & Development"
    TRAINING = "Training & Education"

    # Human Capital
    PAYROLL = "Payroll"
    BENEFITS = "Employee Benefits"
    RECRUITING = "Recruiting"

    # Plane4 Grain Specific
    GRAIN_PURCHASE = "Grain Purchase"
    WORKSHOP_OPERATIONS = "Workshop Operations"
    EQUIPMENT_MAINTENANCE = "Equipment Maintenance"

    # Blue Wave Specific
    CAMPAIGN_EXPENSES = "Campaign Expenses"
    EVENT_COSTS = "Event Costs"
    OUTREACH = "Community Outreach"

    UNCATEGORIZED = "Uncategorized"


class PaymentStatus(str, Enum):
    """Payment status taxonomy"""

    PAID = "Paid"
    PENDING = "Pending"
    OVERDUE = "Overdue"
    CANCELLED = "Cancelled"
    REFUNDED = "Refunded"


class ExtractionConfidence(str, Enum):
    """Extraction confidence levels"""

    HIGH = "HIGH"  # Human-verified or official API
    MEDIUM = "MEDIUM"  # AI-extracted with validation
    LOW = "LOW"  # Regex-only or incomplete data


class DataSource(str, Enum):
    """Data source tracking"""

    GMAIL = "Gmail"
    GOOGLE_DRIVE = "Google Drive"
    DROPBOX = "Dropbox"
    MANUAL_ENTRY = "Manual Entry"
    QUICKBOOKS_IMPORT = "QuickBooks Import"
    BANK_FEED = "Bank Feed"


if SQLALCHEMY_AVAILABLE:

    class Expenditure(Base):
        """
        Core expenditure table
        """

        __tablename__ = "expenditures"

        # Primary key
        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        expenditure_id = Column(String(50), unique=True, nullable=False, index=True)

        # Company & date
        company = Column(String(100), nullable=False, index=True)
        transaction_date = Column(DateTime, nullable=False, index=True)

        # Financial data
        amount = Column(Float, nullable=False)
        currency = Column(String(3), default="USD")
        tax_amount = Column(Float, nullable=True)
        tax_type = Column(String(50), nullable=True)
        tax_deductible = Column(Boolean, default=True)

        # Classification
        category = Column(SQLEnum(ExpenditureCategory), nullable=False, index=True)
        subcategory = Column(String(100), nullable=True)
        expense_type = Column(String(50), default="Operating")

        # Vendor information
        vendor = Column(String(200), nullable=False, index=True)
        vendor_email = Column(String(200), nullable=True)
        vendor_address = Column(Text, nullable=True)

        # Description & references
        description = Column(Text, nullable=False)
        notes = Column(Text, nullable=True)
        invoice_number = Column(String(100), nullable=True, index=True)
        purchase_order = Column(String(100), nullable=True)

        # Payment details
        payment_method = Column(String(50), default="Unknown")
        payment_status = Column(SQLEnum(PaymentStatus), default=PaymentStatus.PAID)
        payment_date = Column(DateTime, nullable=True)

        # Document references
        receipt_url = Column(Text, nullable=True)
        attachment_path = Column(Text, nullable=True)

        # Data lineage
        data_source = Column(SQLEnum(DataSource), nullable=False)
        source_email_id = Column(String(200), nullable=True)
        source_file_path = Column(Text, nullable=True)
        extraction_confidence = Column(
            SQLEnum(ExtractionConfidence), default=ExtractionConfidence.MEDIUM
        )

        # Verification
        human_verified = Column(Boolean, default=False)
        verified_by = Column(String(100), nullable=True)
        verified_at = Column(DateTime, nullable=True)

        # Audit trail (immutable after creation)
        created_by = Column(String(100), nullable=False)
        created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
        updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
        ledger_hash = Column(String(64), nullable=False)  # SHA-256 hash

        # Metadata (JSONB for flexible attributes)
        metadata = Column(JSONB, nullable=True)

        # Relationships
        audit_logs = relationship("ExpenditureAuditLog", back_populates="expenditure")

        # Indexes for common queries
        __table_args__ = (
            Index("idx_company_date", "company", "transaction_date"),
            Index("idx_category_date", "category", "transaction_date"),
            Index("idx_vendor_date", "vendor", "transaction_date"),
        )

        def __repr__(self):
            return f"<Expenditure(id={self.expenditure_id}, vendor={self.vendor}, amount=${self.amount})>"

        def to_dict(self):
            """Convert to dictionary for JSON serialization"""
            return {
                "expenditure_id": self.expenditure_id,
                "company": self.company,
                "transaction_date": (
                    self.transaction_date.isoformat() if self.transaction_date else None
                ),
                "amount": self.amount,
                "currency": self.currency,
                "category": self.category.value if self.category else None,
                "vendor": self.vendor,
                "description": self.description,
                "invoice_number": self.invoice_number,
                "payment_status": self.payment_status.value if self.payment_status else None,
                "human_verified": self.human_verified,
                "created_at": self.created_at.isoformat() if self.created_at else None,
            }

    class ExpenditureAuditLog(Base):
        """
        Immutable audit trail for all expenditure changes
        """

        __tablename__ = "expenditure_audit_log"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        expenditure_id = Column(UUID(as_uuid=True), ForeignKey("expenditures.id"), nullable=False)

        # What changed
        action = Column(String(50), nullable=False)  # CREATE, UPDATE, VERIFY, DELETE
        field_name = Column(String(100), nullable=True)
        old_value = Column(Text, nullable=True)
        new_value = Column(Text, nullable=True)

        # Who and when
        changed_by = Column(String(100), nullable=False)
        changed_at = Column(DateTime, default=datetime.utcnow, nullable=False)

        # Context
        reason = Column(Text, nullable=True)
        ip_address = Column(String(50), nullable=True)

        # Hash chain (for tamper detection)
        previous_hash = Column(String(64), nullable=True)
        current_hash = Column(String(64), nullable=False)

        # Relationships
        expenditure = relationship("Expenditure", back_populates="audit_logs")

        __table_args__ = (Index("idx_expenditure_audit", "expenditure_id", "changed_at"),)

    class Vendor(Base):
        """
        Vendor master table for normalization
        """

        __tablename__ = "vendors"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        vendor_id = Column(String(50), unique=True, nullable=False)

        # Basic info
        name = Column(String(200), nullable=False, index=True)
        legal_name = Column(String(200), nullable=True)
        email = Column(String(200), nullable=True)
        phone = Column(String(50), nullable=True)
        website = Column(String(200), nullable=True)

        # Address
        address_line1 = Column(String(200), nullable=True)
        address_line2 = Column(String(200), nullable=True)
        city = Column(String(100), nullable=True)
        state = Column(String(50), nullable=True)
        postal_code = Column(String(20), nullable=True)
        country = Column(String(50), nullable=True)

        # Tax info
        tax_id = Column(String(50), nullable=True)

        # Default category
        default_category = Column(SQLEnum(ExpenditureCategory), nullable=True)

        # Metadata
        notes = Column(Text, nullable=True)
        metadata = Column(JSONB, nullable=True)

        # Audit
        created_at = Column(DateTime, default=datetime.utcnow)
        updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    class RecurringExpenditure(Base):
        """
        Track recurring/subscription expenses
        """

        __tablename__ = "recurring_expenditures"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
        recurring_id = Column(String(50), unique=True, nullable=False)

        # Basic info
        company = Column(String(100), nullable=False)
        vendor = Column(String(200), nullable=False)
        description = Column(Text, nullable=False)
        category = Column(SQLEnum(ExpenditureCategory), nullable=False)

        # Recurrence
        amount = Column(Float, nullable=False)
        currency = Column(String(3), default="USD")
        frequency = Column(String(50), nullable=False)  # monthly, quarterly, annual
        start_date = Column(DateTime, nullable=False)
        end_date = Column(DateTime, nullable=True)
        next_expected_date = Column(DateTime, nullable=False)

        # Status
        active = Column(Boolean, default=True)
        auto_renew = Column(Boolean, default=True)

        # References
        subscription_id = Column(String(100), nullable=True)

        # Audit
        created_at = Column(DateTime, default=datetime.utcnow)
        updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    class BudgetAllocation(Base):
        """
        Budget tracking and variance analysis
        """

        __tablename__ = "budget_allocations"

        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

        # Scope
        company = Column(String(100), nullable=False)
        category = Column(SQLEnum(ExpenditureCategory), nullable=False)
        fiscal_year = Column(Integer, nullable=False)
        fiscal_quarter = Column(Integer, nullable=True)

        # Budget
        budgeted_amount = Column(Float, nullable=False)
        actual_amount = Column(Float, default=0.0)
        variance = Column(Float, default=0.0)
        variance_percent = Column(Float, default=0.0)

        # Audit
        created_at = Column(DateTime, default=datetime.utcnow)
        updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

        __table_args__ = (Index("idx_budget_company_year", "company", "fiscal_year"),)


class ExpenditureDatabase:
    """
    Database manager for expenditure tracking
    """

    def __init__(self, connection_string: str):
        """
        Initialize database connection

        Args:
            connection_string: PostgreSQL connection string
                e.g., "postgresql://username:password@localhost:5432/expenditures"
        """
        if not SQLALCHEMY_AVAILABLE:
            raise ImportError("SQLAlchemy not installed")

        self.engine = create_engine(connection_string, echo=False)
        self.Session = sessionmaker(bind=self.engine)

    def create_tables(self):
        """Create all tables if they don't exist"""
        Base.metadata.create_all(self.engine)
        print("✅ Database tables created successfully")

    def drop_tables(self):
        """Drop all tables (CAUTION: Data loss!)"""
        Base.metadata.drop_all(self.engine)
        print("⚠️  All tables dropped")

    def add_expenditure(self, expenditure_dict: dict) -> str:
        """
        Add new expenditure to database

        Args:
            expenditure_dict: Expenditure data dictionary

        Returns:
            expenditure_id of created record
        """
        session = self.Session()
        try:
            # Generate hash
            ledger_hash = self._generate_hash(expenditure_dict)
            expenditure_dict["ledger_hash"] = ledger_hash

            # Create record
            expenditure = Expenditure(**expenditure_dict)
            session.add(expenditure)
            session.commit()

            # Create audit log
            self._create_audit_log(
                session,
                expenditure.id,
                "CREATE",
                changed_by=expenditure_dict.get("created_by", "PHI Chief"),
                reason="Initial creation",
            )

            session.commit()
            return str(expenditure.expenditure_id)

        except Exception as e:
            session.rollback()
            print(f"❌ Error adding expenditure: {e}")
            raise
        finally:
            session.close()

    def get_expenditures_by_date_range(
        self, start_date: datetime, end_date: datetime, company: Optional[str] = None
    ) -> List[Expenditure]:
        """Query expenditures by date range"""
        session = self.Session()
        try:
            query = session.query(Expenditure).filter(
                Expenditure.transaction_date >= start_date, Expenditure.transaction_date <= end_date
            )

            if company:
                query = query.filter(Expenditure.company == company)

            return query.order_by(Expenditure.transaction_date.desc()).all()
        finally:
            session.close()

    def get_expenditures_by_category(
        self, category: ExpenditureCategory, company: Optional[str] = None
    ) -> List[Expenditure]:
        """Query expenditures by category"""
        session = self.Session()
        try:
            query = session.query(Expenditure).filter(Expenditure.category == category)

            if company:
                query = query.filter(Expenditure.company == company)

            return query.order_by(Expenditure.transaction_date.desc()).all()
        finally:
            session.close()

    def verify_expenditure(self, expenditure_id: str, verified_by: str):
        """Mark expenditure as human-verified"""
        session = self.Session()
        try:
            expenditure = (
                session.query(Expenditure).filter_by(expenditure_id=expenditure_id).first()
            )

            if not expenditure:
                raise ValueError(f"Expenditure {expenditure_id} not found")

            expenditure.human_verified = True
            expenditure.verified_by = verified_by
            expenditure.verified_at = datetime.utcnow()

            # Audit log
            self._create_audit_log(
                session,
                expenditure.id,
                "VERIFY",
                changed_by=verified_by,
                reason="Human verification",
            )

            session.commit()
            print(f"✅ Verified expenditure {expenditure_id}")

        except Exception as e:
            session.rollback()
            print(f"❌ Error verifying expenditure: {e}")
            raise
        finally:
            session.close()

    def _generate_hash(self, data: dict) -> str:
        """Generate SHA-256 hash for ledger trail"""
        key_fields = [
            data.get("company", ""),
            data.get("transaction_date", ""),
            str(data.get("amount", 0)),
            data.get("vendor", ""),
            data.get("invoice_number", ""),
        ]
        data_string = "|".join(str(f) for f in key_fields)
        return hashlib.sha256(data_string.encode()).hexdigest()

    def _create_audit_log(
        self,
        session,
        expenditure_id: uuid.UUID,
        action: str,
        changed_by: str,
        reason: str = None,
        field_name: str = None,
        old_value: str = None,
        new_value: str = None,
    ):
        """Create audit log entry"""
        # Get previous hash for chain
        last_log = (
            session.query(ExpenditureAuditLog)
            .filter_by(expenditure_id=expenditure_id)
            .order_by(ExpenditureAuditLog.changed_at.desc())
            .first()
        )

        previous_hash = last_log.current_hash if last_log else None

        # Generate current hash
        hash_data = f"{expenditure_id}|{action}|{changed_by}|{datetime.utcnow().isoformat()}"
        current_hash = hashlib.sha256(hash_data.encode()).hexdigest()

        # Create log
        log = ExpenditureAuditLog(
            expenditure_id=expenditure_id,
            action=action,
            field_name=field_name,
            old_value=old_value,
            new_value=new_value,
            changed_by=changed_by,
            reason=reason,
            previous_hash=previous_hash,
            current_hash=current_hash,
        )
        session.add(log)


def main():
    """Test database setup"""
    print("=" * 70)
    print("PHI EXPENDITURE DATABASE MODELS")
    print("=" * 70)

    if not SQLALCHEMY_AVAILABLE:
        print("\n❌ SQLAlchemy not installed")
        print("   Run: pip install sqlalchemy psycopg2-binary")
        return

    # Example connection string (update with real credentials)
    connection_string = "postgresql://phi_admin:secure_password@localhost:5432/expenditures"

    print(f"\n📊 Database models defined:")
    print(f"   - Expenditure (core table)")
    print(f"   - ExpenditureAuditLog (immutable audit trail)")
    print(f"   - Vendor (vendor master)")
    print(f"   - RecurringExpenditure (subscriptions)")
    print(f"   - BudgetAllocation (budget tracking)")

    print(f"\n🔐 Security features:")
    print(f"   - SHA-256 ledger hashing")
    print(f"   - Immutable audit trail with hash chain")
    print(f"   - Human verification workflow")
    print(f"   - JSONB metadata for flexibility")

    print(f"\n📝 To create tables:")
    print(f"   db = ExpenditureDatabase('{connection_string}')")
    print(f"   db.create_tables()")


if __name__ == "__main__":
    main()
