use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use crate::{AppException, BridgeConfig, ConnectionRequest, FfiEnvelope, TorTunnelCore};

#[no_mangle]
pub extern "C" fn tt_core_create() -> *mut TorTunnelCore {
    Box::into_raw(Box::new(TorTunnelCore::new()))
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_destroy(core: *mut TorTunnelCore) {
    if !core.is_null() {
        drop(Box::from_raw(core));
    }
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_connect(
    core: *mut TorTunnelCore,
    request_json: *const c_char,
) -> *mut c_char {
    with_core(core, |core| {
        let request: ConnectionRequest = parse_json(request_json)?;
        let status = core.connect(request).map_err(|err| err.to_string())?;
        serde_json::to_string(&FfiEnvelope::ok(status)).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_disconnect(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        serde_json::to_string(&FfiEnvelope::ok(core.disconnect())).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_start_tor(
    core: *mut TorTunnelCore,
    bridge_json: *const c_char,
) -> *mut c_char {
    with_core(core, |core| {
        let bridge_config: BridgeConfig = parse_json(bridge_json)?;
        serde_json::to_string(&FfiEnvelope::ok(core.start_tor(bridge_config)))
            .map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_stop_tor(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        serde_json::to_string(&FfiEnvelope::ok(core.stop_tor())).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_rotate_identity(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        let status = core.rotate_identity().map_err(|err| err.to_string())?;
        serde_json::to_string(&FfiEnvelope::ok(status)).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_set_app_exceptions(
    core: *mut TorTunnelCore,
    exceptions_json: *const c_char,
) -> *mut c_char {
    with_core(core, |core| {
        let exceptions: Vec<AppException> = parse_json(exceptions_json)?;
        let updated = core.set_app_exceptions(exceptions);
        serde_json::to_string(&FfiEnvelope::ok(updated)).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_set_bridge_config(
    core: *mut TorTunnelCore,
    bridge_json: *const c_char,
) -> *mut c_char {
    with_core(core, |core| {
        let bridge_config: BridgeConfig = parse_json(bridge_json)?;
        serde_json::to_string(&FfiEnvelope::ok(core.set_bridge_config(bridge_config)))
            .map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_verify_exit(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        let verification = core.verify_exit().map_err(|err| err.to_string())?;
        serde_json::to_string(&FfiEnvelope::ok(verification)).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_export_diagnostics(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        serde_json::to_string(&FfiEnvelope::ok(core.export_diagnostics()))
            .map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_run_leak_self_test(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        serde_json::to_string(&FfiEnvelope::ok(core.run_leak_self_test()))
            .map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_status(core: *mut TorTunnelCore) -> *mut c_char {
    with_core(core, |core| {
        serde_json::to_string(&FfiEnvelope::ok(core.status())).map_err(|err| err.to_string())
    })
}

#[no_mangle]
pub unsafe extern "C" fn tt_core_free_string(value: *mut c_char) {
    if !value.is_null() {
        drop(CString::from_raw(value));
    }
}

unsafe fn with_core<F>(core: *mut TorTunnelCore, f: F) -> *mut c_char
where
    F: FnOnce(&mut TorTunnelCore) -> Result<String, String>,
{
    if core.is_null() {
        return string_to_ptr(error_json("null core pointer"));
    }

    match f(&mut *core) {
        Ok(json) => string_to_ptr(json),
        Err(error) => string_to_ptr(error_json(&error)),
    }
}

unsafe fn parse_json<T>(value: *const c_char) -> Result<T, String>
where
    T: serde::de::DeserializeOwned,
{
    if value.is_null() {
        return Err("null JSON pointer".to_string());
    }

    let json = CStr::from_ptr(value)
        .to_str()
        .map_err(|err| err.to_string())?;
    serde_json::from_str(json).map_err(|err| err.to_string())
}

fn string_to_ptr(value: String) -> *mut c_char {
    let sanitized = value.replace('\0', "");
    CString::new(sanitized)
        .expect("sanitized string should not contain nul bytes")
        .into_raw()
}

fn error_json(message: &str) -> String {
    serde_json::to_string(&FfiEnvelope::<serde_json::Value>::error(message))
        .expect("error envelope should serialize")
}
