#!/usr/bin/env python3
"""
Verify that MODULE.bazel dependencies are aligned with WORKSPACE dependencies.

This script checks that the versions specified in MODULE.bazel match those
defined in versions.bzl (used by WORKSPACE).
"""
import re
import sys
from pathlib import Path


def parse_module_bazel(file_path):
    """Parse bazel_dep declarations from MODULE.bazel."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    deps = {}
    for match in re.finditer(
        r'bazel_dep\(name\s*=\s*"([^"]+)",\s*version\s*=\s*"([^"]+)"\)',
        content
    ):
        deps[match.group(1)] = match.group(2)
    
    # Parse Python version
    python_match = re.search(
        r'python\.toolchain\(python_version\s*=\s*"([^"]+)"\)',
        content
    )
    python_version = python_match.group(1) if python_match else None
    
    return deps, python_version


def parse_versions_bzl(file_path):
    """Parse version definitions from versions.bzl."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Extract Python version
    python_match = re.search(r'"python":\s*"([^"]+)"', content)
    python_version = python_match.group(1) if python_match else None
    
    # Parse rule dependencies
    deps = {}
    
    # Match entries like: "rules_python": { ... "version": "1.4.1", ... }
    for match in re.finditer(
        r'"([^"]+)":\s*\{[^}]*"version":\s*"([^"]+)"[^}]*\}',
        content,
        re.DOTALL
    ):
        name = match.group(1)
        version = match.group(2)
        # Filter for rule dependencies (they typically start with rules_ or have specific prefixes)
        if any(name.startswith(prefix) for prefix in ['rules_', 'aspect_', 'bazel_', 'toolchains_']):
            deps[name] = version
    
    return deps, python_version


def main():
    script_dir = Path(__file__).parent
    module_file = script_dir / "MODULE.bazel"
    versions_file = script_dir / "versions.bzl"
    
    print("Verifying MODULE.bazel and WORKSPACE dependency alignment...")
    print()
    
    # Parse files
    module_deps, module_python = parse_module_bazel(module_file)
    workspace_deps, workspace_python = parse_versions_bzl(versions_file)
    
    print(f"MODULE.bazel: {len(module_deps)} dependencies, Python {module_python}")
    print(f"versions.bzl: {len(workspace_deps)} dependencies, Python {workspace_python}")
    print()
    
    # Check shared dependencies
    all_deps = set(module_deps.keys()) | set(workspace_deps.keys())
    shared_deps = set(module_deps.keys()) & set(workspace_deps.keys())
    
    mismatches = []
    print("Dependency Alignment Check:")
    print("-" * 70)
    
    for dep in sorted(all_deps):
        module_ver = module_deps.get(dep, "NOT IN MODULE")
        workspace_ver = workspace_deps.get(dep, "NOT IN WORKSPACE")
        
        if dep in shared_deps:
            if module_ver == workspace_ver:
                print(f"✓ {dep:25s} {module_ver}")
            else:
                print(f"✗ {dep:25s} MODULE: {module_ver}, WORKSPACE: {workspace_ver}")
                mismatches.append(dep)
        else:
            # Dependency is only in one place
            if module_ver == "NOT IN MODULE":
                print(f"ℹ {dep:25s} {workspace_ver} (WORKSPACE only)")
            else:
                print(f"ℹ {dep:25s} {module_ver} (MODULE only)")
    
    print()
    
    # Check Python version
    print("Python Version Check:")
    print("-" * 70)
    if module_python == workspace_python:
        print(f"✓ Python: {module_python}")
    else:
        print(f"✗ Python: MODULE: {module_python}, WORKSPACE: {workspace_python}")
        mismatches.append("python")
    
    print()
    print("=" * 70)
    
    if mismatches:
        print(f"✗ FAILURE: {len(mismatches)} misalignment(s) found: {', '.join(mismatches)}")
        return 1
    else:
        print("✓ SUCCESS: All shared dependencies are properly aligned!")
        return 0


if __name__ == "__main__":
    sys.exit(main())
