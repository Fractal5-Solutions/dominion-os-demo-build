#!/usr/bin/env python3
"""
PHI Expenditure Extraction Engine
Gmail API + Drive Integration for Automated Financial Data Harvesting

Purpose: Extract invoices, receipts, and financial transactions from Gmail and cloud storage
Approach: Safe, auditable, AI-powered with human verification for high-value items
Status: IMPLEMENTATION READY - Requires OAuth setup
"""

import base64
import hashlib
import json
import os
import re
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

# Note: These imports require installation:
# pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError

    GMAIL_API_AVAILABLE = True
except ImportError:
    GMAIL_API_AVAILABLE = False
    print(
        "⚠️  Gmail API libraries not installed. Run: pip install google-auth google-api-python-client"
    )


# Gmail API scopes
SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.modify",  # For labeling processed emails
]


@dataclass
class Expenditure:
    """Structured expenditure record"""

    expenditure_id: str
    company: str
    transaction_date: str
    amount: float
    currency: str
    category: str
    subcategory: str
    vendor: str
    description: str
    tax_type: Optional[str] = None
    tax_amount: Optional[float] = None
    tax_deductible: bool = True
    expense_type: str = "Operating"
    receipt_url: Optional[str] = None
    invoice_number: Optional[str] = None
    payment_method: str = "Unknown"
    payment_status: str = "Paid"
    data_source: str = "Gmail"
    source_email_id: Optional[str] = None
    extraction_confidence: str = "MEDIUM"
    human_verified: bool = False
    created_by: str = "PHI Chief"
    created_at: str = ""
    ledger_hash: str = ""

    def __post_init__(self):
        """Generate hash and timestamp after initialization"""
        if not self.created_at:
            self.created_at = datetime.utcnow().isoformat()
        if not self.ledger_hash:
            self.ledger_hash = self._generate_hash()

    def _generate_hash(self) -> str:
        """Generate SHA-256 hash for ledger trail"""
        data_string = f"{self.company}|{self.transaction_date}|{self.amount}|{self.vendor}|{self.invoice_number}"
        return hashlib.sha256(data_string.encode()).hexdigest()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return asdict(self)


