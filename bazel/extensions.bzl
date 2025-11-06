"""Bazel module extensions for http_archive repositories"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//:versions.bzl", "VERSIONS")
load("//sysroot:sysroot.bzl", "sysroot")

def _load_http_archive_from_config(name, config):
    """Helper function to load http_archive from a VERSIONS config entry.
    
    Args:
        name: Name of the repository
        config: Configuration dict from VERSIONS with url, sha256, version, etc.
    """
    # Prepare kwargs for http_archive
    kwargs = {
        "name": name,
        "sha256": config["sha256"],
    }
    
    # Format URL with all config values
    url_format_args = {k: v for k, v in config.items() if k not in ["type", "sha256", "url", "strip_prefix", "patches", "patch_args", "build_file_content"]}
    kwargs["url"] = config["url"].format(**url_format_args)
    
    # Format strip_prefix if present
    if "strip_prefix" in config:
        kwargs["strip_prefix"] = config["strip_prefix"].format(**url_format_args)
    
    # Add optional fields if present
    if "patches" in config:
        kwargs["patches"] = config["patches"]
    if "patch_args" in config:
        kwargs["patch_args"] = config["patch_args"]
    if "build_file_content" in config:
        kwargs["build_file_content"] = config["build_file_content"]
    
    http_archive(**kwargs)

def _source_archives_impl(module_ctx):
    """Implementation of source_archives extension.
    
    This extension loads http_archive repositories for source code
    that is used in build targets (e.g., m4, autoconf, automake, libtool, llvm).
    """
    # Load source archives using helper function
    for repo_name in ["m4_source", "autoconf_source", "automake_source", "libtool_source", "llvm_source"]:
        _load_http_archive_from_config(repo_name, VERSIONS[repo_name])

source_archives = module_extension(
    implementation = _source_archives_impl,
)

def _sysroot_archives_impl(module_ctx):
    """Implementation of sysroot_archives extension.
    
    This extension loads sysroot repositories for cross-compilation.
    """
    
    # Setup AMD64 sysroot
    sysroot(
        name = "sysroot_linux_amd64",
        version = VERSIONS["bins_release"],
        sha256 = VERSIONS["sysroot_amd64_sha256"],
        arch = "amd64",
    )
    
    # Setup ARM64 sysroot
    sysroot(
        name = "sysroot_linux_arm64",
        version = VERSIONS["bins_release"],
        sha256 = VERSIONS["sysroot_arm64_sha256"],
        arch = "arm64",
    )

sysroot_archives = module_extension(
    implementation = _sysroot_archives_impl,
)

