#!/usr/bin/env bash
# Builds camillia_core for macOS and generates Swift bindings.
#
# Usage: scripts/build-apple.sh <out-dir> [debug|release]
#
# Produces:
#   <out-dir>/lib/libcamillia_core.a            (universal if x86_64 target is installed)
#   <out-dir>/include/camillia_coreFFI.h
#   <out-dir>/include/module.modulemap
#   <out-dir>/swift/camillia_core.swift
set -euo pipefail

OUT_DIR="$(mkdir -p "${1:?usage: build-apple.sh <out-dir> [debug|release]}" && cd "$1" && pwd)"
PROFILE="${2:-release}"
CORE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$CORE_DIR"

# Homebrew's rustup doesn't put cargo/rustc on PATH; add the active toolchain's bin dir.
if ! command -v cargo >/dev/null 2>&1; then
  PATH="$(dirname "$(rustup which cargo)"):$PATH"
fi
CARGO="cargo"

PROFILE_FLAG=""
[[ "$PROFILE" == "release" ]] && PROFILE_FLAG="--release"

TARGETS=(aarch64-apple-darwin)
if rustup target list --installed | grep -q '^x86_64-apple-darwin$'; then
  TARGETS+=(x86_64-apple-darwin)
fi

LIBS=()
for target in "${TARGETS[@]}"; do
  $CARGO build -p camillia_core --target "$target" $PROFILE_FLAG
  LIBS+=("target/$target/$PROFILE/libcamillia_core.a")
done

rm -rf "$OUT_DIR/lib" "$OUT_DIR/include" "$OUT_DIR/swift"
mkdir -p "$OUT_DIR/lib" "$OUT_DIR/include" "$OUT_DIR/swift"

if [[ ${#LIBS[@]} -gt 1 ]]; then
  lipo -create "${LIBS[@]}" -output "$OUT_DIR/lib/libcamillia_core.a"
else
  cp "${LIBS[0]}" "$OUT_DIR/lib/libcamillia_core.a"
fi

GEN_DIR="$(mktemp -d)"
trap 'rm -rf "$GEN_DIR"' EXIT
$CARGO run -q -p uniffi-bindgen -- generate \
  --library "target/${TARGETS[0]}/$PROFILE/libcamillia_core.dylib" \
  --language swift --out-dir "$GEN_DIR"

cp "$GEN_DIR/camillia_coreFFI.h" "$OUT_DIR/include/"
cp "$GEN_DIR/camillia_coreFFI.modulemap" "$OUT_DIR/include/module.modulemap"
cp "$GEN_DIR/camillia_core.swift" "$OUT_DIR/swift/"

echo "camillia_core ($PROFILE, ${TARGETS[*]}) -> $OUT_DIR"
