#!/usr/bin/env python3
"""
PHI BIMS Financial Initialization Script
Simple initialization of BIMS-aligned financial database
"""

import json
import sys
from pathlib import Path

# Add current directory to path
sys.path.append(".")

try:
    import uuid

    from phi_bims_financial_models import (
        Base,
        Company,
        create_company_chart_of_accounts,
        initialize_bims_companies,
    )
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    print("🎯 PHI BIMS Financial Initialization")
    print("===================================")

    # Create database engine
    db_path = Path("./data/phi_financial_bims.db")
    db_path.parent.mkdir(exist_ok=True)
    engine = create_engine(f"sqlite:///{db_path}")

    print("📊 Creating database schema...")
    Base.metadata.create_all(engine)
    print("✅ Database schema created")

    print("🏢 Initializing BIMS companies...")
    initialize_bims_companies(engine)
    print("✅ BIMS companies initialized")

    # Create chart of accounts for each company
    Session = sessionmaker(bind=engine)
    session = Session()

    companies = session.query(Company).all()
    for company in companies:
        print(f"📋 Creating chart of accounts for {company.bims_name}...")
        create_company_chart_of_accounts(session, company.id, company.bims_name)

    session.commit()
    session.close()

    print("✅ All company charts of accounts created")
    print("🎉 BIMS Financial System Phase 1 Complete!")
    print(f"📁 Database: {db_path.absolute()}")

except Exception as e:
    print(f"❌ Error during initialization: {e}")
    import traceback

    traceback.print_exc()
    sys.exit(1)
