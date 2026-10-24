package me.efesser.flauncher.tvremote.rsocket

import android.util.Log
import io.ktor.utils.io.ClosedWriteChannelException
import io.rsocket.kotlin.RSocketRequestHandler
import io.rsocket.kotlin.core.RSocketServer
import io.rsocket.kotlin.payload.Payload
import io.rsocket.kotlin.payload.buildPayload
import io.rsocket.kotlin.payload.data
import io.rsocket.kotlin.transport.ktor.tcp.KtorTcpServerTransport
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.updateAndGet
import kotlinx.coroutines.isActive
import kotlinx.io.readString
import kotlinx.serialization.json.Json
import me.efesser.flauncher.tvremote.data.RemoteEvent
import me.efesser.flauncher.tvremote.data.ServerStatusEvent

// Vendored from Faayaverse. Protocol & wire format kept byte-identical so the
// Faayaverse phone remote can connect to Portal unmodified. Logging swapped from
// Kermit to android.util.Log; otherwise behaviour matches the original.
class TvRemoteServer(private val host: String = "0.0.0.0", val port: Int = 8080) {
    private val serverExceptionHandler = CoroutineExceptionHandler { _, e ->
        Log.e(TAG, "Unhandled coroutine exception", e)
    }

    private var scope =
        CoroutineScope(SupervisorJob() + Dispatchers.Default + serverExceptionHandler)

    private val _activeConnectionCount = MutableStateFlow(0)
    val activeConnectionCount: StateFlow<Int> = _activeConnectionCount.asStateFlow()

    private val _remoteEventsFromClients = MutableSharedFlow<RemoteEvent>()
    val remoteEventsFromClients: SharedFlow<RemoteEvent> = _remoteEventsFromClients.asSharedFlow()

    private val _eventsToStreamToClients = MutableSharedFlow<Any>(
        extraBufferCapacity = 32,
        onBufferOverflow = BufferOverflow.DROP_OLDEST,
    )

    suspend fun broadcastEvent(event: Any) {
        _eventsToStreamToClients.emit(event)
    }

    private fun createRequestHandler() =
        RSocketRequestHandler {
            requestStream { _: Payload ->
                val newCount = _activeConnectionCount.updateAndGet { it + 1 }
                Log.i(TAG, "CLIENT CONNECTED — activeConnections=$newCount")
                flow {
                    emit(
                        buildPayload {
                            data("""{"type": "subscription_ack", "message": "Subscribed to server event stream"}""")
                        },
                    )

                    _eventsToStreamToClients.collect { eventToStream ->
                        try {
                            val jsonString = when (eventToStream) {
                                is RemoteEvent -> Json.encodeToString(eventToStream)
                                is ServerStatusEvent -> Json.encodeToString(eventToStream)
                                else -> Json.encodeToString(
                                    mapOf(
                                        "type" to "unknown_event",
                                        "error" to "Cannot serialize event",
                                    ),
                                )
                            }
                            emit(buildPayload { data(jsonString) })
                        } catch (e: CancellationException) {
                            throw e
                        } catch (e: ClosedWriteChannelException) {
                            Log.i(TAG, "client left mid-stream (${e.message ?: "closed"})")
                            throw CancellationException("client-gone", e)
                        } catch (e: Exception) {
                            Log.w(TAG, "Failed to stream event $eventToStream", e)
                            runCatching {
                                emit(
                                    buildPayload {
                                        data("""{"type": "error", "message": "${e.message ?: "Unknown error"}"}""")
                                    },
                                )
                            }
                        }
                    }
                }.onCompletion {
                    val remaining = _activeConnectionCount.updateAndGet { it - 1 }
                    Log.i(TAG, "CLIENT DISCONNECTED — activeConnections=$remaining")
                }
            }

            requestResponse { payload: Payload ->
                try {
                    val eventJsonString = payload.data.readString()
                    val remoteEvent = Json.decodeFromString<RemoteEvent>(eventJsonString)
                    Log.i(TAG, "Parsed RemoteEvent: $remoteEvent")
                    _remoteEventsFromClients.emit(remoteEvent)
                    broadcastEvent(remoteEvent)
                    buildPayload {
                        data("""{"type": "ack", "message": "Command received: ${remoteEvent::class.simpleName}"}""")
                    }
                } catch (e: Exception) {
                    buildPayload {
                        data("""{"type": "error", "message": "Failed to process command: ${e.message}"}""")
                    }
                }
            }
        }

    private val server = RSocketServer()

    suspend fun start() {
        if (!scope.isActive) {
            scope = CoroutineScope(SupervisorJob() + Dispatchers.Default + serverExceptionHandler)
        }
        val transport = KtorTcpServerTransport(scope.coroutineContext)
        val target = transport.target(host, port)
        server.startServer(target) { createRequestHandler() }
        Log.i(TAG, "Started successfully on $host:$port")
    }

    fun stop() {
        scope.cancel()
        Log.i(TAG, "Stopped successfully")
    }

    companion object {
        private const val TAG = "TvRemoteServer"
    }
}
