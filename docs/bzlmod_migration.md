# Bzlmod Migration for envoy_toolshed

This document describes the bzlmod migration for the envoy_toolshed repository and provides guidance for consumers using this repository as a dependency.

## Overview

Envoy_toolshed has been migrated to support Bazel's new module system (bzlmod) while maintaining backward compatibility with the legacy WORKSPACE mode. This migration addresses **Blocker #3** from the main Envoy bzlmod migration.

## Key Changes

### MODULE.bazel Configuration

The repository now includes a `bazel/MODULE.bazel` file that defines:

- **Module name**: `envoy_toolshed`
- **Version**: `0.3.8-dev`
- **Dependencies**: All required Bazel modules with specific versions

### LLVM Toolchain Removal

The LLVM extension and toolchains_llvm dependency have been removed from MODULE.bazel because:

1. **Extension limitations**: LLVM toolchain extensions can only be used by root modules in bzlmod
2. **Not required**: This repository doesn't compile C/C++ code that requires the LLVM toolchain
3. **WORKSPACE mode**: LLVM toolchain configuration remains available in WORKSPACE mode for building sanitizer libraries

**Note**: If you need to build the LLVM sanitizer libraries (targets like `//compile:cxx_msan` or `//compile:cxx_tsan`), you must use WORKSPACE mode, not bzlmod mode.

### JQ Toolchain Configuration

The JQ toolchain is configured with an explicit version to ensure consistency:

```starlark
bazel_lib_toolchains = use_extension("@aspect_bazel_lib//lib:extensions.bzl", "toolchains")
bazel_lib_toolchains.jq(version = "1.7")
use_repo(bazel_lib_toolchains, "jq", "jq_toolchains")
```

This aligns with the aspect_bazel_lib version used in WORKSPACE mode (2.16.0).

## Using envoy_toolshed as a Dependency

### In bzlmod Mode

To use envoy_toolshed as a dependency in your MODULE.bazel file:

```starlark
# Option 1: Using a git_override (for development/testing)
bazel_dep(name = "envoy_toolshed", version = "0.3.8-dev")
git_override(
    module_name = "envoy_toolshed",
    remote = "https://github.com/envoyproxy/toolshed.git",
    commit = "<commit-hash>",
    strip_prefix = "bazel",
)

# Option 2: Using archive_override
bazel_dep(name = "envoy_toolshed", version = "0.3.8-dev")
archive_override(
    module_name = "envoy_toolshed",
    urls = ["https://github.com/envoyproxy/toolshed/archive/<commit-hash>.tar.gz"],
    strip_prefix = "toolshed-<commit-hash>/bazel",
)
```

**Important**: Note the `strip_prefix = "bazel"` parameter. The MODULE.bazel file is located in the `bazel/` subdirectory, not at the repository root.

### In WORKSPACE Mode

WORKSPACE mode continues to work as before:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "envoy_toolshed",
    remote = "https://github.com/envoyproxy/toolshed.git",
    commit = "<commit-hash>",
)

load("@envoy_toolshed//:archives.bzl", "load_archives")
load_archives()

load("@envoy_toolshed//:deps.bzl", "resolve_dependencies")
resolve_dependencies()

load("@envoy_toolshed//:toolchains.bzl", "load_toolchains")
load_toolchains()
```

## Module Dependencies

The following dependencies are declared in MODULE.bazel with their specific versions:

- `aspect_bazel_lib@2.16.0` - Bazel utility library (provides jq toolchain)
- `bazel_skylib@1.7.1` - Bazel standard library
- `platforms@1.0.0` - Platform definitions
- `rules_foreign_cc@0.14.0` - Build rules for C/C++ libraries
- `rules_perl@0.4.1` - Perl toolchain rules
- `rules_pkg@1.0.1` - Package creation rules
- `rules_python@1.4.1` - Python rules (supports versions 3.9-3.13)
- `rules_shell@0.6.1` - Shell script rules

## Python Support

The MODULE.bazel file configures Python toolchains for multiple versions:

- Python 3.9
- Python 3.10
- Python 3.11
- Python 3.12
- Python 3.13 (default)

## Build Modes

### bzlmod Mode (Enabled)

To use bzlmod mode explicitly:

```bash
cd bazel
bazel build //target --enable_bzlmod
```

Or set in `.bazelrc`:

```
# Enable bzlmod by default
common --enable_bzlmod
```

### WORKSPACE Mode (Legacy)

To continue using WORKSPACE mode:

```bash
cd bazel
bazel build //target --noenable_bzlmod
```

## Compatibility Notes

### What Works in bzlmod Mode

- All Python-based tools and targets
- JQ-based utilities
- Format checking tools
- Dependency management tools
- Autotools building (m4, autoconf, automake, libtool)

### What Requires WORKSPACE Mode

- Building LLVM sanitizer libraries (`//compile:cxx_msan`, `//compile:cxx_tsan`)
  - These targets build LLVM runtime libraries from source and require the LLVM toolchain configuration in WORKSPACE mode

## Testing

To verify the bzlmod migration:

```bash
cd bazel

# Test module graph resolution
bazel mod graph --enable_bzlmod

# Test a simple build
bazel build //format/clang_tidy:clang_tidy --enable_bzlmod

# Test WORKSPACE mode still works
bazel build //format/clang_tidy:clang_tidy --noenable_bzlmod
```

## Migration from WORKSPACE to bzlmod

If you're migrating your own project from using envoy_toolshed in WORKSPACE mode to bzlmod:

1. Add `bazel_dep(name = "envoy_toolshed", version = "0.3.8-dev")` to your MODULE.bazel
2. Add appropriate override (git_override or archive_override) with `strip_prefix = "bazel"`
3. Remove WORKSPACE loads for envoy_toolshed
4. Test your builds with `--enable_bzlmod`

## Known Limitations

1. **LLVM toolchain unavailable in bzlmod mode**: The LLVM toolchain is only configured in WORKSPACE mode. If you need C/C++ compilation with specific toolchain features, you must use WORKSPACE mode or configure the LLVM toolchain yourself in your root MODULE.bazel.

2. **Strip prefix required**: When using git_override or archive_override, you must specify `strip_prefix = "bazel"` because the MODULE.bazel is in a subdirectory.

3. **Sanitizer library builds**: Targets that build LLVM sanitizer libraries require WORKSPACE mode.

## Future Work

- Evaluate publishing envoy_toolshed to the Bazel Central Registry (BCR)
- Consider restructuring repository to have MODULE.bazel at root instead of in `bazel/` subdirectory
- Investigate whether sanitizer library builds can work in bzlmod mode

## References

- [Bazel bzlmod documentation](https://bazel.build/external/module)
- [Module extensions documentation](https://bazel.build/external/extension)
- [Envoy bzlmod migration document](https://github.com/mmorel-35/envoy/blob/copilot/document-bzlmod-migration/docs/bzlmod_migration.md)
- [Bazel Central Registry](https://registry.bazel.build/)

## Support

For issues related to bzlmod support in envoy_toolshed, please file an issue on the [toolshed repository](https://github.com/envoyproxy/toolshed/issues).
