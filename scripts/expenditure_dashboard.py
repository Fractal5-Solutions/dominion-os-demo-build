#!/usr/bin/env python3
"""
PHI Expenditure Tracking Dashboard
Web interface for financial data visualization and verification

Purpose: Real-time expenditure monitoring, human verification, reporting
Tech Stack: Flask + Bootstrap + Chart.js
Status: IMPLEMENTATION READY
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

from flask import Flask, jsonify, render_template, request, send_file

# Import expenditure models
try:
    from expenditure_exports import export_to_csv, export_to_quickbooks
    from expenditure_models import (
        SQLALCHEMY_AVAILABLE,
        ExpenditureCategory,
        ExpenditureDatabase,
        ExtractionConfidence,
        PaymentStatus,
    )

    MODELS_AVAILABLE = True
except ImportError:
    MODELS_AVAILABLE = False
    print("⚠️  expenditure_models not available")

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("FLASK_SECRET_KEY", "phi-dominion-os-2026")

# Database connection (configure in environment)
# NOTE: Default includes password for local dev only - DEMO_MODE bypasses database entirely
DB_CONNECTION = os.environ.get(
    "EXPENDITURE_DB",
    "postgresql://phi_admin:secure_password@localhost:5432/expenditures",
)

# Initialize database if available
db = None
DEMO_MODE = os.environ.get("DEMO_MODE", "true").lower() == "true"

if MODELS_AVAILABLE and not DEMO_MODE:
    try:
        db = ExpenditureDatabase(DB_CONNECTION)
        print("✅ Database connected")
    except Exception as e:
        print(f"⚠️  Database connection failed: {e}")
        print("💡 Running in DEMO_MODE - API endpoints will return sample data")
        DEMO_MODE = True
else:
    print("💡 Running in DEMO_MODE - API endpoints will return sample data")
    DEMO_MODE = True


# ============================================================================
# DEMO DATA GENERATOR
# ============================================================================


def generate_demo_summary():
    """Generate sample summary data for demo mode"""
    now = datetime.now()
    return {
        "current_month": {
            "total": 45678.90,
            "count": 142,
            "month": now.strftime("%B %Y"),
        },
        "ytd": {"total": 523456.78, "count": 1847},
        "top_vendors": [
            {"vendor": "AWS", "amount": 89234.50},
            {"vendor": "Microsoft Azure", "amount": 67890.25},
            {"vendor": "Google Cloud", "amount": 45678.30},
            {"vendor": "GitHub", "amount": 23456.00},
            {"vendor": "Atlassian", "amount": 12345.67},
        ],
        "by_category": [
            {"category": "Cloud Services", "amount": 202803.05},
            {"category": "Software Licenses", "amount": 145678.90},
            {"category": "Professional Services", "amount": 89234.56},
            {"category": "Hardware", "amount": 45678.12},
            {"category": "Office Supplies", "amount": 23456.78},
            {"category": "Marketing", "amount": 16605.37},
        ],
        "by_company": [
            {"company": "Fractal5Solutions", "amount": 345678.90},
            {"company": "TechStartupCo", "amount": 123456.78},
            {"company": "InnovateNow", "amount": 54321.10},
        ],
        "verification": {"verified": 1234, "pending": 613, "percent_verified": 66.8},
    }


def generate_demo_expenditures(limit=100):
    """Generate sample expenditure data for demo mode"""
    vendors = [
        "AWS",
        "Microsoft",
        "Google Cloud",
        "GitHub",
        "Atlassian",
        "Stripe",
        "Twilio",
        "SendGrid",
    ]
    categories = [
        "Cloud Services",
        "Software Licenses",
        "Professional Services",
        "Hardware",
        "Office Supplies",
    ]
    companies = ["Fractal5Solutions", "TechStartupCo", "InnovateNow"]

    expenditures = []
    for i in range(min(limit, 100)):
        days_ago = i * 2
        expenditures.append(
            {
                "id": f"EXP-{1000+i:04d}",
                "company": companies[i % len(companies)],
                "date": (datetime.now() - timedelta(days=days_ago)).strftime("%Y-%m-%d"),
                "amount": round(100 + (i * 123.45) % 5000, 2),
                "currency": "USD",
                "category": categories[i % len(categories)],
                "vendor": vendors[i % len(vendors)],
                "description": f"Sample transaction {i+1} for demo purposes",
                "invoice_number": f"INV-{2000+i:04d}",
                "status": "paid" if i % 3 == 0 else "pending",
                "verified": i % 4 == 0,
                "confidence": "high" if i % 2 == 0 else "medium",
            }
        )
    return expenditures


# ============================================================================
# HOME / DASHBOARD
# ============================================================================


@app.route("/")
def index():
    """Main dashboard view"""
    return render_template("dashboard.html")


@app.route("/health")
def health():
    """Health check endpoint for container orchestration"""
    return (
        jsonify(
            {
                "status": "healthy",
                "demo_mode": DEMO_MODE,
                "database_available": db is not None,
                "models_available": MODELS_AVAILABLE,
            }
        ),
        200,
    )


@app.route("/api/summary")
def api_summary():
    """
    Get dashboard summary statistics

    Returns:
        JSON with current month spend, YTD, top vendors, category breakdown
    """
    if DEMO_MODE:
        return jsonify(generate_demo_summary())

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        # Current month
        now = datetime.now()
        month_start = datetime(now.year, now.month, 1)
        month_end = (
            datetime(now.year, now.month + 1, 1) if now.month < 12 else datetime(now.year + 1, 1, 1)
        )

        current_month_expenses = db.get_expenditures_by_date_range(month_start, month_end)

        # YTD
        year_start = datetime(now.year, 1, 1)
        ytd_expenses = db.get_expenditures_by_date_range(year_start, now)

        # Calculate totals
        current_month_total = sum(exp.amount for exp in current_month_expenses)
        ytd_total = sum(exp.amount for exp in ytd_expenses)

        # Top vendors (YTD)
        vendor_totals = {}
        for exp in ytd_expenses:
            vendor_totals[exp.vendor] = vendor_totals.get(exp.vendor, 0) + exp.amount

        top_vendors = sorted(vendor_totals.items(), key=lambda x: x[1], reverse=True)[:10]

        # Category breakdown (YTD)
        category_totals = {}
        for exp in ytd_expenses:
            cat = exp.category.value if exp.category else "Uncategorized"
            category_totals[cat] = category_totals.get(cat, 0) + exp.amount

        # By company (YTD)
        company_totals = {}
        for exp in ytd_expenses:
            company_totals[exp.company] = company_totals.get(exp.company, 0) + exp.amount

        # Verification status
        verified_count = sum(1 for exp in ytd_expenses if exp.human_verified)
        pending_count = len(ytd_expenses) - verified_count

        return jsonify(
            {
                "current_month": {
                    "total": round(current_month_total, 2),
                    "count": len(current_month_expenses),
                    "month": now.strftime("%B %Y"),
                },
                "ytd": {"total": round(ytd_total, 2), "count": len(ytd_expenses)},
                "top_vendors": [{"vendor": v, "amount": round(a, 2)} for v, a in top_vendors],
                "by_category": [
                    {"category": c, "amount": round(a, 2)}
                    for c, a in sorted(category_totals.items(), key=lambda x: x[1], reverse=True)
                ],
                "by_company": [
                    {"company": c, "amount": round(a, 2)} for c, a in company_totals.items()
                ],
                "verification": {
                    "verified": verified_count,
                    "pending": pending_count,
                    "percent_verified": round(
                        (verified_count / len(ytd_expenses) * 100) if ytd_expenses else 0,
                        1,
                    ),
                },
            }
        )

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# EXPENDITURE LIST & DETAILS
# ============================================================================


@app.route("/expenditures")
def expenditures_list():
    """List all expenditures with filters"""
    return render_template("expenditures.html")


@app.route("/api/expenditures")
def api_expenditures():
    """
    Get expenditures with optional filters

    Query params:
        start_date: YYYY-MM-DD
        end_date: YYYY-MM-DD
        company: Company name
        category: Category name
        verified: true/false/all
        limit: Number of results
    """
    if DEMO_MODE:
        limit = int(request.args.get("limit", 100))
        expenditures = generate_demo_expenditures(limit)
        return jsonify({"expenditures": expenditures, "count": len(expenditures)})

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        # Parse query parameters
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")
        company = request.args.get("company")
        category_str = request.args.get("category")
        verified_filter = request.args.get("verified", "all")
        limit = int(request.args.get("limit", 100))

        # Default to last 90 days if no date range specified
        if not end_date_str:
            end_date = datetime.now()
        else:
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d")

        if not start_date_str:
            start_date = end_date - timedelta(days=90)
        else:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")

        # Query database
        expenditures = db.get_expenditures_by_date_range(start_date, end_date, company)

        # Apply filters
        if category_str:
            expenditures = [
                exp for exp in expenditures if exp.category and exp.category.value == category_str
            ]

        if verified_filter == "true":
            expenditures = [exp for exp in expenditures if exp.human_verified]
        elif verified_filter == "false":
            expenditures = [exp for exp in expenditures if not exp.human_verified]

        # Limit results
        expenditures = expenditures[:limit]

        # Convert to JSON
        results = [
            {
                "id": exp.expenditure_id,
                "company": exp.company,
                "date": exp.transaction_date.strftime("%Y-%m-%d"),
                "amount": round(exp.amount, 2),
                "currency": exp.currency,
                "category": exp.category.value if exp.category else None,
                "vendor": exp.vendor,
                "description": (
                    exp.description[:100] + "..." if len(exp.description) > 100 else exp.description
                ),
                "invoice_number": exp.invoice_number,
                "status": exp.payment_status.value if exp.payment_status else None,
                "verified": exp.human_verified,
                "confidence": (
                    exp.extraction_confidence.value if exp.extraction_confidence else None
                ),
            }
            for exp in expenditures
        ]

        return jsonify({"expenditures": results, "count": len(results)})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/expenditures/<expenditure_id>")
def api_expenditure_detail(expenditure_id: str):
    """Get detailed information for a specific expenditure"""
    if DEMO_MODE:
        demo_exp = generate_demo_expenditures(1)[0]
        demo_exp["id"] = expenditure_id
        demo_exp["extra_metadata"] = {"source": "demo", "note": "Sample data for demonstration"}
        return jsonify(demo_exp)

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        session = db.Session()
        from expenditure_models import Expenditure

        expenditure = session.query(Expenditure).filter_by(expenditure_id=expenditure_id).first()

        if not expenditure:
            return jsonify({"error": "Expenditure not found"}), 404

        result = {
            "id": expenditure.expenditure_id,
            "company": expenditure.company,
            "date": expenditure.transaction_date.strftime("%Y-%m-%d %H:%M:%S"),
            "amount": round(expenditure.amount, 2),
            "currency": expenditure.currency,
            "category": expenditure.category.value if expenditure.category else None,
            "subcategory": expenditure.subcategory,
            "vendor": expenditure.vendor,
            "vendor_email": expenditure.vendor_email,
            "description": expenditure.description,
            "notes": expenditure.notes,
            "invoice_number": expenditure.invoice_number,
            "payment_method": expenditure.payment_method,
            "payment_status": (
                expenditure.payment_status.value if expenditure.payment_status else None
            ),
            "tax_amount": expenditure.tax_amount,
            "tax_type": expenditure.tax_type,
            "tax_deductible": expenditure.tax_deductible,
            "receipt_url": expenditure.receipt_url,
            "data_source": expenditure.data_source.value if expenditure.data_source else None,
            "source_email_id": expenditure.source_email_id,
            "confidence": (
                expenditure.extraction_confidence.value
                if expenditure.extraction_confidence
                else None
            ),
            "verified": expenditure.human_verified,
            "verified_by": expenditure.verified_by,
            "verified_at": (
                expenditure.verified_at.strftime("%Y-%m-%d %H:%M:%S")
                if expenditure.verified_at
                else None
            ),
            "created_by": expenditure.created_by,
            "created_at": expenditure.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "ledger_hash": expenditure.ledger_hash,
            "metadata": expenditure.metadata,
        }

        session.close()
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# VERIFICATION WORKFLOW
# ============================================================================


@app.route("/verify")
def verify_page():
    """Human verification interface"""
    return render_template("verify.html")


@app.route("/api/pending_verification")
def api_pending_verification():
    """Get expenditures pending human verification"""
    if DEMO_MODE:
        pending = [exp for exp in generate_demo_expenditures(50) if not exp["verified"]]
        return jsonify({"pending": pending, "count": len(pending)})

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        session = db.Session()
        from expenditure_models import Expenditure

        # Get unverified expenditures with LOW confidence
        pending = (
            session.query(Expenditure)
            .filter(
                Expenditure.human_verified == False,
                Expenditure.extraction_confidence == ExtractionConfidence.LOW,
            )
            .order_by(Expenditure.amount.desc())  # High-value first
            .limit(50)
            .all()
        )

        results = [
            {
                "id": exp.expenditure_id,
                "company": exp.company,
                "date": exp.transaction_date.strftime("%Y-%m-%d"),
                "amount": round(exp.amount, 2),
                "vendor": exp.vendor,
                "description": exp.description[:150],
                "invoice_number": exp.invoice_number,
                "confidence": exp.extraction_confidence.value,
            }
            for exp in pending
        ]

        session.close()
        return jsonify({"pending": results, "count": len(results)})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/verify/<expenditure_id>", methods=["POST"])
def api_verify(expenditure_id: str):
    """
    Mark expenditure as verified

    Request body:
        {
            "verified_by": "Matthew Dillon",
            "updates": {optional field updates}
        }
    """
    if DEMO_MODE:
        return jsonify(
            {
                "success": True,
                "message": "Demo mode: verification simulated",
                "expenditure_id": expenditure_id,
            }
        )

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        data = request.get_json()
        verified_by = data.get("verified_by", "Unknown")
        updates = data.get("updates", {})

        # Apply any field updates before verification
        if updates:
            session = db.Session()
            from expenditure_models import Expenditure

            expenditure = (
                session.query(Expenditure).filter_by(expenditure_id=expenditure_id).first()
            )

            if expenditure:
                for field, value in updates.items():
                    if hasattr(expenditure, field):
                        setattr(expenditure, field, value)

                session.commit()
            session.close()

        # Verify
        db.verify_expenditure(expenditure_id, verified_by)

        return jsonify({"success": True, "message": "Expenditure verified"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# REPORTS
# ============================================================================


@app.route("/reports")
def reports_page():
    """Reports and exports page"""
    return render_template("reports.html")


@app.route("/api/report/category")
def api_report_category():
    """
    Category spending report

    Query params:
        start_date: YYYY-MM-DD
        end_date: YYYY-MM-DD
        company: Optional company filter
    """
    if DEMO_MODE:
        demo_summary = generate_demo_summary()
        return jsonify({"categories": demo_summary["by_category"]})

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")
        company = request.args.get("company")

        # Default to current year if not specified
        if not end_date_str:
            end_date = datetime.now()
        else:
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d")

        if not start_date_str:
            start_date = datetime(end_date.year, 1, 1)
        else:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")

        # Get expenditures
        expenditures = db.get_expenditures_by_date_range(start_date, end_date, company)

        # Aggregate by category
        category_data = {}
        for exp in expenditures:
            cat = exp.category.value if exp.category else "Uncategorized"
            if cat not in category_data:
                category_data[cat] = {"total": 0, "count": 0, "items": []}

            category_data[cat]["total"] += exp.amount
            category_data[cat]["count"] += 1
            category_data[cat]["items"].append(
                {
                    "date": exp.transaction_date.strftime("%Y-%m-%d"),
                    "vendor": exp.vendor,
                    "amount": round(exp.amount, 2),
                }
            )

        # Format results
        results = [
            {
                "category": cat,
                "total": round(data["total"], 2),
                "count": data["count"],
                "average": round(data["total"] / data["count"], 2),
                "items": sorted(data["items"], key=lambda x: x["amount"], reverse=True)[
                    :5
                ],  # Top 5
            }
            for cat, data in category_data.items()
        ]

        # Sort by total
        results.sort(key=lambda x: x["total"], reverse=True)

        return jsonify(
            {
                "period": {
                    "start": start_date.strftime("%Y-%m-%d"),
                    "end": end_date.strftime("%Y-%m-%d"),
                },
                "categories": results,
                "total": sum(r["total"] for r in results),
            }
        )

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/report/monthly_trend")
def api_report_monthly_trend():
    """
    Monthly spending trend for last 12 months

    Query params:
        company: Optional company filter
    """
    if DEMO_MODE:
        months = []
        for i in range(12):
            date = datetime.now() - timedelta(days=30 * i)
            months.append(
                {
                    "month": date.strftime("%Y-%m"),
                    "total": round(30000 + (i * 2000) % 20000, 2),
                    "count": 120 + (i * 10),
                }
            )
        return jsonify({"months": list(reversed(months))})

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        company = request.args.get("company")

        # Last 12 months
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365)

        # Get expenditures
        expenditures = db.get_expenditures_by_date_range(start_date, end_date, company)

        # Aggregate by month
        monthly_data = {}
        for exp in expenditures:
            month_key = exp.transaction_date.strftime("%Y-%m")
            if month_key not in monthly_data:
                monthly_data[month_key] = {"total": 0, "count": 0}

            monthly_data[month_key]["total"] += exp.amount
            monthly_data[month_key]["count"] += 1

        # Format results
        results = [
            {
                "month": month,
                "total": round(data["total"], 2),
                "count": data["count"],
                "average": round(data["total"] / data["count"], 2),
            }
            for month, data in sorted(monthly_data.items())
        ]

        return jsonify({"months": results})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/export/csv")
def api_export_csv():
    """Export expenditures to CSV"""
    if DEMO_MODE:
        return jsonify({"error": "Export not available in demo mode"}), 503

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        # Get query parameters
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")
        company = request.args.get("company")

        # Default to current year
        if not end_date_str:
            end_date = datetime.now()
        else:
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d")

        if not start_date_str:
            start_date = datetime(end_date.year, 1, 1)
        else:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")

        # Get expenditures
        expenditures = db.get_expenditures_by_date_range(start_date, end_date, company)

        # Export to CSV
        csv_data, headers = export_to_csv(expenditures)

        # Return as downloadable file
        from flask import Response

        return Response(csv_data, headers=headers)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/export/quickbooks")
def api_export_quickbooks():
    """Export expenditures to QuickBooks IIF format"""
    if DEMO_MODE:
        return jsonify({"error": "Export not available in demo mode"}), 503

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        # Get query parameters
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")
        company = request.args.get("company")

        # Default to current year
        if not end_date_str:
            end_date = datetime.now()
        else:
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d")

        if not start_date_str:
            start_date = datetime(end_date.year, 1, 1)
        else:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")

        # Get expenditures
        expenditures = db.get_expenditures_by_date_range(start_date, end_date, company)

        # Export to QuickBooks IIF
        iif_data, headers = export_to_quickbooks(expenditures)

        # Return as downloadable file
        from flask import Response

        return Response(iif_data, headers=headers)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# RECURRING EXPENDITURES
# ============================================================================


@app.route("/recurring")
def recurring_page():
    """Recurring/subscription expenses page"""
    return render_template("recurring.html")


@app.route("/api/recurring")
def api_recurring():
    """Get recurring expenditures"""
    if DEMO_MODE:
        recurring = [
            {"vendor": "AWS", "amount": 5000.00, "frequency": "monthly", "next_date": "2026-03-15"},
            {
                "vendor": "GitHub",
                "amount": 420.00,
                "frequency": "monthly",
                "next_date": "2026-03-01",
            },
            {
                "vendor": "Atlassian",
                "amount": 150.00,
                "frequency": "monthly",
                "next_date": "2026-03-10",
            },
        ]
        return jsonify({"recurring": recurring, "count": len(recurring)})

    if not db:
        return jsonify({"error": "Database not available"}), 503

    try:
        session = db.Session()
        from expenditure_models import RecurringExpenditure

        recurring = (
            session.query(RecurringExpenditure)
            .filter_by(active=True)
            .order_by(RecurringExpenditure.next_expected_date)
            .all()
        )

        results = [
            {
                "id": rec.recurring_id,
                "company": rec.company,
                "vendor": rec.vendor,
                "description": rec.description,
                "amount": round(rec.amount, 2),
                "currency": rec.currency,
                "frequency": rec.frequency,
                "start_date": rec.start_date.strftime("%Y-%m-%d"),
                "next_expected": rec.next_expected_date.strftime("%Y-%m-%d"),
                "active": rec.active,
                "auto_renew": rec.auto_renew,
            }
            for rec in recurring
        ]

        session.close()

        # Calculate total monthly cost
        monthly_total = sum(
            r["amount"] / (12 if r["frequency"] == "annual" else 1) for r in results
        )

        return jsonify({"recurring": results, "monthly_total": round(monthly_total, 2)})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# MAIN
# ============================================================================


def main():
    """Run Flask development server"""
    print("=" * 70)
    print("PHI EXPENDITURE TRACKING DASHBOARD")
    print("=" * 70)
    print()

    if not MODELS_AVAILABLE:
        print("⚠️  Warning: expenditure_models not available")
        print("   Some features may not work")
        print()

    if not db:
        print("⚠️  Warning: Database connection not available")
        print(f"   Connection string: {DB_CONNECTION}")
        print("   Dashboard will run in demo mode")
        print()

    print("🌐 Starting Flask server...")
    print("   Local:   http://localhost:5000")
    print("   Network: http://0.0.0.0:5000")
    print()
    print("📊 Available routes:")
    print("   /                - Dashboard home")
    print("   /expenditures    - Expenditure list")
    print("   /verify          - Human verification")
    print("   /reports         - Reports & exports")
    print("   /recurring       - Recurring expenses")
    print()
    print("Press Ctrl+C to stop")
    print("=" * 70)

    app.run(host="0.0.0.0", port=5000, debug=True)


if __name__ == "__main__":
    main()
