# camillia-app-core

Shared Rust core for the Camillia desktop apps. Business logic lives here; each
platform keeps a native UI and calls into this crate via [UniFFI](https://mozilla.github.io/uniffi-rs/)-generated bindings.

| Frontend | Repo | Bindings |
|---|---|---|
| macOS (SwiftUI) | [camillia-app-mac](https://github.com/oumike/camillia-app-mac) | Swift, UniFFI built-in |
| Windows (WinUI 3) | [camillia-app-win](https://github.com/oumike/camillia-app-win) | C#, [uniffi-bindgen-cs](https://github.com/NordSecurity/uniffi-bindgen-cs) |

Both frontends include this repo as a git submodule at `core/`.

## Layout

- `src/lib.rs`: the exported API (`#[uniffi::export]`)
- `uniffi-bindgen/`: pinned bindgen CLI used for Swift generation
- `scripts/build-apple.sh`: static lib + Swift bindings
- `scripts/build-windows.ps1`: DLL + C# bindings

## Versions

`uniffi` is pinned to `=0.31.0` to match `uniffi-bindgen-cs` `v0.11.0+v0.31.0`.
Bump both together.

## Develop

```sh
cargo test
scripts/build-apple.sh /tmp/camillia-apple          # macOS
```

```powershell
scripts\build-windows.ps1 -OutDir $env:TEMP\camillia-win   # Windows
```

## Updating a frontend

After pushing changes here, in the frontend repo:

```sh
git submodule update --remote core
git commit -am "Bump core"
```
