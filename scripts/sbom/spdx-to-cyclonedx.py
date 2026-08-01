#!/usr/bin/env python3
"""Convert a Yocto create-spdx image bundle (*.spdx.tar.zst) into a CycloneDX SBOM.

Yocto's create-spdx class emits one SPDX 2.2 document per recipe/package plus
an index.json manifest — there is no single flattened "image" document, so
generic SPDX<->CycloneDX converters do not understand this bundle layout.
This script walks the bundle directly and re-projects each package-level
document into a CycloneDX 1.5 component.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path


def extract_bundle(bundle_path: Path, dest: Path) -> None:
    subprocess.run(
        ["tar", "--use-compress-program=unzstd", "-xf", str(bundle_path), "-C", str(dest)],
        check=True,
    )


def load_index(dest: Path) -> list[dict]:
    index_file = dest / "index.json"
    if not index_file.is_file():
        raise SystemExit(f"ERROR: index.json not found in extracted bundle at {dest}")
    return json.loads(index_file.read_text())["documents"]


def is_package_document(filename: str) -> bool:
    # "recipe-*" and "runtime-*" documents describe build-time/runtime
    # relationships; the bare "<name>.spdx.json" document is the installed
    # package itself.
    return not (filename.startswith("recipe-") or filename.startswith("runtime-"))


def _looks_like_spdx_id(expr: str) -> bool:
    return " " not in expr and "(" not in expr


def cyclonedx_licenses(license_expr: str | None) -> list[dict]:
    if not license_expr or license_expr in ("NOASSERTION", "NONE"):
        return []
    if _looks_like_spdx_id(license_expr):
        return [{"license": {"id": license_expr}}]
    return [{"license": {"name": license_expr}}]


def build_components(dest: Path, documents: list[dict]) -> list[dict]:
    components = []
    for doc in documents:
        filename = doc.get("filename", "")
        if not filename.endswith(".spdx.json") or not is_package_document(filename):
            continue
        doc_path = dest / filename
        if not doc_path.is_file():
            continue
        data = json.loads(doc_path.read_text())
        for pkg in data.get("packages", []):
            name = pkg.get("name")
            if not name:
                continue
            version = pkg.get("versionInfo") or "unknown"
            license_expr = pkg.get("licenseDeclared") or pkg.get("licenseConcluded")
            supplier = pkg.get("supplier")
            component = {
                "type": "library",
                "bom-ref": f"{name}@{version}",
                "name": name,
                "version": version,
                "licenses": cyclonedx_licenses(license_expr),
            }
            if supplier and supplier != "NOASSERTION":
                component["supplier"] = {"name": supplier}
            components.append(component)

    deduped: dict[tuple[str, str], dict] = {}
    for component in components:
        deduped[(component["name"], component["version"])] = component
    return sorted(deduped.values(), key=lambda c: c["name"])


def build_cyclonedx_document(components: list[dict], image_name: str) -> dict:
    return {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "component": {
                "type": "firmware",
                "name": image_name,
            }
        },
        "components": components,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path, help="Path to the *.spdx.tar.zst bundle")
    parser.add_argument("--image-name", required=True, help="Image name recorded in BOM metadata")
    parser.add_argument("--output", type=Path, required=True, help="Output CycloneDX JSON path")
    args = parser.parse_args()

    if not args.bundle.is_file():
        print(f"ERROR: SPDX bundle not found: {args.bundle}", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        dest = Path(tmp)
        extract_bundle(args.bundle, dest)
        documents = load_index(dest)
        components = build_components(dest, documents)
        bom = build_cyclonedx_document(components, args.image_name)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(bom, indent=2) + "\n")
    print(f"Wrote CycloneDX SBOM with {len(components)} components to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
