# Bazel Dependency Alignment

## Overview
This document describes the alignment between MODULE.bazel (bzlmod) and WORKSPACE dependency management systems.

## Dependency Versions

The following dependencies are shared between MODULE.bazel and WORKSPACE (via versions.bzl):

| Dependency | Version | Notes |
|------------|---------|-------|
| aspect_bazel_lib | 2.16.0 | Build tools and utilities |
| bazel_skylib | 1.4.2 | Core Bazel library |
| rules_foreign_cc | 0.14.0 | Foreign build system rules |
| rules_perl | 0.4.1 | Perl toolchain support |
| rules_python | 1.4.1 | Python rules |
| Python | 3.12 | Python interpreter version |

## MODULE.bazel Only Dependencies

The following dependencies are only used in MODULE.bazel:

| Dependency | Version | Purpose |
|------------|---------|---------|
| rules_pkg | 0.7.0 | Package building (used for website builds) |

## WORKSPACE Only Dependencies

The following dependencies are only used in WORKSPACE:

| Dependency | Version | Purpose |
|------------|---------|---------|
| toolchains_llvm | 1.4.0 | LLVM toolchain configuration |

## Verification

To verify that dependencies are aligned, run:

```bash
cd bazel
python3 verify_version_alignment.py
```

This script will check that all shared dependencies have matching versions between MODULE.bazel and versions.bzl.

## Updating Dependencies

When updating dependency versions:

1. Update the version in `versions.bzl` for WORKSPACE-based builds
2. Update the corresponding version in `MODULE.bazel` for bzlmod-based builds
3. Run the verification script to ensure alignment
4. Test with both build systems:
   - `bazel build --noenable_bzlmod //...` (WORKSPACE)
   - `bazel build --enable_bzlmod //...` (MODULE.bazel)

## Notes

- MODULE.bazel is the newer Bazel module system (bzlmod)
- WORKSPACE is the traditional Bazel dependency management
- Both are supported to allow gradual migration
- Version alignment is critical for consistent builds across both systems