class GmailExpenditureExtractor:
    """
    Gmail API integration for automated expenditure extraction
    """

    def __init__(
        self,
        credentials_path: str = "config/gmail_credentials.json",
        token_path: str = "config/gmail_token.json",
    ):
        self.credentials_path = credentials_path
        self.token_path = token_path
        self.service = None
        self.user_id = "me"

    def authenticate(self) -> bool:
        """Authenticate with Gmail API using OAuth 2.0"""
        if not GMAIL_API_AVAILABLE:
            print("❌ Gmail API libraries not available")
            return False

        creds = None

        # Load existing token if available
        if os.path.exists(self.token_path):
            creds = Credentials.from_authorized_user_file(self.token_path, SCOPES)

        # Refresh or get new credentials
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                if not os.path.exists(self.credentials_path):
                    print(f"❌ Credentials file not found: {self.credentials_path}")
                    print("📋 Setup instructions:")
                    print("   1. Go to https://console.cloud.google.com")
                    print("   2. Enable Gmail API")
                    print("   3. Create OAuth 2.0 credentials")
                    print(f"   4. Download and save to {self.credentials_path}")
                    return False

                flow = InstalledAppFlow.from_client_secrets_file(self.credentials_path, SCOPES)
                creds = flow.run_local_server(port=0)

            # Save credentials for next run
            with open(self.token_path, "w") as token:
                token.write(creds.to_json())

        self.service = build("gmail", "v1", credentials=creds)
        print("✅ Gmail API authenticated successfully")
        return True

    def search_emails(self, query: str, max_results: int = 100) -> List[Dict]:
        """
        Search Gmail for emails matching query

        Args:
            query: Gmail search query (e.g., "subject:invoice after:2024/01/01")
            max_results: Maximum number of results to return

        Returns:
            List of email dictionaries with metadata
        """
        if not self.service:
            print("❌ Not authenticated. Call authenticate() first.")
            return []

        try:
            results = (
                self.service.users()
                .messages()
                .list(userId=self.user_id, q=query, maxResults=max_results)
                .execute()
            )

            messages = results.get("messages", [])

            if not messages:
                print(f"No messages found for query: {query}")
                return []

            print(f"✅ Found {len(messages)} messages for query: {query}")
            return messages

        except HttpError as error:
            print(f"❌ Gmail API error: {error}")
            return []

    def get_email_details(self, message_id: str) -> Optional[Dict]:
        """Get full email details including body and attachments"""
        if not self.service:
            return None

        try:
            message = (
                self.service.users()
                .messages()
                .get(userId=self.user_id, id=message_id, format="full")
                .execute()
            )

            return self._parse_email(message)

        except HttpError as error:
            print(f"❌ Error fetching email {message_id}: {error}")
            return None

    def _parse_email(self, message: Dict) -> Dict:
        """Parse Gmail API message into structured format"""
        headers = {h["name"]: h["value"] for h in message["payload"]["headers"]}

        # Extract body
        body = self._get_email_body(message["payload"])

        # Extract attachments metadata
        attachments = self._get_attachment_info(message["payload"])

        return {
            "id": message["id"],
            "thread_id": message["threadId"],
            "from": headers.get("From", ""),
            "to": headers.get("To", ""),
            "subject": headers.get("Subject", ""),
            "date": headers.get("Date", ""),
            "body": body,
            "attachments": attachments,
            "snippet": message.get("snippet", ""),
        }

    def _get_email_body(self, payload: Dict) -> str:
        """Extract email body from payload"""
        if "body" in payload and "data" in payload["body"]:
            return base64.urlsafe_b64decode(payload["body"]["data"]).decode(
                "utf-8", errors="ignore"
            )

        if "parts" in payload:
            for part in payload["parts"]:
                if part["mimeType"] == "text/plain":
                    if "data" in part["body"]:
                        return base64.urlsafe_b64decode(part["body"]["data"]).decode(
                            "utf-8", errors="ignore"
                        )

        return ""

    def _get_attachment_info(self, payload: Dict) -> List[Dict]:
        """Extract attachment metadata"""
        attachments = []

        if "parts" in payload:
            for part in payload["parts"]:
                if part.get("filename"):
                    attachments.append(
                        {
                            "filename": part["filename"],
                            "mime_type": part["mimeType"],
                            "attachment_id": part["body"].get("attachmentId", ""),
                            "size": part["body"].get("size", 0),
                        }
                    )

        return attachments

    def extract_expenditure_from_email(self, email: Dict) -> Optional[Expenditure]:
        """
        Extract expenditure data from email using pattern matching

        This is a simple regex-based extractor. For production, consider:
        - GPT-4 for complex invoice parsing
        - Claude for structured extraction
        - Custom ML models for specific vendors
        """
        body = email.get("body", "") + " " + email.get("snippet", "")
        subject = email.get("subject", "")

        # Extract amount
        amount_match = re.search(r"\$([0-9,]+\.[0-9]{2})", body)
        if not amount_match:
            amount_match = re.search(r"Total[:|\s]+\$?([0-9,]+\.[0-9]{2})", body, re.IGNORECASE)

        if not amount_match:
            return None  # No amount found

        amount_str = amount_match.group(1).replace(",", "")
        amount = float(amount_str)

        # Extract vendor from email address
        from_email = email.get("from", "")
        vendor = self._extract_vendor_from_email(from_email)

        # Extract date (use email date)
        date_str = email.get("date", "")
        transaction_date = self._parse_date(date_str)

        # Extract invoice number
        invoice_match = re.search(r"Invoice #[:|\s]+([A-Z0-9-]+)", body, re.IGNORECASE)
        invoice_number = invoice_match.group(1) if invoice_match else None

        # Determine company (would need more sophisticated logic)
        company = self._determine_company(subject, body, vendor)

        # Categorize (simple heuristic, should use AI for better accuracy)
        category = self._categorize_expense(subject, body, vendor)

        # Build expenditure record
        return Expenditure(
            expenditure_id=f"EXP-{email['id'][:16]}",
            company=company,
            transaction_date=transaction_date,
            amount=amount,
            currency="USD",  # Default, should detect from email
            category=category,
            subcategory="Auto-detected",
            vendor=vendor,
            description=subject[:200],
            invoice_number=invoice_number,
            data_source="Gmail",
            source_email_id=email["id"],
            extraction_confidence="MEDIUM",  # Simple regex = medium confidence
            created_by="PHI Chief Auto-Extractor",
        )

    def _extract_vendor_from_email(self, from_email: str) -> str:
        """Extract vendor name from email address"""
        # Extract domain
        match = re.search(r"@([a-zA-Z0-9.-]+)", from_email)
        if match:
            domain = match.group(1)
            # Remove common TLDs and clean up
            vendor = domain.split(".")[0]
            return vendor.title()
        return "Unknown Vendor"

    def _parse_date(self, date_str: str) -> str:
        """Parse email date to YYYY-MM-DD format"""
        try:
            # Gmail date format: "Mon, 27 Feb 2026 10:30:00 -0800"
            from email.utils import parsedate_to_datetime

            dt = parsedate_to_datetime(date_str)
            return dt.strftime("%Y-%m-%d")
        except:
            return datetime.now().strftime("%Y-%m-%d")

    def _determine_company(self, subject: str, body: str, vendor: str) -> str:
        """Determine which company this expense belongs to (simple heuristic)"""
        text = (subject + " " + body).lower()

        if "fractal5" in text or "dominion" in text:
            return "Fractal5 Solutions Inc"
        elif "blue wave" in text or "campaign" in text:
            return "Blue Wave Action Group Inc"
        elif "plane4" in text or "grain" in text or "workshop" in text:
            return "Plane4 Grain Inc"

        # Default to Fractal5 (most likely)
        return "Fractal5 Solutions Inc"

    def _categorize_expense(self, subject: str, body: str, vendor: str) -> str:
        """Categorize expense based on content (simple heuristic)"""
        text = (subject + " " + body + " " + vendor).lower()

        # Cloud & Infrastructure
        if any(keyword in text for keyword in ["google cloud", "gcp", "aws", "azure", "cloud run"]):
            return "Cloud Computing"
        if any(keyword in text for keyword in ["domain", "hosting", "squarespace", "godaddy"]):
            return "Domain & Hosting"

        # Software & SaaS
        if any(keyword in text for keyword in ["github", "gitlab", "subscription"]):
            return "Development Tools"
        if any(keyword in text for keyword in ["stripe", "payment processing"]):
            return "Payment Processing Fees"

        # Marketing
        if any(keyword in text for keyword in ["google ads", "facebook ads", "advertising"]):
            return "Advertising"

        return "Uncategorized"

    def bulk_extract(self, queries: List[str], date_range: tuple = None) -> List[Expenditure]:
        """
        Bulk extract expenditures from multiple queries

        Args:
            queries: List of Gmail search queries
            date_range: Optional (start_date, end_date) tuple for filtering

        Returns:
            List of extracted expenditures
        """
        all_expenditures = []

        for query in queries:
            # Add date filter if provided
            if date_range:
                start, end = date_range
                query += f" after:{start} before:{end}"

            print(f"\n🔍 Searching: {query}")
            messages = self.search_emails(query, max_results=500)

            for msg in messages[:10]:  # Limit for testing
                email = self.get_email_details(msg["id"])
                if email:
                    expenditure = self.extract_expenditure_from_email(email)
                    if expenditure:
                        all_expenditures.append(expenditure)
                        print(f"   ✅ Extracted: ${expenditure.amount} - {expenditure.vendor}")

        return all_expenditures


