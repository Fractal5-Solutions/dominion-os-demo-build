#!/usr/bin/env python3
"""
PHI Expenditure AI Optimizer
Purpose: AI-enhanced pipeline optimization for autonomous ingestion
Features: Confidence tuning, category prediction, vendor normalization, outlier detection
Generated: 2026-02-27 by PHI Chief Sovereign Mode
"""

import sys
import re
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from difflib import SequenceMatcher


class AIOptimizer:
    """AI-powered optimization for expenditure ingestion pipeline"""

    def __init__(self, config_path: Optional[str] = None):
        """Initialize AI optimizer with configuration"""
        self.config_path = config_path or Path(__file__).parent / "ai_optimization_config.json"
        self.config = self.load_config()
        self.vendor_patterns = self.build_vendor_patterns()
        self.category_rules = self.build_category_rules()

    def load_config(self) -> Dict:
        """Load AI optimization configuration"""
        if Path(self.config_path).exists():
            with open(self.config_path, 'r') as f:
                return json.load(f)

        # Default configuration
        return {
            "enabled": True,
            "features": {
                "confidence_tuning": {
                    "enabled": True,
                    "thresholds": {"high": 0.9, "medium": 0.7, "low": 0.5},
                    "auto_verify_high": True
                },
                "category_prediction": {
                    "enabled": True,
                    "model": "pattern_matching_v1",
                    "confidence_threshold": 0.85
                },
                "vendor_normalization": {
                    "enabled": True,
                    "fuzzy_matching": True,
                    "auto_create_vendors": False
                },
                "amount_validation": {
                    "enabled": True,
                    "outlier_detection": True,
                    "statistical_method": "iqr"
                },
                "tax_calculation": {
                    "enabled": True,
                    "auto_detect_region": True,
                    "default_rate": 0.13
                }
            }
        }

    def build_vendor_patterns(self) -> Dict[str, List[str]]:
        """Build vendor name patterns for normalization"""
        return {
            "google": ["google", "gcp", "google cloud", "g suite", "google workspace", "gmail"],
            "amazon": ["amazon", "aws", "amazon web services", "amzn"],
            "microsoft": ["microsoft", "msft", "azure", "office 365", "ms 365"],
            "github": ["github", "gh", "git hub"],
            "atlassian": ["atlassian", "jira", "confluence", "trello"],
            "adobe": ["adobe", "adbe", "creative cloud"],
            "slack": ["slack", "slack tech", "slack technologies"],
            "zoom": ["zoom", "zoom.us", "zoom video"],
            "docusign": ["docusign", "docu sign", "dsign"],
            "salesforce": ["salesforce", "sfdc", "sales force"],
            "shopify": ["shopify", "shop pay"],
            "stripe": ["stripe", "stripe inc", "stripe payments"],
            "twilio": ["twilio", "twlo"],
            "datadog": ["datadog", "data dog", "ddog"],
            "cloudflare": ["cloudflare", "cloud flare"],
            "digitalocean": ["digitalocean", "digital ocean", "do"],
            "linode": ["linode", "akamai"],
            "godaddy": ["godaddy", "go daddy"],
            "namecheap": ["namecheap", "name cheap"],
            "rogers": ["rogers", "rogers communications"],
            "bell": ["bell", "bell canada"],
            "telus": ["telus", "telus communications"],
        }

    def build_category_rules(self) -> List[Dict]:
        """Build category prediction rules"""
        return [
            {
                "category": "Cloud Services",
                "keywords": ["cloud", "aws", "azure", "gcp", "hosting", "server", "compute", "storage", "cdn"],
                "vendors": ["google cloud", "amazon web services", "microsoft azure", "digitalocean", "cloudflare"]
            },
            {
                "category": "Software Subscriptions",
                "keywords": ["subscription", "license", "saas", "software", "app", "tool", "service"],
                "vendors": ["github", "atlassian", "adobe", "jetbrains", "slack", "zoom", "docusign"]
            },
            {
                "category": "Marketing & Advertising",
                "keywords": ["ads", "advertising", "marketing", "campaign", "ppc", "social media"],
                "vendors": ["google ads", "facebook", "linkedin", "twitter", "instagram"]
            },
            {
                "category": "Professional Services",
                "keywords": ["consulting", "legal", "accounting", "cpa", "lawyer", "attorney", "professional"],
                "vendors": ["legal", "accounting", "consulting"]
            },
            {
                "category": "Office & Facilities",
                "keywords": ["office", "supplies", "furniture", "workspace", "coworking", "rent"],
                "vendors": ["wework", "regus", "staples", "office depot"]
            },
            {
                "category": "Telecommunications",
                "keywords": ["phone", "mobile", "internet", "telecom", "wireless", "broadband"],
                "vendors": ["rogers", "bell", "telus", "at&t", "verizon"]
            },
            {
                "category": "Insurance",
                "keywords": ["insurance", "coverage", "policy", "premium"],
                "vendors": ["manulife", "sun life", "great west", "industrial alliance"]
            },
            {
                "category": "Domain & Hosting",
                "keywords": ["domain", "dns", "ssl", "certificate", "hosting", "registrar"],
                "vendors": ["godaddy", "namecheap", "google domains", "cloudflare"]
            },
            {
                "category": "Payment Processing",
                "keywords": ["payment", "processing", "gateway", "merchant", "pos", "transaction"],
                "vendors": ["stripe", "square", "paypal", "shopify payments"]
            },
            {
                "category": "Development Tools",
                "keywords": ["development", "dev", "api", "code", "repository", "version control"],
                "vendors": ["github", "gitlab", "bitbucket", "jetbrains"]
            }
        ]

    def normalize_vendor(self, vendor_name: str) -> Tuple[str, float]:
        """
        Normalize vendor name using fuzzy matching
        Returns: (normalized_name, confidence)
        """
        if not self.config["features"]["vendor_normalization"]["enabled"]:
            return vendor_name, 1.0

        vendor_lower = vendor_name.lower().strip()

        # Check exact patterns first
        for normalized, patterns in self.vendor_patterns.items():
            for pattern in patterns:
                if pattern in vendor_lower:
                    return normalized.title(), 1.0

        # Fuzzy matching if enabled
        if self.config["features"]["vendor_normalization"]["fuzzy_matching"]:
            best_match = None
            best_ratio = 0.0

            for normalized, patterns in self.vendor_patterns.items():
                for pattern in patterns:
                    ratio = SequenceMatcher(None, vendor_lower, pattern).ratio()
                    if ratio > best_ratio and ratio >= 0.75:
                        best_ratio = ratio
                        best_match = normalized.title()

            if best_match:
                return best_match, best_ratio

        return vendor_name, 0.8  # Return original with medium confidence

    def predict_category(self, vendor: str, description: str) -> Tuple[str, float]:
        """
        Predict expenditure category using pattern matching
        Returns: (category, confidence)
        """
        if not self.config["features"]["category_prediction"]["enabled"]:
            return "Uncategorized", 0.5

        vendor_lower = vendor.lower()
        description_lower = description.lower() if description else ""
        combined_text = f"{vendor_lower} {description_lower}"

        best_category = None
        best_score = 0.0

        for rule in self.category_rules:
            score = 0.0
            matches = 0

            # Check vendor matches
            for vendor_pattern in rule["vendors"]:
                if vendor_pattern.lower() in vendor_lower:
                    score += 0.5
                    matches += 1
                    break

            # Check keyword matches
            keyword_matches = sum(1 for kw in rule["keywords"] if kw in combined_text)
            if keyword_matches > 0:
                score += min(keyword_matches * 0.15, 0.5)
                matches += keyword_matches

            # Normalize score
            if matches > 0:
                confidence = min(score, 1.0)
                if confidence > best_score:
                    best_score = confidence
                    best_category = rule["category"]

        if best_category and best_score >= self.config["features"]["category_prediction"]["confidence_threshold"]:
            return best_category, best_score

        return "Uncategorized", 0.5

    def calculate_confidence(self, data: Dict) -> Tuple[str, float]:
        """
        Calculate overall confidence level for extracted data
        Returns: (confidence_level, confidence_score)
        """
        if not self.config["features"]["confidence_tuning"]["enabled"]:
            return "MEDIUM", 0.7

        score = 0.0
        weights = {
            "vendor": 0.25,
            "amount": 0.25,
            "date": 0.20,
            "description": 0.15,
            "invoice": 0.15
        }

        # Vendor confidence
        if data.get("vendor"):
            vendor_name = data["vendor"]
            if len(vendor_name) > 3 and not vendor_name.isdigit():
                score += weights["vendor"]
            elif len(vendor_name) > 0:
                score += weights["vendor"] * 0.5

        # Amount confidence
        if data.get("amount"):
            try:
                amount = float(data["amount"])
                if 0 < amount < 1000000:  # Reasonable range
                    score += weights["amount"]
                elif amount > 0:
                    score += weights["amount"] * 0.7
            except (ValueError, TypeError):
                pass

        # Date confidence
        if data.get("date"):
            try:
                date_str = data["date"]
                # Check if date is in reasonable format
                if re.match(r'\d{4}-\d{2}-\d{2}', date_str):
                    score += weights["date"]
                elif re.match(r'\d{2}/\d{2}/\d{4}', date_str):
                    score += weights["date"] * 0.8
            except (ValueError, TypeError):
                pass

        # Description confidence
        if data.get("description"):
            desc = data["description"]
            if len(desc) > 10:
                score += weights["description"]
            elif len(desc) > 0:
                score += weights["description"] * 0.5

        # Invoice number confidence
        if data.get("invoice_number"):
            invoice = data["invoice_number"]
            if len(invoice) > 3:
                score += weights["invoice"]

        # Determine confidence level
        thresholds = self.config["features"]["confidence_tuning"]["thresholds"]
        if score >= thresholds["high"]:
            return "HIGH", score
        elif score >= thresholds["medium"]:
            return "MEDIUM", score
        else:
            return "LOW", score

    def validate_amount(self, amount: float, category: str, historical_data: Optional[List[float]] = None) -> Tuple[bool, str]:
        """
        Validate amount for outlier detection
        Returns: (is_valid, reason)
        """
        if not self.config["features"]["amount_validation"]["enabled"]:
            return True, "validation_disabled"

        # Basic range check
        if amount <= 0:
            return False, "negative_or_zero"

        if amount > 1000000:
            return False, "exceeds_reasonable_maximum"

        # Outlier detection using IQR if historical data provided
        if historical_data and len(historical_data) >= 10:
            if self.config["features"]["amount_validation"]["outlier_detection"]:
                sorted_data = sorted(historical_data)
                q1_idx = len(sorted_data) // 4
                q3_idx = 3 * len(sorted_data) // 4

                q1 = sorted_data[q1_idx]
                q3 = sorted_data[q3_idx]
                iqr = q3 - q1

                lower_bound = q1 - 1.5 * iqr
                upper_bound = q3 + 1.5 * iqr

                if amount < lower_bound or amount > upper_bound:
                    return False, f"statistical_outlier (IQR: {q1:.2f}-{q3:.2f})"

        return True, "valid"

    def calculate_tax(self, amount: float, region: str = "ON") -> Tuple[float, str]:
        """
        Calculate tax amount based on region
        Returns: (tax_amount, tax_type)
        """
        if not self.config["features"]["tax_calculation"]["enabled"]:
            return 0.0, "NONE"

        # Tax rates by region (Canadian provinces)
        tax_rates = {
            "ON": (0.13, "HST"),  # Ontario
            "BC": (0.12, "PST+GST"),  # British Columbia
            "AB": (0.05, "GST"),  # Alberta
            "QC": (0.14975, "QST+GST"),  # Quebec
            "NS": (0.15, "HST"),  # Nova Scotia
            "NB": (0.15, "HST"),  # New Brunswick
            "MB": (0.12, "PST+GST"),  # Manitoba
            "SK": (0.11, "PST+GST"),  # Saskatchewan
            "PE": (0.15, "HST"),  # Prince Edward Island
            "NL": (0.15, "HST"),  # Newfoundland and Labrador
        }

        if region in tax_rates:
            rate, tax_type = tax_rates[region]
        else:
            # Use default rate
            rate = self.config["features"]["tax_calculation"]["default_rate"]
            tax_type = "HST"

        tax_amount = amount * rate
        return round(tax_amount, 2), tax_type

    def optimize_extraction(self, raw_data: Dict) -> Dict:
        """
        Apply all AI optimizations to raw extracted data
        Returns: Optimized data with confidence scores
        """
        optimized = raw_data.copy()
        metadata = {
            "ai_optimized": True,
            "optimization_timestamp": datetime.utcnow().isoformat() + "Z",
            "optimizations_applied": []
        }

        # Vendor normalization
        if optimized.get("vendor"):
            normalized_vendor, vendor_confidence = self.normalize_vendor(optimized["vendor"])
            if normalized_vendor != optimized["vendor"]:
                metadata["optimizations_applied"].append({
                    "type": "vendor_normalization",
                    "original": optimized["vendor"],
                    "normalized": normalized_vendor,
                    "confidence": vendor_confidence
                })
            optimized["vendor"] = normalized_vendor
            optimized["vendor_confidence"] = vendor_confidence

        # Category prediction
        vendor = optimized.get("vendor", "")
        description = optimized.get("description", "")
        predicted_category, category_confidence = self.predict_category(vendor, description)

        if not optimized.get("category") or optimized["category"] == "Uncategorized":
            optimized["category"] = predicted_category
            metadata["optimizations_applied"].append({
                "type": "category_prediction",
                "predicted": predicted_category,
                "confidence": category_confidence
            })

        optimized["category_confidence"] = category_confidence

        # Confidence calculation
        confidence_level, confidence_score = self.calculate_confidence(optimized)
        optimized["confidence"] = confidence_level
        optimized["confidence_score"] = confidence_score

        metadata["optimizations_applied"].append({
            "type": "confidence_calculation",
            "level": confidence_level,
            "score": confidence_score
        })

        # Auto-verify if high confidence
        if (confidence_level == "HIGH" and
            self.config["features"]["confidence_tuning"]["auto_verify_high"]):
            optimized["verified"] = True
            optimized["verified_by"] = "AI_AUTO_VERIFY"
            optimized["verified_at"] = datetime.utcnow().isoformat() + "Z"
            metadata["optimizations_applied"].append({
                "type": "auto_verification",
                "reason": "high_confidence",
                "score": confidence_score
            })

        # Amount validation
        if optimized.get("amount"):
            try:
                amount = float(optimized["amount"])
                is_valid, reason = self.validate_amount(amount, optimized.get("category", ""))

                if not is_valid:
                    optimized["amount_validation_warning"] = reason
                    metadata["optimizations_applied"].append({
                        "type": "amount_validation",
                        "valid": False,
                        "reason": reason
                    })
            except (ValueError, TypeError):
                pass

        # Tax calculation (if not already present)
        if not optimized.get("tax_amount") and optimized.get("amount"):
            try:
                amount = float(optimized["amount"])
                region = optimized.get("region", "ON")
                tax_amount, tax_type = self.calculate_tax(amount, region)

                if tax_amount > 0:
                    optimized["tax_amount"] = tax_amount
                    optimized["tax_type"] = tax_type
                    optimized["tax_calculated_by"] = "AI"
                    metadata["optimizations_applied"].append({
                        "type": "tax_calculation",
                        "amount": tax_amount,
                        "type": tax_type,
                        "region": region
                    })
            except (ValueError, TypeError):
                pass

        optimized["ai_metadata"] = metadata
        return optimized

    def batch_optimize(self, raw_data_list: List[Dict]) -> List[Dict]:
        """Optimize a batch of extracted data"""
        return [self.optimize_extraction(data) for data in raw_data_list]

    def get_optimization_stats(self, optimized_data_list: List[Dict]) -> Dict:
        """Generate statistics about optimizations applied"""
        stats = {
            "total_items": len(optimized_data_list),
            "ai_optimized": 0,
            "auto_verified": 0,
            "vendor_normalized": 0,
            "category_predicted": 0,
            "tax_calculated": 0,
            "confidence_distribution": {
                "HIGH": 0,
                "MEDIUM": 0,
                "LOW": 0
            }
        }

        for item in optimized_data_list:
            if item.get("ai_metadata", {}).get("ai_optimized"):
                stats["ai_optimized"] += 1

            if item.get("verified_by") == "AI_AUTO_VERIFY":
                stats["auto_verified"] += 1

            confidence = item.get("confidence", "MEDIUM")
            if confidence in stats["confidence_distribution"]:
                stats["confidence_distribution"][confidence] += 1

            metadata = item.get("ai_metadata", {})
            optimizations = metadata.get("optimizations_applied", [])

            for opt in optimizations:
                opt_type = opt.get("type")
                if opt_type == "vendor_normalization":
                    stats["vendor_normalized"] += 1
                elif opt_type == "category_prediction":
                    stats["category_predicted"] += 1
                elif opt_type == "tax_calculation":
                    stats["tax_calculated"] += 1

        return stats


