package me.efesser.flauncher.tvremote.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// TvAccessInfoUpdate dropped — Portal has no Faaya workspace/session identity.
@Serializable
sealed class ServerStatusEvent {
    @Serializable
    @SerialName("heartbeat")
    data class Heartbeat(
        val timestamp: Long,
        val serverLoad: Double? = null,
        val activeConnections: Int? = null,
    ) : ServerStatusEvent()

    @Serializable
    @SerialName("tv_state_update")
    data class TvStateUpdate(
        val volume: Int,
        val channel: String,
        val isMuted: Boolean,
        val inputSource: String? = null,
    ) : ServerStatusEvent()

    @Serializable
    @SerialName("system_shutdown_alert")
    data object SystemShutdownAlert : ServerStatusEvent()

    @Serializable
    @SerialName("screen_context")
    data class ScreenContext(
        val screen: String,
        val metadata: Map<String, String> = emptyMap(),
    ) : ServerStatusEvent()
}
