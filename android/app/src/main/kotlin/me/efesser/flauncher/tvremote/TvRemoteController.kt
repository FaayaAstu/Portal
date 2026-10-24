package me.efesser.flauncher.tvremote

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import me.efesser.flauncher.tvremote.data.RemoteEvent
import me.efesser.flauncher.tvremote.data.ServerStatusEvent
import me.efesser.flauncher.tvremote.mdns.MdnsPublisher
import me.efesser.flauncher.tvremote.mdns.MdnsTxtKeys
import me.efesser.flauncher.tvremote.rsocket.TvRemoteServer
import java.util.UUID
import java.util.concurrent.atomic.AtomicReference

// Single owner for the Portal-side TV remote server lifecycle. Starts/stops the
// RSocket server + mDNS advertisement together, pumps a 7s heartbeat, and bridges
// RemoteEvents from the server to a Flutter EventChannel as JSON strings. The
// Flutter side decodes and routes.
class TvRemoteController(private val context: Context) : EventChannel.StreamHandler {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val eventSink = AtomicReference<EventChannel.EventSink?>(null)

    private var scope: CoroutineScope? = null
    private var server: TvRemoteServer? = null
    private var mdns: MdnsPublisher? = null
    private var heartbeatJob: Job? = null
    private var collectJob: Job? = null

    @Volatile
    private var running: Boolean = false

    val deviceId: String
        get() = prefs.getString(KEY_DEVICE_ID, null) ?: run {
            val fresh = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_DEVICE_ID, fresh).apply()
            fresh
        }

    var deviceName: String
        get() = prefs.getString(KEY_DEVICE_NAME, null)?.takeIf { it.isNotBlank() } ?: DEFAULT_NAME
        set(value) {
            prefs.edit().putString(KEY_DEVICE_NAME, value).apply()
            if (running) {
                mdns?.republish(PORT, buildTxt())
            }
        }

    fun isRunning(): Boolean = running

    fun info(): Map<String, Any> = mapOf(
        "deviceId" to deviceId,
        "deviceName" to deviceName,
        "port" to PORT,
        "running" to running,
    )

    fun start() {
        if (running) return
        running = true
        val newScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        scope = newScope
        val newServer = TvRemoteServer(port = PORT)
        server = newServer
        val newMdns = MdnsPublisher(context)
        mdns = newMdns

        newScope.launch {
            try {
                newServer.start()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start RSocket server", e)
                return@launch
            }
            newMdns.start(PORT, buildTxt())
        }

        collectJob = newScope.launch {
            newServer.remoteEventsFromClients.collect { event ->
                forwardToFlutter(event)
            }
        }

        heartbeatJob = newScope.launch {
            while (true) {
                delay(HEARTBEAT_INTERVAL_MS)
                try {
                    newServer.broadcastEvent(
                        ServerStatusEvent.Heartbeat(
                            timestamp = System.currentTimeMillis(),
                            activeConnections = newServer.activeConnectionCount.value,
                        ),
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "heartbeat broadcast failed", e)
                }
            }
        }
    }

    fun stop() {
        if (!running) return
        running = false
        heartbeatJob?.cancel()
        collectJob?.cancel()
        heartbeatJob = null
        collectJob = null
        mdns?.stop()
        mdns = null
        server?.stop()
        server = null
        scope?.cancel()
        scope = null
    }

    private fun buildTxt(): Map<String, String> = mapOf(
        MdnsTxtKeys.DEVICE_ID to deviceId,
        MdnsTxtKeys.DEVICE_NAME to deviceName,
        MdnsTxtKeys.VERSION to appVersionName(),
    )

    private fun appVersionName(): String = try {
        val pi = context.packageManager.getPackageInfo(context.packageName, 0)
        pi.versionName ?: ""
    } catch (_: Exception) {
        ""
    }

    private fun forwardToFlutter(event: RemoteEvent) {
        val sink = eventSink.get() ?: return
        val json = try {
            Json.encodeToString(event)
        } catch (e: Exception) {
            Log.w(TAG, "encode failed for $event", e)
            return
        }
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                sink.success(json)
            } catch (e: Exception) {
                Log.w(TAG, "sink.success failed", e)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink.set(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink.set(null)
    }

    companion object {
        private const val TAG = "TvRemoteController"
        private const val PREFS_NAME = "flauncher_tv_remote"
        private const val KEY_DEVICE_ID = "deviceId"
        private const val KEY_DEVICE_NAME = "deviceName"
        private const val DEFAULT_NAME = "Portal TV"
        private const val PORT = 8080
        private const val HEARTBEAT_INTERVAL_MS = 7_000L
    }
}
