#!/usr/bin/env python3
"""
PHI Expenditure System - Sample Data Generator
Generates realistic test data for dashboard development and testing.

Usage:
    python3 generate_sample_data.py [--count 100]
"""

import os
import sys
import random
from datetime import datetime, timedelta
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from expenditure_models import ExpenditureDatabase, Expenditure, RecurringExpenditure

# Sample vendors by category
VENDORS = {
    "Cloud Services": [
        ("Google Cloud Platform", "billing@google.com", 500, 15000),
        ("Amazon Web Services", "aws-billing@amazon.com", 800, 20000),
        ("Microsoft Azure", "azure-billing@microsoft.com", 600, 12000),
        ("DigitalOcean", "billing@digitalocean.com", 50, 500),
        ("Cloudflare", "billing@cloudflare.com", 20, 200),
    ],
    "Software Subscriptions": [
        ("GitHub Enterprise", "billing@github.com", 200, 800),
        ("Atlassian (Jira/Confluence)", "billing@atlassian.com", 150, 600),
        ("Adobe Creative Cloud", "billing@adobe.com", 80, 300),
        ("JetBrains", "sales@jetbrains.com", 50, 200),
        ("Slack", "feedback@slack.com", 100, 400),
    ],
    "Marketing & Advertising": [
        ("Google Ads", "support@google.com", 1000, 10000),
        ("Facebook Ads", "ads@facebook.com", 500, 5000),
        ("LinkedIn Ads", "advertising@linkedin.com", 300, 3000),
        ("Twitter Ads", "ads@twitter.com", 200, 2000),
    ],
    "Professional Services": [
        ("Legal Services - Smith & Associates", "billing@smithlaw.ca", 1500, 8000),
        ("Accounting - CPA Firm", "info@cpafirm.ca", 1000, 5000),
        ("HR Consulting", "contact@hrconsult.ca", 800, 4000),
        ("IT Support - TechCorp", "support@techcorp.ca", 500, 3000),
    ],
    "Office & Facilities": [
        ("WeWork", "billing@wework.com", 2000, 8000),
        ("Staples Business", "business@staples.ca", 100, 500),
        ("Office Depot", "orders@officedepot.ca", 80, 400),
    ],
    "Telecommunications": [
        ("Rogers Business", "business@rogers.com", 200, 800),
        ("Bell Canada", "business@bell.ca", 150, 600),
        ("Telus", "business@telus.com", 180, 700),
    ],
    "Insurance": [
        ("Manulife Financial", "business@manulife.com", 500, 2000),
        ("Sun Life", "business@sunlife.ca", 450, 1800),
    ],
    "Domain & Hosting": [
        ("GoDaddy", "billing@godaddy.com", 50, 300),
        ("Namecheap", "billing@namecheap.com", 30, 150),
    ],
}

COMPANIES = [
    "Fractal5 Solutions Inc",
    "Blue Wave Action Group Inc",
    "Plane4 Grain Inc"
]

PAYMENT_METHODS = ["Credit Card", "Bank Transfer", "PayPal", "Cheque"]
PAYMENT_STATUSES = ["Paid", "Pending", "Overdue"]
CONFIDENCES = ["HIGH", "HIGH", "HIGH", "MEDIUM", "MEDIUM", "LOW"]  # Weighted


def generate_expenditures(db, count=100):
    """Generate sample expenditure data."""

    print(f"🎲 Generating {count} sample expenditures...")
    print()

    expenditures_created = 0

    for i in range(count):
        # Random date within last 12 months
        days_ago = random.randint(0, 365)
        date = datetime.now() - timedelta(days=days_ago)

        # Random company
        company = random.choice(COMPANIES)

        # Random category and vendor
        category = random.choice(list(VENDORS.keys()))
        vendor_name, vendor_email, min_amount, max_amount = random.choice(VENDORS[category])

        # Random amount within vendor's typical range
        amount = round(random.uniform(min_amount, max_amount), 2)

        # Calculate tax (13% HST for Ontario)
        tax_amount = round(amount * 0.13, 2) if random.random() > 0.2 else None

        # Confidence (mostly HIGH, some MEDIUM/LOW)
        confidence = random.choice(CONFIDENCES)

        # Verified status (unverified if LOW confidence)
        verified = confidence != "LOW" and random.random() > 0.3

        # Generate invoice number
        invoice_number = f"{vendor_name.split()[0].upper()}-{random.randint(10000, 99999)}"

        # Create expenditure
        exp = Expenditure(
            company=company,
            date=date.date(),
            amount=amount,
            currency="CAD",
            vendor=vendor_name,
            vendor_email=vendor_email,
            category=category,
            description=f"{category} - {vendor_name}",
            invoice_number=invoice_number,
            payment_method=random.choice(PAYMENT_METHODS),
            payment_status=random.choice(PAYMENT_STATUSES),
            tax_amount=tax_amount,
            tax_type="HST" if tax_amount else None,
            tax_deductible=True,
            data_source="SAMPLE_DATA",
            source_email_id=f"sample_{i}@test.com",
            confidence=confidence,
            verified=verified,
            verified_by="Matthew Dillon" if verified else None,
            verified_at=datetime.now() if verified else None,
            notes=f"Sample expenditure #{i+1}",
            created_by="sample_data_generator"
        )

        db.session.add(exp)
        expenditures_created += 1

        if (i + 1) % 20 == 0:
            print(f"  ✓ Created {i+1}/{count} expenditures...")

    db.session.commit()
    print()
    print(f"✅ Created {expenditures_created} expenditures")
    return expenditures_created


