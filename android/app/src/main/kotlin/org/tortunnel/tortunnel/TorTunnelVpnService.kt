package org.tortunnel.tortunnel

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.system.OsConstants

class TorTunnelVpnService : VpnService() {
    private var tunnelInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_DISCONNECT) {
            stopTunnel()
            return START_NOT_STICKY
        }
        establishStrictModeInterface()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    fun protectTorSocket(socket: Int): Boolean {
        return protect(socket)
    }

    fun isStrictLockdownActive(): Boolean {
        return isLockdownEnabled
    }

    private fun establishStrictModeInterface() {
        if (tunnelInterface != null) {
            return
        }

        val builder = Builder()
            .setSession("TorTunnel Strict Mode")
            .addAddress("10.111.0.2", 32)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("10.111.0.1")
            .allowFamily(OsConstants.AF_INET)
            .setBlocking(true)

        // Deliberately do not call allowBypass() and do not allow AF_INET6.
        // Per-app exceptions are handled only in Compatibility Mode and must
        // never be enabled while Android lockdown is active.
        tunnelInterface = builder.establish()
    }

    private fun stopTunnel() {
        tunnelInterface?.close()
        tunnelInterface = null
        stopSelf()
    }

    companion object {
        const val ACTION_CONNECT = "org.tortunnel.tortunnel.CONNECT"
        const val ACTION_DISCONNECT = "org.tortunnel.tortunnel.DISCONNECT"
    }
}
