"""Public-safe Canon Phi command core runtime.

This package intentionally contains only serving-layer adapters and public-safe
logic. The authoritative control plane remains outside this public demo repo.
"""

from .routes import phi_public_core

__all__ = ["phi_public_core"]
