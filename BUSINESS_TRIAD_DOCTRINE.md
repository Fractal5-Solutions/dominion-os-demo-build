# Fractal5 Business Triad Doctrine

**Immutable Release Canon: Dominion OS 1.0**

This defines how Dominion OS, the F5 SaaS Suite, APIs, Agentic Professionals, and verticals are structured, priced, and released. It is the single source of truth for aligning product, catalog, and website.

## 📊 Master Catalog

- Primary Source (Cloud): https://docs.google.com/spreadsheets/d/1QCKB5IVsuHax4drNgZR9PEdHbfvd4yA6bNj2m7eDUjk/edit?usp=sharing
- Public View: https://docs.google.com/spreadsheets/d/e/2PACX-1vSASIAPnkex8zB0wopSY8zO2ZSvF73CJgv3h9viOueqKicMXDYdUUpIg792E0QTqrBn8dZt1hMvuE_O/pubhtml
- Immutable Backup (Local): docs/catalog/F5_Master_Catalog_2025_WITH_TRIADS.xlsx

All catalog entries are locked at v1.0 until commercial release. Patches increment as v1.0.n.

## 🧩 Triad Doctrine

Every vertical (BL2–BL7) consists of exactly three anchors:

- SaaS Gateway — the bundled cloud application
- API Stream — the Intelligence subscription powering it
- Agent Professional — the expert interface

No vertical is valid without all three parts.

## 🔑 Structure

1. Dominion OS Configurations (modalities): Deploy It, Extend It, License It, Use It as a Service — required for all downstream offers.
1. Verticals (BL2–BL7): each = SaaS + API + Agent (one canonical triad per vertical).
1. Microproducts: entry SKUs that ladder into the triad (funnel → SaaS/API/Agent).

## 💰 Pricing Doctrine

- OS Modalities → license-based
- SaaS → tiered bundles (Basic, Pro, Sovereign)
- APIs → subscription + unit metering (tokens/events/reports)
- Agents → role-licensed (e.g., “Compliance Officer Agent”)
- Microproducts → fixed-price, designed as funnels

## 🌐 Website Adjustments

- /cloud-engine — show OS Modalities first
- /intelligence — per vertical triads (SaaS → API → Agent)
- /solutions — organized by BL2–BL7; one triad per vertical
- /solutions#contact — canonical contact link
- Pricing Page — Modalities → SaaS → API → Agents; Microproducts at bottom with clear upsell

## 🚀 Release Discipline

- Tags: immutable v1.0.n
- Artifacts per patch: Cloud Run image (digest), Desktop EXE (SHA256), Catalog snapshot (Excel + link to Google Sheet snapshot)
- Must align code, catalog, web content

**Owner: Matthew (sovereign). Execution: PHI (autopilot).**