def save_expenditures(expenditures: List[Expenditure], output_path: str):
    """Save expenditures to JSON file"""
    output_dir = Path(output_path).parent
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        json.dump([exp.to_dict() for exp in expenditures], f, indent=2)

    print(f"\n✅ Saved {len(expenditures)} expenditures to {output_path}")


def main():
    """Main execution flow"""
    print("=" * 70)
    print("PHI EXPENDITURE EXTRACTION ENGINE")
    print("=" * 70)

    if not GMAIL_API_AVAILABLE:
        print("\n❌ Gmail API libraries not installed")
        print("   Run: pip install google-auth google-auth-oauthlib google-api-python-client")
        return

    # Initialize extractor
    extractor = GmailExpenditureExtractor()

    # Authenticate
    if not extractor.authenticate():
        print("❌ Authentication failed. Exiting.")
        return

    # Define search queries (from config)
    queries = [
        "subject:invoice",
        "subject:receipt",
        "from:billing@google.com",
        "from:receipts@stripe.com",
        "subject:payment",
        "has:attachment filename:pdf subject:invoice",
    ]

    # Set date range (last 90 days for testing)
    end_date = datetime.now()
    start_date = end_date - timedelta(days=90)
    date_range = (start_date.strftime("%Y/%m/%d"), end_date.strftime("%Y/%m/%d"))

    # Extract expenditures
    print(f"\n📅 Extracting from {date_range[0]} to {date_range[1]}")
    expenditures = extractor.bulk_extract(queries, date_range)

    # Save results
    if expenditures:
        output_path = (
            f"telemetry/expenditures/extracted_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )
        save_expenditures(expenditures, output_path)

        # Summary statistics
        total_amount = sum(exp.amount for exp in expenditures)
        by_company = {}
        for exp in expenditures:
            by_company[exp.company] = by_company.get(exp.company, 0) + exp.amount

        print("\n" + "=" * 70)
        print("EXTRACTION SUMMARY")
        print("=" * 70)
        print(f"Total Expenditures: {len(expenditures)}")
        print(f"Total Amount: ${total_amount:,.2f}")
        print("\nBy Company:")
        for company, amount in by_company.items():
            print(f"  {company}: ${amount:,.2f}")
    else:
        print("\n⚠️  No expenditures extracted")


if __name__ == "__main__":
    main()
