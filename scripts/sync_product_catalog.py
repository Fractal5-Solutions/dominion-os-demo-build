import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest_path = ROOT / "demo" / "assets" / "dominion-product-manifest.v1.json"
catalog_path = ROOT / "demo" / "assets" / "dominion-saas-catalog.json"

manifest_bytes = manifest_path.read_bytes()
manifest = json.loads(manifest_bytes.decode("utf-8-sig"))
catalog = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
by_name = {m["name"]: m for m in manifest["modules"]}

for module in catalog["modules"]:
    source = by_name[module["name"]]
    for key in ("id", "sku", "implementation_state", "standalone_ga"):
        module[key] = source[key]

catalog["canonical_manifest"] = {
    "authority": "dominion-os-core/config/dominion-product-manifest.v1.json",
    "snapshot_path": "demo/assets/dominion-product-manifest.v1.json",
    "snapshot_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
}
catalog["independent_ga_claim"] = False
catalog["universal_api_claim"] = False
catalog["marketplace_listing_claim"] = False
with catalog_path.open("w", encoding="utf-8", newline="\n") as handle:
    handle.write(json.dumps(catalog, indent=2) + "\n")
print(catalog["canonical_manifest"]["snapshot_sha256"])