def main():
    """CLI interface for AI optimizer"""
    import argparse

    parser = argparse.ArgumentParser(description="PHI Expenditure AI Optimizer")
    parser.add_argument("--test", action="store_true", help="Run test optimization")
    parser.add_argument("--input", type=str, help="Input JSON file with raw data")
    parser.add_argument("--output", type=str, help="Output JSON file for optimized data")
    parser.add_argument("--config", type=str, help="Path to AI optimization config")

    args = parser.parse_args()

    optimizer = AIOptimizer(config_path=args.config)

    if args.test:
        # Test with sample data
        sample_data = {
            "vendor": "Google Cloud Platform",
            "amount": 1250.00,
            "date": "2026-02-15",
            "description": "Cloud compute and storage services",
            "invoice_number": "GCP-123456"
        }

        print("🧪 Testing AI Optimizer...")
        print(f"\n📥 Input:\n{json.dumps(sample_data, indent=2)}")

        optimized = optimizer.optimize_extraction(sample_data)

        print(f"\n📤 Optimized:\n{json.dumps(optimized, indent=2)}")

    elif args.input and args.output:
        # Process file
        with open(args.input, 'r') as f:
            raw_data_list = json.load(f)

        print(f"🔄 Optimizing {len(raw_data_list)} items...")

        optimized_list = optimizer.batch_optimize(raw_data_list)
        stats = optimizer.get_optimization_stats(optimized_list)

        with open(args.output, 'w') as f:
            json.dump(optimized_list, f, indent=2)

        print(f"\n✅ Optimization complete!")
        print(f"\n📊 Statistics:")
        print(json.dumps(stats, indent=2))

    else:
        print("✨ PHI Expenditure AI Optimizer")
        print("\nUsage:")
        print("  --test              Run test optimization")
        print("  --input FILE        Input JSON file")
        print("  --output FILE       Output JSON file")
        print("  --config FILE       Config file path")


if __name__ == "__main__":
    main()
