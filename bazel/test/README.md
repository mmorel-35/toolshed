# arch_alias Extension Test Module

This directory contains a BCR-compatible test module for the `arch_alias` bzlmod extension.

## Purpose

This test module validates:
1. The `arch_alias_ext` module extension works correctly in bzlmod mode
2. Multiple arch aliases can be created in the same module
3. The aliases resolve to the correct platform targets based on host architecture
4. The aliases can be used in `.bazelrc` configurations

## Usage

### Running Tests Locally

From this directory:

```bash
bazel build //...
bazel test //...
```

### BCR Presubmit

This test module is automatically run during BCR presubmit checks. It validates that the module works correctly across different:
- Operating systems (Linux, macOS)
- Architectures (amd64, aarch64)
- Bazel versions (7.x, 8.x, 9.x)

## Test Structure

### MODULE.bazel
Defines the test module and configures the `arch_alias_ext` extension with test aliases:
- `test_platform` - Generic platform alias for basic functionality
- `test_clang_platform` - Secondary alias to test multiple repositories

### BUILD.bazel
Contains simple build targets that exercise the platform aliases through the build configuration.

### .bazelrc
Configures the build to use `@test_platform` as the `--host_platform`, validating that:
1. The alias repository is created successfully
2. The alias resolves to a valid platform target
3. Bazel can use the platform for build configurations

## Architecture Support

The test covers common architecture strings:
- `amd64` / `x86_64` - Intel/AMD 64-bit
- `aarch64` / `arm64` - ARM 64-bit

All architectures in the test map to `@platforms//host` or `@platforms//os:linux` for simplicity.

## Integration with BCR

This test module follows BCR best practices:
1. Located in `bazel/test/` relative to the module root
2. Uses `local_path_override` to test the parent module
3. Can be run independently or as part of BCR presubmit
4. Tests the module's public API (the `arch_alias_ext` extension)
