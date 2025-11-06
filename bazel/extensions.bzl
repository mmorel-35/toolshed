"""Bazel module extensions for http_archive repositories"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//:versions.bzl", "VERSIONS")
load("//sysroot:sysroot.bzl", "sysroot")

def _source_archives_impl(module_ctx):
    """Implementation of source_archives extension.
    
    This extension loads http_archive repositories for source code
    that is used in build targets (e.g., m4, autoconf, automake, libtool, llvm).
    """
    
    # Load m4_source
    m4_config = VERSIONS["m4_source"]
    http_archive(
        name = "m4_source",
        sha256 = m4_config["sha256"],
        url = m4_config["url"].format(version = m4_config["version"]),
        strip_prefix = m4_config["strip_prefix"].format(version = m4_config["version"]),
        patches = m4_config.get("patches", []),
        patch_args = m4_config.get("patch_args", []),
        build_file_content = m4_config["build_file_content"],
    )
    
    # Load autoconf_source
    autoconf_config = VERSIONS["autoconf_source"]
    http_archive(
        name = "autoconf_source",
        sha256 = autoconf_config["sha256"],
        url = autoconf_config["url"].format(version = autoconf_config["version"]),
        strip_prefix = autoconf_config["strip_prefix"].format(version = autoconf_config["version"]),
        build_file_content = autoconf_config["build_file_content"],
    )
    
    # Load automake_source
    automake_config = VERSIONS["automake_source"]
    http_archive(
        name = "automake_source",
        sha256 = automake_config["sha256"],
        url = automake_config["url"].format(version = automake_config["version"]),
        strip_prefix = automake_config["strip_prefix"].format(version = automake_config["version"]),
        build_file_content = automake_config["build_file_content"],
    )
    
    # Load libtool_source
    libtool_config = VERSIONS["libtool_source"]
    http_archive(
        name = "libtool_source",
        sha256 = libtool_config["sha256"],
        url = libtool_config["url"].format(version = libtool_config["version"]),
        strip_prefix = libtool_config["strip_prefix"].format(version = libtool_config["version"]),
        build_file_content = libtool_config["build_file_content"],
    )
    
    # Load llvm_source
    llvm_config = VERSIONS["llvm_source"]
    http_archive(
        name = "llvm_source",
        sha256 = llvm_config["sha256"],
        url = llvm_config["url"].format(
            repo = llvm_config["repo"],
            version = llvm_config["version"],
        ),
        strip_prefix = llvm_config["strip_prefix"].format(version = llvm_config["version"]),
        build_file_content = llvm_config["build_file_content"],
    )

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

