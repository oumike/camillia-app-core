//! Shared core for the Camillia apps.
//!
//! Everything exported with `#[uniffi::export]` is available to the Swift
//! (macOS) and C# (Windows) frontends through generated bindings.

uniffi::setup_scaffolding!();

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum CoreError {
    #[error("invalid input: {reason}")]
    InvalidInput { reason: String },
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct CoreInfo {
    pub name: String,
    pub version: String,
}

/// Name and version of the linked core library.
#[uniffi::export]
pub fn core_info() -> CoreInfo {
    CoreInfo {
        name: env!("CARGO_PKG_NAME").to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    }
}

/// Smoke-test function used by both frontends to confirm the FFI link works.
#[uniffi::export]
pub fn greet(name: String) -> Result<String, CoreError> {
    let name = name.trim();
    if name.is_empty() {
        return Err(CoreError::InvalidInput {
            reason: "name must not be empty".to_string(),
        });
    }
    Ok(format!("Hello, {name}, from camillia_core"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_formats_name() {
        assert_eq!(greet("Mac".into()).unwrap(), "Hello, Mac, from camillia_core");
    }

    #[test]
    fn greet_rejects_empty() {
        assert!(matches!(greet("  ".into()), Err(CoreError::InvalidInput { .. })));
    }

    #[test]
    fn core_info_reports_crate() {
        assert_eq!(core_info().name, "camillia_core");
    }
}
