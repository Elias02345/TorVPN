package org.tortunnel.tortunnel

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.system.OsConstants
import android.util.Log

/**
 * Strict-mode system VPN for Android.
 *
 * Establishes a TUN interface that captures all IPv4 traffic, protects tor's own
 * sockets so they bypass the tunnel, and hands the TUN fd to the native
 * `tun2proxy` engine which forwards packets to tor's SOCKS port. UDP and IPv6 are
 * not routed (fail-closed). The Flutter UI starts/stops this service.
 *
 * Fail-closed: if the native engine is unavailable, the interface still captures
 * traffic but forwards nothing, so apps cannot leak directly. The service must
 * pass the device leak-test matrix (see docs/VERIFICATION_CHECKLIST.md) before it
 * may report `protected`.
 */
class TorTunnelVpnService : VpnService() {
    private var tunnelInterface: ParcelFileDescriptor? = null
    private var engineRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_DISCONNECT -> {
                stopTunnel()
                return START_NOT_STICKY
            }
            else -> {
                val socksPort = intent?.getIntExtra(EXTRA_SOCKS_PORT, DEFAULT_SOCKS_PORT)
                    ?: DEFAULT_SOCKS_PORT
                startForegroundNotification()
                if (establishStrictModeInterface()) {
                    startEngine(socksPort)
                }
                // Sticky so the tunnel is re-established after process death.
                return START_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    /** Protect a tor socket so its traffic bypasses the tunnel (and reaches relays). */
    fun protectTorSocket(socket: Int): Boolean = protect(socket)

    /** Whether Android always-on lockdown is active; app exceptions are forbidden then. */
    fun isStrictLockdownActive(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && isLockdownEnabled

    private fun establishStrictModeInterface(): Boolean {
        if (tunnelInterface != null) {
            return true
        }
        val builder = Builder()
            .setSession("TorTunnel Strict Mode")
            .setMtu(TUN_MTU)
            .addAddress(TUN_ADDRESS, TUN_PREFIX)
            .addRoute("0.0.0.0", 0)
            .addDnsServer(TUN_DNS)
            .allowFamily(OsConstants.AF_INET)
            .setBlocking(true)

        // Deliberately do not call allowBypass() and do not allow AF_INET6.
        // Per-app exceptions are handled only in Compatibility Mode and must never
        // be enabled while Android lockdown is active.
        return try {
            tunnelInterface = builder.establish()
            tunnelInterface != null
        } catch (error: IllegalStateException) {
            Log.e(TAG, "Failed to establish VPN interface", error)
            false
        }
    }

    private fun startEngine(socksPort: Int) {
        val fd = tunnelInterface?.fd ?: return
        if (!ENGINE_AVAILABLE) {
            Log.w(TAG, "Native tun2proxy engine unavailable; interface is fail-closed (no forwarding).")
            return
        }
        try {
            nativeStartTun2proxy(fd, socksPort)
            engineRunning = true
        } catch (error: Throwable) {
            Log.e(TAG, "Native engine failed to start", error)
            engineRunning = false
        }
    }

    private fun stopTunnel() {
        if (engineRunning && ENGINE_AVAILABLE) {
            try {
                nativeStopTun2proxy()
            } catch (error: Throwable) {
                Log.e(TAG, "Native engine failed to stop", error)
            }
            engineRunning = false
        }
        tunnelInterface?.close()
        tunnelInterface = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun startForegroundNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TorTunnel",
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.description = "TorTunnel system tunnel status"
            manager.createNotificationChannel(channel)
        }

        val disconnectIntent = Intent(this, TorTunnelVpnService::class.java).apply {
            action = ACTION_DISCONNECT
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val disconnectPending =
            PendingIntent.getService(this, 0, disconnectIntent, flags)

        startForeground(NOTIFICATION_ID, buildNotification(disconnectPending))
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(disconnectPending: PendingIntent): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("TorTunnel")
            .setContentText("Strict Mode tunnel active")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Disconnect",
                disconnectPending,
            )
            .build()
    }

    private external fun nativeStartTun2proxy(tunFd: Int, socksPort: Int): Int
    private external fun nativeStopTun2proxy()

    companion object {
        private const val TAG = "TorTunnelVpnService"

        const val ACTION_CONNECT = "org.tortunnel.tortunnel.CONNECT"
        const val ACTION_DISCONNECT = "org.tortunnel.tortunnel.DISCONNECT"
        const val EXTRA_SOCKS_PORT = "org.tortunnel.tortunnel.SOCKS_PORT"

        private const val DEFAULT_SOCKS_PORT = 9050
        private const val TUN_ADDRESS = "10.111.0.2"
        private const val TUN_PREFIX = 32
        private const val TUN_DNS = "10.111.0.1"
        private const val TUN_MTU = 1500

        private const val CHANNEL_ID = "tortunnel_status"
        private const val NOTIFICATION_ID = 0x7707

        /** Whether the native tun2proxy engine library could be loaded. */
        private val ENGINE_AVAILABLE: Boolean = try {
            System.loadLibrary("tortunnel_engine")
            true
        } catch (error: Throwable) {
            false
        }
    }
}
