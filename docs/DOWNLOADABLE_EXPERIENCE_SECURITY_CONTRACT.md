# Dominion OS 1.0 Downloadable Experience Security Contract

## Product promise

The downloadable experience is the real Dominion OS 1.0 product runtime, not a simulated mock-up. It is designed to run in the customer's own controlled estate: Windows x64, Google Cloud, customer-controlled containers, authorized drives, and authorized connectors.

## Distribution boundary

The package may contain only the minimum artifacts required to operate the product:
- signed Windows executables and required runtime libraries;
- signed/minimized container images or image references;
- public deployment manifests and configuration schemas;
- connector interfaces and customer-facing bootstrap tooling;
- release receipts, digests, license metadata, and public documentation.

It must not contain source repositories, .git history, build pipelines, debug symbols, test fixtures, developer-only tooling, internal runbooks, operator configuration, Fractal5 production data, or private infrastructure state.

## Secrets and identity

No Fractal5 secret, credential, token, API key, private key, signing key, service-account credential, OAuth refresh token, or customer credential may be embedded in a downloadable artifact.

Customer credentials must be provided at install or runtime through customer-controlled authentication and secret stores. Google Cloud identity should use short-lived customer-estate identity where possible rather than static credentials.

## Reverse-engineering posture

The release objective is strong resistance and minimal intellectual-property exposure, not an impossible guarantee. Executable software delivered to a customer-controlled machine can be inspected. Public language must therefore say "hardened," "source code not distributed," and "reverse-engineering resistant" rather than "impossible to reverse engineer."

Release builds should be stripped, minimized, signed, and free of source maps/debug symbols unless explicitly required. Container images must exclude shells and package managers where operationally unnecessary and must contain no source tree, VCS metadata, caches, credentials, or development dependencies.

## Experience parity

"Same experience" means the customer receives the same product UX, workflow, governance model, connector contract, and supported SaaS behavior that constitutes Dominion OS 1.0. It does not mean disclosure of Fractal5's internal source, build system, operator tools, or proprietary control-plane implementation.

## Mandatory public-download gate

A public Windows download is prohibited until the exact downloadable artifact passes all of the following:
1. digest-bound release receipt and signature verification;
2. source/VCS/debug/development-artifact exclusion scan;
3. secret and credential scan;
4. malware/dependency/vulnerability scan;
5. clean-machine Windows install, launch, update, uninstall, and recovery test;
6. customer-owned Google Cloud deployment test using non-Fractal5 credentials;
7. connector authorization/revocation test with customer-owned test accounts;
8. proof that no Fractal5 production endpoint, secret, or privileged control is required;
9. network egress inventory and privacy review;
10. final human approval before publishing the download URL.

## Public wording

"Download Dominion OS 1.0 for Windows. Connect it to your own Google Cloud, containers, drives, and authorized services. Experience the same Dominion OS product architecture used in production—without receiving Fractal5 source code, internal credentials, secrets, or proprietary operational infrastructure."
