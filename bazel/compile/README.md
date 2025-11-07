# Sanitizer libraries

This directory contains build rules for creating hermetic LLVM sanitizer libraries (MSAN, TSAN) that can be used with Envoy.

## For External Consumers

If you're consuming `envoy_toolshed` as a Bazel dependency (via WORKSPACE or MODULE.bazel), you have two options:

### Option 1: Use Pre-built Artifacts (Recommended)

Download pre-built sanitizer libraries from the [GitHub Releases](https://github.com/envoyproxy/toolshed/releases):

- `msan-llvm18.1.8-x86_64.tar.xz`
- `tsan-llvm18.1.8-x86_64.tar.xz`

This is the recommended approach for most users as it avoids the need for complex build setup.

### Option 2: Build from Source

Building these targets from source requires installing compiler wrapper scripts as a one-time setup:

```bash
# Install the wrapper scripts
sudo cp bazel/compile/clang-wrapper.sh /usr/local/bin/clang-wrapper
sudo cp bazel/compile/clangxx-wrapper.sh /usr/local/bin/clang++-wrapper
sudo chmod +x /usr/local/bin/clang-wrapper /usr/local/bin/clang++-wrapper

# Ensure lld is available
sudo ln -sf /usr/bin/ld.lld /usr/bin/lld

# Then build the libraries
bazel build @envoy_toolshed//compile:cxx_tsan
bazel build @envoy_toolshed//compile:cxx_msan
```

**Why wrappers are needed:** The LLVM runtimes build requires clang, but Bazel's `rules_foreign_cc` 
passes GCC-specific flags that are incompatible with clang. The wrapper scripts filter out these 
incompatible flags while passing through all other flags.

## Building Locally

To build the libraries locally (for development or CI):

```bash
# Install wrappers (one-time setup)
sudo cp bazel/compile/clang-wrapper.sh /usr/local/bin/clang-wrapper
sudo cp bazel/compile/clangxx-wrapper.sh /usr/local/bin/clang++-wrapper
sudo chmod +x /usr/local/bin/clang-wrapper /usr/local/bin/clang++-wrapper
sudo ln -sf /usr/bin/ld.lld /usr/bin/lld

# Build
cd bazel
bazel build //compile:cxx_msan
bazel build //compile:cxx_tsan
```

This will produce:
- `bazel-bin/compile/msan-llvm18.1.8-x86_64.tar.xz`
- `bazel-bin/compile/tsan-llvm18.1.8-x86_64.tar.xz`

## Updating prebuilt versions

The sanitizer libraries are automatically built and published to GitHub releases. To update:

1. **Make changes** to the build configuration and merge them to main

2. **Create a release** with the naming format `bazel-bins-v{version}`

3. **Wait for CI** to build and publish the binaries to the release

4. **Get SHA256 hashes** for the published artifacts:
   ```bash
   curl -L https://github.com/envoyproxy/toolshed/releases/download/bazel-bins-v1.0.0/msan-llvm18.1.8-x86_64.tar.xz | sha256sum
   curl -L https://github.com/envoyproxy/toolshed/releases/download/bazel-bins-v1.0.0/tsan-llvm18.1.8-x86_64.tar.xz | sha256sum
   ```

5. **Update versions.bzl** with the new release tag and SHA256 values

## Technical Details

See the BUILD file comments for details on the wrapper approach and why it's necessary.
