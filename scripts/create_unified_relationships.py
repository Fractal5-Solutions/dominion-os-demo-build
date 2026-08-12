#!/usr/bin/env python3
"""NON-COMMANDING compatibility tombstone for the public proof repository."""

import sys

MESSAGE = """REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Private relationship
aggregation across CRM, email, cloud-drive, or other business data sources
belongs in governed private systems and is intentionally unavailable here.

No private data was read, combined, scored, written, or exported.
"""

sys.stderr.write(MESSAGE)
raise SystemExit(2)
