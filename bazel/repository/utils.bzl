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

def _get_alias_name(ctx):
    """Extract the appropriate alias name from the repository context.
    
    In bzlmod, repository names include the canonical name 
    (e.g., "module~~ext~name"), but we want the alias target to use 
    just the apparent name (e.g., "name"). In WORKSPACE mode, the 
    repository name is already the apparent name.
    
    Args:
        ctx: The repository rule context
        
    Returns:
        The apparent name to use for the alias target
    """
    if ctx.attr.alias_name:
        # Explicit override takes precedence
        return ctx.attr.alias_name
    
    # In WORKSPACE mode, ctx.name is already the apparent name
    # In bzlmod, ctx.name is canonical, so extract the last component
    if "~" in ctx.name:
        return ctx.name.split("~")[-1]
    return ctx.name

def _arch_alias_impl(ctx):
    arch = ctx.os.arch
    actual = ctx.attr.aliases.get(arch)
    if not actual:
        fail(ERROR_UNSUPPORTED.format(
            arch = arch,
            supported = ctx.attr.aliases.keys(),
        ))
    
    alias_name = _get_alias_name(ctx)
    
    ctx.file(
        "BUILD.bazel",
        ALIAS_BUILD.format(
            name = alias_name,
            actual = actual,
        ),
    )

arch_alias = repository_rule(
    implementation = _arch_alias_impl,
    attrs = {
        "aliases": attr.string_dict(
            doc = "A dictionary of arch strings, mapped to associated aliases",
        ),
        "alias_name": attr.string(
            doc = "Optional override for the alias target name (useful in bzlmod)",
            default = "",
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
    
    The alias_name parameter is explicitly set to ensure the BUILD file
    target uses the intended apparent name (from the tag), rather than
    the canonical repository name that bzlmod generates internally.
    
    Args:
        module_ctx: The module extension context
    """
    for mod in module_ctx.modules:
        for alias_tag in mod.tags.alias:
            # Pass alias_name explicitly to ensure the target name in the
            # generated BUILD file matches the user's expectation
            arch_alias(
                name = alias_tag.name,
                aliases = alias_tag.aliases,
                alias_name = alias_tag.name,
            )

arch_alias_ext = module_extension(
    implementation = _arch_alias_extension_impl,
    tag_classes = {
        "alias": _alias_tag,
    },
)
