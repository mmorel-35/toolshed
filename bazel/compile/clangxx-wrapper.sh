#!/bin/bash
# Wrapper script to filter out GCC-specific flags that clang++ doesn't support

args=()
for arg in "$@"; do
    case "$arg" in
        -fno-canonical-system-headers)
            # Skip this GCC-specific flag
            ;;
        -Wno-free-nonheap-object)
            # Skip this GCC-specific flag
            ;;
        -pass-exit-codes)
            # Skip this GCC-specific linker flag
            ;;
        -fuse-ld=gold)
            # Skip gold linker, we use lld
            ;;
        -B/usr/bin)
            # Skip binutils path
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

exec clang++ "${args[@]}"
