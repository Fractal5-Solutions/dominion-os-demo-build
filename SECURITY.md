# Security boundary

This repository is a **public demonstration boundary** for Dominion OS™ + SaaS Suite.

Do not commit or publish:

- secrets, credentials, tokens, private keys, signing material, or recovery data;
- customer, payment, regulated, confidential, or private operational data;
- private source code, internal automation, infrastructure definitions, deployment authority, or production-control material;
- private APIs, internal service endpoints, privileged commands, or alternate command-plane behavior.

The public repository must remain presentation-artifact-only. Provider deployment readiness does not imply that a public provider runtime is continuously available. Runtime claims fail closed and require separate current machine-produced evidence.

If sensitive material is discovered, exposure containment and credential rotation/revocation take precedence over history cleanup. Git-history removal alone is not a substitute for rotating an exposed secret.

Please report security concerns privately through Fractal5 Solutions rather than opening a public issue:
https://www.fractal5solutions.com/#contact
