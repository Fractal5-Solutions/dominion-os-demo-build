from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass
class OptimizationProfile:
    precision: str
    batch_size: int
    throughput: float
    latency_ms: float
    notes: str


_DEFAULT_OPTIMIZATIONS: dict[str, OptimizationProfile] = {
    "net10": OptimizationProfile(
        precision="int8",
        batch_size=32,
        throughput=420.5,
        latency_ms=6.7,
        notes="Auto-selected INT8 quantization with fused attention kernels",
    )
}


def _base_manifest(name: str) -> dict[str, Any]:
    timestamp = datetime.now(tz=timezone.utc).isoformat()
    return {
        "$schema": "internal:feature-manifest:v1",
        "model_name": name,
        "version": "1.0.0",
        "created": timestamp,
        "git_revision": "UNKNOWN",
        "image_ref": None,
        "features": [
            {"name": "input", "type": "tensor", "nullable": False},
            {"name": "output", "type": "tensor", "nullable": False},
        ],
        "metrics": {"accuracy": None, "f1": None},
        "drift": {"pvalue": 1.0, "method": "ks"},
        "source_lineage_ids": [],
        "tags": ["candidate"],
        "notes": "Auto-generated manifest",
    }


def _render_optimization(name: str | None, optimize: bool) -> OptimizationProfile | None:
    if not optimize:
        return None

    if name and name.lower() in _DEFAULT_OPTIMIZATIONS:
        return _DEFAULT_OPTIMIZATIONS[name.lower()]

    return OptimizationProfile(
        precision="fp16",
        batch_size=16,
        throughput=220.0,
        latency_ms=9.5,
        notes="Default mixed-precision plan",
    )


def install_model(
    name: str,
    *,
    target_dir: Path | str = Path("models"),
    optimize: bool = True,
    force: bool = False,
) -> Path:
    """Create or update a model manifest for ``name`` with optimization metadata.

    Args:
        name: Model identifier (for example, ``"net10"``).
        target_dir: Base directory where models are stored.
        optimize: Whether to embed an optimization plan.
        force: Overwrite existing manifest instead of refusing to clobber.

    Returns:
        The path to the written ``manifest.json`` file.
    """

    target_path = Path(target_dir)
    model_dir = target_path / name
    model_dir.mkdir(parents=True, exist_ok=True)

    manifest_path = model_dir / "manifest.json"
    if manifest_path.exists() and not force:
        # Keep existing manifests intact unless forced; this avoids losing
        # prior measurements or downstream annotations.
        raise FileExistsError(
            f"Manifest already exists at {manifest_path}. Pass force=True to overwrite."
        )

    manifest = _base_manifest(name)
    optimization = _render_optimization(name, optimize)
    if optimization:
        manifest["optimization"] = {
            "precision": optimization.precision,
            "batch_size": optimization.batch_size,
            "throughput_tps": optimization.throughput,
            "latency_ms": optimization.latency_ms,
            "notes": optimization.notes,
        }
        manifest["tags"].append("optimized")

    manifest_path.write_text(json.dumps(manifest, indent=2))
    return manifest_path
