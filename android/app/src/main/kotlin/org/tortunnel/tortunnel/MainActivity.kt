package org.tortunnel.tortunnel

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingVpnResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> prepareVpn(result)
                "startVpn" -> {
                    startVpnService(TorTunnelVpnService.ACTION_CONNECT)
                    result.success(mapOf("started" to true))
                }
                "stopVpn" -> {
                    startVpnService(TorTunnelVpnService.ACTION_DISCONNECT)
                    result.success(mapOf("stopped" to true))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_VPN_PREPARE) {
            return
        }

        val result = pendingVpnResult ?: return
        pendingVpnResult = null
        result.success(
            mapOf(
                "prepared" to (resultCode == Activity.RESULT_OK),
                "cancelled" to (resultCode != Activity.RESULT_OK),
            ),
        )
    }

    private fun prepareVpn(result: MethodChannel.Result) {
        if (pendingVpnResult != null) {
            result.error(
                "vpn_permission_pending",
                "A VPN permission request is already open.",
                null,
            )
            return
        }

        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(mapOf("prepared" to true, "cancelled" to false))
            return
        }

        pendingVpnResult = result
        startActivityForResult(intent, REQUEST_VPN_PREPARE)
    }

    private fun startVpnService(action: String) {
        val intent = Intent(this, TorTunnelVpnService::class.java).setAction(action)
        startService(intent)
    }

    companion object {
        private const val CHANNEL_NAME = "org.tortunnel.tortunnel/vpn"
        private const val REQUEST_VPN_PREPARE = 43120
    }
}
