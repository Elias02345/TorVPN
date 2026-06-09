import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _CreateNative = Pointer<Void> Function();
typedef _DestroyNative = Void Function(Pointer<Void>);
typedef _JsonNoArgNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _JsonOneArgNative =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _FreeStringNative = Void Function(Pointer<Utf8>);

typedef _CreateDart = Pointer<Void> Function();
typedef _DestroyDart = void Function(Pointer<Void>);
typedef _JsonNoArgDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _JsonOneArgDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class TorTunnelFfiLibrary {
  TorTunnelFfiLibrary._(this._library)
    : _create = _library.lookupFunction<_CreateNative, _CreateDart>(
        'tt_core_create',
      ),
      _destroy = _library.lookupFunction<_DestroyNative, _DestroyDart>(
        'tt_core_destroy',
      ),
      _freeString = _library.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'tt_core_free_string',
      ),
      _connect = _library.lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
        'tt_core_connect',
      ),
      _disconnect = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_disconnect',
      ),
      _startTor = _library.lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
        'tt_core_start_tor',
      ),
      _stopTor = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_stop_tor',
      ),
      _rotateIdentity = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_rotate_identity',
          ),
      _setAppExceptions = _library
          .lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
            'tt_core_set_app_exceptions',
          ),
      _setBridgeConfig = _library
          .lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
            'tt_core_set_bridge_config',
          ),
      _verifyExit = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_verify_exit',
      ),
      _exportDiagnostics = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_export_diagnostics',
          ),
      _runLeakSelfTest = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_run_leak_self_test',
          ),
      _status = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_status',
      );

  final DynamicLibrary _library;
  final _CreateDart _create;
  final _DestroyDart _destroy;
  final _FreeStringDart _freeString;
  final _JsonOneArgDart _connect;
  final _JsonNoArgDart _disconnect;
  final _JsonOneArgDart _startTor;
  final _JsonNoArgDart _stopTor;
  final _JsonNoArgDart _rotateIdentity;
  final _JsonOneArgDart _setAppExceptions;
  final _JsonOneArgDart _setBridgeConfig;
  final _JsonNoArgDart _verifyExit;
  final _JsonNoArgDart _exportDiagnostics;
  final _JsonNoArgDart _runLeakSelfTest;
  final _JsonNoArgDart _status;

  DynamicLibrary get library => _library;

  static TorTunnelFfiLibrary open() {
    if (Platform.isWindows) {
      return TorTunnelFfiLibrary._(DynamicLibrary.open('tor_tunnel_core.dll'));
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return TorTunnelFfiLibrary._(
        DynamicLibrary.open('libtor_tunnel_core.so'),
      );
    }
    throw UnsupportedError(
      'TorTunnel core is only planned for Android, Linux, and Windows.',
    );
  }

  static TorTunnelFfiLibrary? tryOpen() {
    try {
      return open();
    } on Object {
      return null;
    }
  }

  FfiCoreSession createSession() => FfiCoreSession._(this, _create());
}

class FfiCoreSession {
  FfiCoreSession._(this._library, this._core);

  final TorTunnelFfiLibrary _library;
  final Pointer<Void> _core;
  bool _closed = false;

  Map<String, dynamic> connect(Map<String, dynamic> request) {
    return _callWithJson(_library._connect, request);
  }

  Map<String, dynamic> disconnect() => _callNoArg(_library._disconnect);

  Map<String, dynamic> startTor(Map<String, dynamic> bridgeConfig) {
    return _callWithJson(_library._startTor, bridgeConfig);
  }

  Map<String, dynamic> stopTor() => _callNoArg(_library._stopTor);

  Map<String, dynamic> rotateIdentity() => _callNoArg(_library._rotateIdentity);

  Map<String, dynamic> setAppExceptions(List<Map<String, dynamic>> exceptions) {
    return _callWithJson(_library._setAppExceptions, exceptions);
  }

  Map<String, dynamic> setBridgeConfig(Map<String, dynamic> bridgeConfig) {
    return _callWithJson(_library._setBridgeConfig, bridgeConfig);
  }

  Map<String, dynamic> verifyExit() => _callNoArg(_library._verifyExit);

  Map<String, dynamic> exportDiagnostics() =>
      _callNoArg(_library._exportDiagnostics);

  Map<String, dynamic> runLeakSelfTest() =>
      _callNoArg(_library._runLeakSelfTest);

  Map<String, dynamic> status() => _callNoArg(_library._status);

  void close() {
    if (_closed) {
      return;
    }
    _library._destroy(_core);
    _closed = true;
  }

  Map<String, dynamic> _callNoArg(_JsonNoArgDart call) {
    final response = call(_core);
    return _decodeAndFree(response);
  }

  Map<String, dynamic> _callWithJson(_JsonOneArgDart call, Object value) {
    final jsonPointer = jsonEncode(value).toNativeUtf8();
    try {
      final response = call(_core, jsonPointer);
      return _decodeAndFree(response);
    } finally {
      malloc.free(jsonPointer);
    }
  }

  Map<String, dynamic> _decodeAndFree(Pointer<Utf8> pointer) {
    try {
      final decoded = jsonDecode(pointer.toDartString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'protocol_version': 1,
        'ok': false,
        'error': 'FFI response was not a JSON object.',
      };
    } finally {
      _library._freeString(pointer);
    }
  }
}
