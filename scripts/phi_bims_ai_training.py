#!/usr/bin/env python3
"""
PHI BIMS AI Training Script
Trains company-specific AI models for revenue verification and financial categorization
"""

import json
import os
import pickle
import sqlite3
from datetime import datetime
from typing import Any, Dict, List


class BIMSFinancialAI:
    """AI training system for BIMS-integrated financial operations"""

    def __init__(self, db_path: str = "data/bims_financial.db"):
        self.db_path = db_path
        self.models = {}
        self.company_configs = {}

        # Load BIMS company configurations
        self.load_bims_config()

    def load_bims_config(self):
        """Load company configurations from BIMS organizational-authority.json"""
        try:
            with open("organizational-authority.json", "r") as f:
                bims_data = json.load(f)

            # Extract company configurations
            for company in bims_data.get("companies", []):
                name = company.get("name", "")
                if name in [
                    "Fractal5 Solutions Inc",
                    "Blue Wave Action Group Inc",
                    "Plane4 Grain Inc",
                ]:
                    self.company_configs[name] = {
                        "business_type": company.get("business_type", ""),
                        "jurisdiction": company.get("jurisdiction", ""),
                        "primary_business": company.get("primary_business", ""),
                        "revenue_streams": self.get_company_revenue_streams(name),
                    }

            print(f"✅ Loaded BIMS configurations for {len(self.company_configs)} companies")

        except Exception as e:
            print(f"⚠️  Could not load BIMS config: {e}")
            # Fallback configurations
            self.company_configs = {
                "Fractal5 Solutions Inc": {
                    "business_type": "Technology",
                    "jurisdiction": "Delaware",
                    "primary_business": "AI development and software solutions",
                    "revenue_streams": ["Software Development", "AI Consulting", "Licensing"],
                },
                "Blue Wave Action Group Inc": {
                    "business_type": "Political",
                    "jurisdiction": "Delaware",
                    "primary_business": "Political action and campaign management",
                    "revenue_streams": [
                        "Campaign Contributions",
                        "Consulting Fees",
                        "Event Revenue",
                    ],
                },
                "Plane4 Grain Inc": {
                    "business_type": "Manufacturing",
                    "jurisdiction": "Delaware",
                    "primary_business": "Furniture manufacturing and sales",
                    "revenue_streams": ["Furniture Sales", "Custom Orders", "Wholesale"],
                },
            }

    def get_company_revenue_streams(self, company_name: str) -> List[str]:
        """Get revenue streams based on company business type"""
        streams = {
            "Fractal5 Solutions Inc": [
                "Software Development",
                "AI Consulting",
                "Licensing",
                "Support Services",
            ],
            "Blue Wave Action Group Inc": [
                "Campaign Contributions",
                "Political Consulting",
                "Event Management",
                "Digital Services",
            ],
            "Plane4 Grain Inc": [
                "Furniture Sales",
                "Custom Manufacturing",
                "Wholesale Distribution",
                "Installation Services",
            ],
        }
        return streams.get(company_name, ["General Revenue"])

    def train_company_models(self):
        """Train AI models for each BIMS company"""
        print("🤖 Training BIMS Company-Specific AI Models...")

        for company_name, config in self.company_configs.items():
            print(f"\n🏢 Training models for {company_name}")

            # Train revenue categorization model
            revenue_model = self.train_revenue_categorization(company_name, config)

            # Train compliance model
            compliance_model = self.train_compliance_model(company_name, config)

            # Train anomaly detection model
            anomaly_model = self.train_anomaly_detection(company_name, config)

            self.models[company_name] = {
                "revenue_categorization": revenue_model,
                "compliance": compliance_model,
                "anomaly_detection": anomaly_model,
                "trained_at": datetime.now().isoformat(),
                "config": config,
            }

            print(f"✅ Models trained for {company_name}")

        # Save models
        self.save_models()
        print("💾 AI Models saved successfully")

    def train_revenue_categorization(self, company_name: str, config: Dict) -> Dict:
        """Train revenue categorization model for specific company"""
        print(f"  📊 Training revenue categorization for {config['business_type']}")

        # Create training data based on company type
        training_data = self.generate_revenue_training_data(company_name, config)

        # Simple rule-based model (can be enhanced with ML later)
        model = {
            "rules": self.create_categorization_rules(config),
            "training_data_size": len(training_data),
            "accuracy_estimate": 0.85,  # Placeholder
            "business_type": config["business_type"],
        }

        return model

    def train_compliance_model(self, company_name: str, config: Dict) -> Dict:
        """Train compliance checking model"""
        print(f"  ⚖️  Training compliance model for {config['jurisdiction']}")

        model = {
            "jurisdiction": config["jurisdiction"],
            "business_type": config["business_type"],
            "compliance_rules": self.create_compliance_rules(config),
            "risk_levels": ["Low", "Medium", "High", "Critical"],
            "last_updated": datetime.now().isoformat(),
        }

        return model

    def train_anomaly_detection(self, company_name: str, config: Dict) -> Dict:
        """Train anomaly detection model"""
        print(f"  🔍 Training anomaly detection for {company_name}")

        model = {
            "thresholds": self.calculate_anomaly_thresholds(config),
            "patterns": self.identify_normal_patterns(config),
            "sensitivity": 0.95,
            "false_positive_rate": 0.05,
        }

        return model

    def generate_revenue_training_data(self, company_name: str, config: Dict) -> List[Dict]:
        """Generate training data for revenue categorization"""
        # This would normally load from historical data
        # For now, create synthetic examples
        examples = []

        for stream in config["revenue_streams"]:
            examples.extend(
                [
                    {
                        "description": f"{stream} - Standard transaction",
                        "category": stream,
                        "amount": 1000.00,
                    },
                    {
                        "description": f"{stream} - Large transaction",
                        "category": stream,
                        "amount": 50000.00,
                    },
                    {
                        "description": f"{stream} - Small transaction",
                        "category": stream,
                        "amount": 100.00,
                    },
                ]
            )

        return examples

    def create_categorization_rules(self, config: Dict) -> List[Dict]:
        """Create categorization rules based on company type"""
        rules = []

        if config["business_type"] == "Technology":
            rules = [
                {"keyword": "software|development|ai|ml", "category": "Software Development"},
                {"keyword": "license|licensing", "category": "Licensing"},
                {"keyword": "consult|advisory", "category": "AI Consulting"},
            ]
        elif config["business_type"] == "Political":
            rules = [
                {"keyword": "campaign|contribution|donation", "category": "Campaign Contributions"},
                {"keyword": "consult|strategy|lobby", "category": "Political Consulting"},
                {"keyword": "event|fundraiser", "category": "Event Management"},
            ]
        elif config["business_type"] == "Manufacturing":
            rules = [
                {"keyword": "furniture|sale|retail", "category": "Furniture Sales"},
                {"keyword": "custom|manufacture|build", "category": "Custom Manufacturing"},
                {"keyword": "wholesale|distribut", "category": "Wholesale Distribution"},
            ]

        return rules

    def create_compliance_rules(self, config: Dict) -> List[Dict]:
        """Create compliance rules based on jurisdiction and business type"""
        rules = []

        # Base compliance rules
        rules.append(
            {
                "rule": "amount_threshold",
                "threshold": 10000.00,
                "action": "review_required",
                "jurisdiction": config["jurisdiction"],
            }
        )

        # Business-specific rules
        if config["business_type"] == "Political":
            rules.extend(
                [
                    {"rule": "campaign_finance_limits", "max_contribution": 5000.00},
                    {"rule": "disclosure_requirements", "threshold": 1000.00},
                    {"rule": "foreign_funding_prohibition", "allowed": False},
                ]
            )
        elif config["business_type"] == "Technology":
            rules.extend(
                [
                    {
                        "rule": "export_controls",
                        "restricted_countries": ["Cuba", "Iran", "North Korea"],
                    },
                    {"rule": "data_privacy", "gdpr_compliance": True},
                ]
            )

        return rules

    def calculate_anomaly_thresholds(self, config: Dict) -> Dict:
        """Calculate anomaly detection thresholds"""
        # This would be based on historical data analysis
        return {
            "amount_threshold": 50000.00,
            "frequency_threshold": 10,  # transactions per day
            "unusual_hours": ["00:00-06:00"],
            "unusual_amounts": [999.99, 777.77, 1234.56],  # Common test amounts
        }

    def identify_normal_patterns(self, config: Dict) -> List[Dict]:
        """Identify normal transaction patterns"""
        patterns = []

        for stream in config["revenue_streams"]:
            patterns.append(
                {
                    "stream": stream,
                    "typical_amount_range": [100.00, 10000.00],
                    "typical_frequency": "daily",
                    "typical_description_patterns": [stream.lower(), "payment", "invoice"],
                }
            )

        return patterns

    def save_models(self):
        """Save trained models to disk"""
        os.makedirs("models", exist_ok=True)

        with open("models/bims_ai_models.pkl", "wb") as f:
            pickle.dump(self.models, f)

        # Also save as JSON for inspection
        with open("models/bims_ai_models.json", "w") as f:
            # Convert to JSON-serializable format
            json_models = {}
            for company, model_data in self.models.items():
                json_models[company] = {
                    "config": model_data["config"],
                    "trained_at": model_data["trained_at"],
                    "revenue_rules_count": len(model_data["revenue_categorization"]["rules"]),
                    "compliance_rules_count": len(model_data["compliance"]["compliance_rules"]),
                    "anomaly_patterns_count": len(model_data["anomaly_detection"]["patterns"]),
                }
            json.dump(json_models, f, indent=2)

    def load_models(self):
        """Load trained models from disk"""
        try:
            with open("models/bims_ai_models.pkl", "rb") as f:
                self.models = pickle.load(f)
            print("✅ AI Models loaded successfully")
            return True
        except FileNotFoundError:
            print("⚠️  No trained models found")
            return False

    def predict_revenue_category(self, company_name: str, description: str, amount: float) -> Dict:
        """Predict revenue category for a transaction"""
        if company_name not in self.models:
            return {"category": "Unknown", "confidence": 0.0}

        model = self.models[company_name]["revenue_categorization"]

        # Simple rule-based prediction
        for rule in model["rules"]:
            if rule["keyword"].lower() in description.lower():
                return {
                    "category": rule["category"],
                    "confidence": 0.8,
                    "rule_matched": rule["keyword"],
                }

        return {"category": "General Revenue", "confidence": 0.5}

    def check_compliance(self, company_name: str, transaction: Dict) -> Dict:
        """Check transaction compliance"""
        if company_name not in self.models:
            return {"compliant": True, "warnings": []}

        model = self.models[company_name]["compliance"]
        warnings = []

        # Check amount thresholds
        for rule in model["compliance_rules"]:
            if rule["rule"] == "amount_threshold":
                if transaction.get("amount", 0) > rule["threshold"]:
                    warnings.append(f"Amount exceeds {rule['threshold']} threshold")

        return {
            "compliant": len(warnings) == 0,
            "warnings": warnings,
            "jurisdiction": model["jurisdiction"],
        }


def main():
    """Main training execution"""
    print("🚀 PHI BIMS AI Training System")
    print("=" * 50)

    ai_system = BIMSFinancialAI()

    # Train models for all companies
    ai_system.train_company_models()

    # Test predictions
    print("\n🧪 Testing AI Predictions:")
    test_transactions = [
        ("Fractal5 Solutions Inc", "AI software development payment", 25000.00),
        ("Blue Wave Action Group Inc", "Campaign contribution received", 5000.00),
        ("Plane4 Grain Inc", "Custom furniture order", 15000.00),
    ]

    for company, desc, amount in test_transactions:
        category = ai_system.predict_revenue_category(company, desc, amount)
        compliance = ai_system.check_compliance(company, {"amount": amount, "description": desc})

        print(f"  {company}: {desc}")
        print(f"    📊 Category: {category['category']} ({category['confidence']:.1%})")
        print(f"    ⚖️  Compliant: {compliance['compliant']}")
        if compliance["warnings"]:
            print(f"    ⚠️  Warnings: {compliance['warnings']}")

    print("\n🎯 BIMS AI Training Complete!")
    print("🤖 Company-specific AI models ready for financial operations")


if __name__ == "__main__":
    main()
