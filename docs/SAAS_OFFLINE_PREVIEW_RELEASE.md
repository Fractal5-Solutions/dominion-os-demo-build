# Free synthetic SaaS Suite preview candidate

This separate package gives every one of the 13 public catalogue modules a
fixed Business and neutral civic administration example. It is an interactive
presentation, not a distribution or implementation of the actual production
modules. Catalogue availability and Coming Soon labels are preserved.

The source HTML and catalogue are read from immutable public commit
`5e80d1824be37a124f4d001fcc3a2fb8b3656f56`. The builder pins both raw hashes,
checks all 13 identities and availability states against that catalogue, and
reuses the ordinary-file archive closure and content validator from the OS
preview packager without modifying that packager or its existing ZIP.

Each module progresses through fixed input, sample plan, explicit review, and
simulated receipt. Approval cannot be inferred from progression. Hold blocks
both approval and progression across all modules. Module selection preserves
its in-memory review state. Reset and mode changes clear every approval and
receipt; Hold persists until explicitly resumed. There are no timers, input
fields, external resources, requests, connectors, persistent storage, or system
changes. Politics covers neutral service administration, never voter profiling,
political-position inference, targeting, or persuasion.

Build outside the repository:

```powershell
py -3 scripts/build_saas_offline_preview.py --output-dir C:\path\outside-repo\saas-preview
py -3 -B -m unittest discover -s tests -p test_saas_offline_preview.py -v
node --test tests/saas-offline-preview.test.cjs
```

The deterministic ZIP contains exactly `index.html`, `README.txt`,
`DEMO-TERMS.txt`, and `demo-manifest.json`, with ordinary nonexecutable files,
fixed timestamps, and no compression-dependent reproducibility. The manifest
hashes the other three entries. Its own hash and the ZIP hash are in the detached
receipt. The receipt also records the packager head, its actual file hash, and
whether that hash matches the head blob. No private source or generated package
is committed.

Source, archive, and Node VM checks do not prove browser rendering, native
keyboard activation, or browser CSP enforcement. Actual `file://` browser
acceptance and a fresh exact-ZIP malware scan remain separate release gates.
The current tool policy denies `file://`; that check must remain unverified
without any alternate-browser or localhost workaround. No scan result is
invented by packaging.

`demo/assets/saas-offline-preview-download.json` has no URL or accepted digest.
Google certification must precede exact preview acceptance and approved public
activation. The existing Squarespace download buttons remain disabled and its
handoff remains unchanged. No new Pages route or publisher entry is added.
