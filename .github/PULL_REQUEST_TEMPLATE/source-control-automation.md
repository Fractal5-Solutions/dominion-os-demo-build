## Source-Control Automation Evidence

### Scope

- [ ] Source-only change
- [ ] Workflow / automation change
- [ ] Documentation change
- [ ] Runtime / deployment change

### Production impact

Describe whether this PR touches public surfaces, runtime code, deployment workflows, secrets, private APIs, customer data, payment systems, or signing keys.

### Gate evidence

| Gate | State | Classification | Required |
| --- | --- | --- | --- |
| _fill from automation_ | _state_ | _green/red/blocked/pending/unknown_ | _yes/no_ |

### Merge doctrine

- [ ] No force-push required.
- [ ] No direct `main` write.
- [ ] No red or unknown required gates.
- [ ] Startup failures are repaired, reclassified with rationale, or escalated.
- [ ] Public-surface policy remains intact.

### Decision

- [ ] Merge-ready
- [ ] Blocked pending repair
- [ ] Blocked pending repository or organization setting

### Evidence notes

Record head SHA, changed files, and any relevant workflow/run identifiers.
