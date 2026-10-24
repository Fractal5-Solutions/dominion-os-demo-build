# Free offline preview candidate

This release lane packages the already-public synthetic Business and Politics
presentation. It does not build or certify the native Dominion product, the
core runtime, SaaS, a connector, or a Google deployment. The owner's request for
free downloadable previews expands the historical Politics presentation scope;
it does not change the native Windows signing and exact-artifact gates.

The input is the exact `demo/live-mission-demo.html` Git blob from public
candidate `c2e066cfc1c95cba129bbadcd864833a05e86d99`. The builder rejects a raw
HTML SHA-256 other than
`6e8ca733f3dbd3798064b47309c1cfd56b29957c5f27d39593d9d1a9295eedb2`.
It reads that immutable Git object rather than the working file. The generated
offline HTML has a separate hash because it adds restrictive CSP, preview
labels, and disables automatic progression. Both identities are recorded.

The ZIP contains only `index.html`, `README.txt`, `DEMO-TERMS.txt`, and
`demo-manifest.json`. It contains the public presentation HTML/CSS/JavaScript,
not private product source. No installer, executable, launcher, credentials,
API client, private data, external resource, or startup registration is added.
The terms permit free local preview/evaluation and unchanged preview copies;
production software and operational authority remain outside that permission.

Build outside the source repository:

```powershell
py -3 scripts/build_offline_preview.py --output-dir C:\path\outside-repo\offline-preview-candidate
py -3 -m unittest discover -s tests -p test_offline_preview_package.py -v
node --test tests/live-mission-approval.test.cjs
```

The builder writes the deterministic ZIP, detached SHA-256, and a local build
receipt. Generated packages and receipts are not committed. The payload
manifest hashes its other three files; the detached receipt hashes all four
entries and the ZIP, avoiding an impossible self-hash claim. Archive closure,
paths, ordinary nonexecutable files, exact bytes, and content boundaries are
verified before an artifact is written.

Source validation is separate from browser and malware checks. Acceptance of
the exact generated ZIP additionally requires extraction and `file://` browser
verification of both missions, native Hold/approval keyboard activation,
receipt consistency, reset/mode separation, zero external requests/storage,
and a fresh malware scan. No Authenticode or malware PASS is invented by the
packager.

`demo/assets/offline-preview-download.json` is a separate fail-closed preview
status record. It starts with `publicUrl: null`, no accepted package digest,
and pending Google certification. Google deployment acceptance comes first,
then exact preview-artifact release acceptance, then approved public activation.
Neither a locally generated ZIP nor a Squarespace source change earns those
gates. The existing native download manifests and provider policies remain
separate.
