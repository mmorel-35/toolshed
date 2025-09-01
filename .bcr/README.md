# BCR Publishing Setup

This repository is configured to automatically publish to the [Bazel Central Registry (BCR)](https://github.com/bazelbuild/bazel-central-registry) when releases prefixed with `bazel-` are created.

## Configuration

The BCR publishing setup includes:

- **Metadata**: `.bcr/metadata.json` - Contains module metadata with phlax as the default maintainer
- **Presubmit**: `.bcr/presubmit.yml` - Defines build and test targets for BCR validation
- **Workflow**: `.github/workflows/bcr-publish.yml` - Automated publishing workflow
- **Helper Script**: `tools/bcr-publish.sh` - Manual publishing utility

## Automatic Publishing

When a release is created with a name starting with `bazel-`, the workflow will:

1. Extract the version from the release tag (removing the `bazel-` prefix)
2. Download and hash the source archive
3. Generate BCR submission files
4. Create an artifact with the submission files

## Manual Publishing

For manual BCR publishing, use the helper script:

```bash
./tools/bcr-publish.sh bazel-1.0.0
```

This will create BCR submission files in `bcr-submission/modules/envoy_toolshed/VERSION/`

## BCR Submission Process

After the workflow runs or you use the manual script:

1. Create a fork of https://github.com/bazelbuild/bazel-central-registry
2. Copy the generated files to `modules/envoy_toolshed/VERSION/` in your fork
3. Update the `versions` array in `modules/envoy_toolshed/metadata.json`
4. Create a pull request to the BCR repository

## Maintainer Information

The default maintainer for BCR submissions is configured as:
- **Name**: Ryan Northey (phlax)
- **GitHub**: @phlax
- **Email**: phlax@users.noreply.github.com

This can be updated in `.bcr/metadata.json` if needed.