# Minimum Spend Public Demo Mode

**Effective:** 2026-07-24  
**Repository:** `Fractal5-Solutions/dominion-os-demo-build`  
**Scope:** public demo surface, `/demo-1`, public demo assets, and supporting demo-only endpoints

## Operating decision

Minimum Spend Mode is active for the wider Fractal5 / Dominion OS stack.

The public demo surface remains a protected client-acquisition asset. Minimum Spend Mode must reduce background and speculative cost without degrading the public story, visual presentation, or controlled demo path.

## Protected public-demo carveout

The following must remain available and presentation-safe:

- `/demo-1` as the public proof bridge;
- demo-only pages, assets, and guided scenarios;
- low-cost health/status responses;
- public-safe receipts and notices;
- contact or conversion routing for prospective clients.

The demo surface may use static, cached, or pre-rendered material wherever possible. It should not require expensive live AI calls to make the first impression work.

## Cost posture

Default posture:

- no autonomous background AI processing;
- no continuous repo, cloud, inbox, Drive, or telemetry scans;
- no premium model calls without explicit approval;
- no image, video, realtime, deep-research, or long-context generation by default;
- no remote probes unless deliberately requested by an operator;
- no always-warm infrastructure unless a paying client, scheduled demonstration, or explicit approval justifies it.

Preferred demo mechanics:

- static first screen;
- cached proof artifacts;
- demo/sample data only;
- lightweight `/health`, `/healthz`, and `/status` checks;
- remote verification only on demand;
- client-facing copy that claims only what receipts support.

## Public claim boundary

Allowed language:

```text
public demo
controlled demo
receipt-gated
governed
staged
public-safe
client-acquisition surface
```

Blocked unless current receipts support the exact claim:

```text
production-ready
certified
fully autonomous
always-on
live-certified
reconciled
tax-ready
audit-ready
100% complete
all systems operational
zero human intervention
```

## Non-impact rule

Minimum Spend Mode must not remove, visually weaken, or confuse `/demo-1`. It should make the demo sharper: less expensive machinery behind the curtain, more disciplined evidence on the surface.

## Current doctrine

Keep the demo alive. Put the expensive machinery to sleep.
