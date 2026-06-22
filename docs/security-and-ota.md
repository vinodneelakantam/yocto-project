# Security And OTA Roadmap

## Binary Signing

- Keep private signing keys off developer laptops and CI runners
- Sign images in controlled environment
- Publish checksums and signatures with release artifacts
- Verify signatures before deployment

## OTA Strategy

- Use A/B partition layout for safe updates
- Validate package/image integrity before activate switch
- Keep rollback path if health checks fail
- Track software bill of materials and update provenance

## Baseline Hardening

- Remove unused packages and services
- Enforce least privilege and secure defaults
- Enable kernel hardening options where compatible
- Add regular vulnerability scans in release process

## CI Compliance Baseline

- Generate build metadata on every CI build (`out/metadata/build-metadata.json`)
- Publish SBOM and license manifest in `out/compliance/`
- Enforce CVE gate before release artifact publication
- Run QEMU smoke test lane and include results in release artifacts
