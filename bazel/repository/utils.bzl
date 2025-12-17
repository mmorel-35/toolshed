"""Repository rule for defining a host platform based on CPU architecture.

This allows you to set a single alias for multiple architectures, that resolve
to arch-specific targets. Using `native.alias` and `select` for this doesn't work
when using an arch as the selector.

This can be useful specifically for setting the `host_platform`.

Example usage:

In WORKSPACE:

```starlark
load("@envoy_toolshed//bazel/repository:utils.bzl", "arch_alias")

arch_alias(
    name = "clang_platform",
    aliases = {
        "amd64": "@envoy//bazel/platforms/rbe:rbe_linux_x64_clang_platform",
        "aarch64": "@envoy//bazel/platforms/rbe:rbe_linux_arm64_clang_platform",
    },
)
```

In MODULE.bazel (bzlmod):

```starlark
arch_alias_ext = use_extension("@envoy_toolshed//bazel/repository:utils.bzl", "arch_alias_ext")
arch_alias_ext.alias(
    name = "clang_platform",
    aliases = {
        "amd64": "@envoy//bazel/platforms/rbe:rbe_linux_x64_clang_platform",
        "aarch64": "@envoy//bazel/platforms/rbe:rbe_linux_arm64_clang_platform",
    },
)
use_repo(arch_alias_ext, "clang_platform")
```

And then in .bazelrc:

```
common:clang-common --host_platform=@clang_platform
```

"""

ERROR_UNSUPPORTED = """
Unsupported host architecture '{arch}'. Supported architectures are: {supported}
"""

ALIAS_BUILD = """
alias(
    name = "{name}",
    actual = "{actual}",
    visibility = ["//visibility:public"],
)
"""

def _arch_alias_impl(ctx):
    arch = ctx.os.arch
    actual = ctx.attr.aliases.get(arch)
    if not actual:
        fail(ERROR_UNSUPPORTED.format(
            arch = arch,
            supported = ctx.attr.aliases.keys(),
        ))
    ctx.file(
        "BUILD.bazel",
        ALIAS_BUILD.format(
            name = ctx.name,
            actual = actual,
        ),
    )

arch_alias = repository_rule(
    implementation = _arch_alias_impl,
    attrs = {
        "aliases": attr.string_dict(
            doc = "A dictionary of arch strings, mapped to associated aliases",
        ),
    },
)

# Bzlmod extension for arch_alias
_alias_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "Name of the alias repository",
            mandatory = True,
        ),
        "aliases": attr.string_dict(
            doc = "A dictionary of arch strings, mapped to associated aliases",
            mandatory = True,
        ),
    },
)

def _arch_alias_extension_impl(module_ctx):
    """Module extension implementation for arch_alias.
    
    This allows arch_alias to be used with bzlmod by creating repositories
    based on the tags defined in MODULE.bazel files.
    """
    for mod in module_ctx.modules:
        for alias_tag in mod.tags.alias:
            arch_alias(
                name = alias_tag.name,
                aliases = alias_tag.aliases,
            )

arch_alias_ext = module_extension(
    implementation = _arch_alias_extension_impl,
    tag_classes = {
        "alias": _alias_tag,
    },
)