def generate_recurring_expenses(db, count=15):
    """Generate sample recurring expense data."""

    print()
    print(f"🔄 Generating {count} recurring expenses...")
    print()

    recurring_vendors = [
        ("Google Workspace", "billing@google.com", "Cloud Services", 150, "MONTHLY"),
        ("Microsoft 365", "billing@microsoft.com", "Software Subscriptions", 200, "MONTHLY"),
        ("Slack Business+", "billing@slack.com", "Software Subscriptions", 120, "MONTHLY"),
        ("AWS Reserved Instances", "aws-billing@amazon.com", "Cloud Services", 2500, "MONTHLY"),
        ("GitHub Enterprise", "billing@github.com", "Software Subscriptions", 250, "MONTHLY"),
        ("Adobe Creative Cloud", "billing@adobe.com", "Software Subscriptions", 80, "MONTHLY"),
        ("Atlassian Cloud", "billing@atlassian.com", "Software Subscriptions", 150, "MONTHLY"),
        ("WeWork Office Space", "billing@wework.com", "Office & Facilities", 3500, "MONTHLY"),
        ("Rogers Business Internet", "business@rogers.com", "Telecommunications", 200, "MONTHLY"),
        ("Manulife Insurance", "business@manulife.com", "Insurance", 800, "MONTHLY"),
        ("Legal Retainer", "billing@smithlaw.ca", "Professional Services", 2000, "MONTHLY"),
        ("Domain Renewal", "billing@godaddy.com", "Domain & Hosting", 50, "ANNUAL"),
        ("SSL Certificates", "billing@namecheap.com", "Domain & Hosting", 100, "ANNUAL"),
        ("Google Ads Budget", "support@google.com", "Marketing & Advertising", 5000, "MONTHLY"),
        ("CRM Software", "billing@salesforce.com", "Software Subscriptions", 300, "MONTHLY"),
    ]

    recurring_created = 0

    for i in range(min(count, len(recurring_vendors))):
        vendor_name, vendor_email, category, amount, frequency = recurring_vendors[i]
        company = random.choice(COMPANIES)

        # Calculate next expected based on frequency
        if frequency == "MONTHLY":
            next_expected = datetime.now() + timedelta(days=random.randint(1, 30))
        elif frequency == "QUARTERLY":
            next_expected = datetime.now() + timedelta(days=random.randint(1, 90))
        else:  # ANNUAL
            next_expected = datetime.now() + timedelta(days=random.randint(1, 365))

        rec = RecurringExpenditure(
            company=company,
            vendor=vendor_name,
            vendor_email=vendor_email,
            category=category,
            description=f"{frequency.capitalize()} subscription - {vendor_name}",
            amount=amount,
            currency="CAD",
            frequency=frequency,
            start_date=datetime.now() - timedelta(days=random.randint(30, 365)),
            next_expected=next_expected.date(),
            active=True,
            auto_renew=random.random() > 0.3,
            created_by="sample_data_generator"
        )

        db.session.add(rec)
        recurring_created += 1

    db.session.commit()
    print(f"✅ Created {recurring_created} recurring expenses")
    return recurring_created


def print_summary(db):
    """Print summary statistics of generated data."""

    print()
    print("=" * 70)
    print("📊 DATABASE SUMMARY")
    print("=" * 70)
    print()

    # Total expenditures
    total_exp = db.session.query(Expenditure).count()
    print(f"Total Expenditures: {total_exp}")

    # By company
    print()
    print("By Company:")
    for company in COMPANIES:
        count = db.session.query(Expenditure).filter_by(company=company).count()
        total = db.session.query(Expenditure).filter_by(company=company).sum(Expenditure.amount) or 0
        print(f"  • {company}: {count} ({total:,.2f} CAD)")

    # By verification status
    print()
    verified_count = db.session.query(Expenditure).filter_by(verified=True).count()
    unverified_count = db.session.query(Expenditure).filter_by(verified=False).count()
    print(f"Verified: {verified_count}")
    print(f"Pending Verification: {unverified_count}")

    # By confidence
    print()
    print("By Confidence:")
    for conf in ["HIGH", "MEDIUM", "LOW"]:
        count = db.session.query(Expenditure).filter_by(confidence=conf).count()
        print(f"  • {conf}: {count}")

    # Recurring expenses
    print()
    recurring_count = db.session.query(RecurringExpenditure).filter_by(active=True).count()
    print(f"Active Recurring Expenses: {recurring_count}")

    print()


def main():
    """Main function."""

    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description='Generate sample expenditure data')
    parser.add_argument('--count', type=int, default=100, help='Number of expenditures to generate')
    parser.add_argument('--recurring', type=int, default=15, help='Number of recurring expenses')
    args = parser.parse_args()

    print()
    print("=" * 70)
    print("PHI EXPENDITURE SYSTEM - SAMPLE DATA GENERATOR")
    print("=" * 70)
    print()

    # Get database connection
    db_connection = os.environ.get(
        'EXPENDITURE_DB',
        'postgresql://phi_admin:secure_password@localhost:5432/expenditures'
    )

    try:
        print("🔌 Connecting to database...")
        db = ExpenditureDatabase(db_connection)
        print("✓ Connected")
        print()

        # Generate data
        generate_expenditures(db, args.count)
        generate_recurring_expenses(db, args.recurring)

        # Print summary
        print_summary(db)

        print("=" * 70)
        print("✅ SAMPLE DATA GENERATION COMPLETE")
        print("=" * 70)
        print()
        print("Next: Launch dashboard with `python3 expenditure_dashboard.py`")
        print()

        return 0

    except Exception as e:
        print()
        print(f"❌ ERROR: {e}")
        print()
        return 1


if __name__ == '__main__':
    sys.exit(main())
