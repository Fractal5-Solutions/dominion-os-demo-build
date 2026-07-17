# Dominion OS™ + SaaS Suite — Customer Lifecycle Control

## Scope

This document governs controlled commercial customers until automated tenant provisioning and a customer portal are separately implemented and proven.

## Onboarding

Before access is granted, record:

- accepted order, statement of work, or procurement authorization;
- named customer sponsor and Fractal5 service owner;
- approved users and least-privilege roles;
- deployment and data boundary;
- prohibited data classes;
- support channel and response target;
- start date, term, and review date;
- acceptance test and rollback owner.

Credentials must be delivered through an approved private channel. They must never appear in public receipts, email bodies containing unrelated parties, source control, or public demo assets.

## Entitlement lifecycle

Each entitlement requires a unique internal reference and must record:

- product or service scope;
- authorized organization and users;
- role and permissions;
- effective and expiry dates;
- provisioning approver;
- last access review;
- suspension and revocation state.

Access reviews occur at onboarding, material scope change, renewal, suspected compromise, and offboarding.

## Support

Commercial customers receive a named support path. Support records classify severity, customer impact, data sensitivity, owner, response, resolution, and follow-up. No production credentials or confidential payloads enter public issue trackers.

## Cancellation, refund, and offboarding

The written order controls financial terms. Fractal5 must:

1. acknowledge cancellation or non-renewal;
2. stop new use at the agreed time;
3. revoke credentials and entitlements;
4. preserve legally required commercial records;
5. return or delete customer-provided data according to the agreement;
6. record completion and unresolved obligations;
7. issue any approved credit or refund through the accounting process.

## Privacy and data handling

Default posture is data minimization. The public demo contains no customer data. A commercial deployment may process only data explicitly authorized by the order and documented boundary. Sensitive or regulated data requires a separate written review before ingestion.

## Evidence gate

The lifecycle gate becomes GREEN only when a real customer onboarding produces a private operational record and a public-safe redacted receipt proving provisioning, entitlement ownership, support path, and offboarding readiness without exposing customer information.