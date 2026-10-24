package me.efesser.flauncher.tvremote.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Vendored from Faayaverse shared/features/tv-remote. Discriminator strings must stay
// byte-identical to Faayaverse so the phone remote's JSON parses here.
@Serializable
sealed class RemoteEvent {
    @Serializable
    @SerialName("DPad")
    data class DPad(val direction: Direction) : RemoteEvent()

    @Serializable
    @SerialName("Select")
    data object Select : RemoteEvent()

    @Serializable
    @SerialName("Back")
    data object Back : RemoteEvent()

    @Serializable
    @SerialName("TrackpadMove")
    data class TrackpadMove(val dx: Float, val dy: Float) : RemoteEvent()

    @Serializable
    @SerialName("TrackpadClick")
    data class TrackpadClick(val x: Float, val y: Float) : RemoteEvent()

    @Serializable
    @SerialName("TrackpadSwipe")
    data class TrackpadSwipe(val direction: Direction, val velocity: Float) : RemoteEvent()

    @Serializable
    @SerialName("TrackpadFling")
    data class TrackpadFling(val direction: Direction, val velocity: Float) : RemoteEvent()

    @Serializable
    @SerialName("PlayPause")
    data object PlayPause : RemoteEvent()

    @Serializable
    @SerialName("VolumeUp")
    data object VolumeUp : RemoteEvent()

    @Serializable
    @SerialName("VolumeDown")
    data object VolumeDown : RemoteEvent()

    @Serializable
    @SerialName("Mute")
    data object Mute : RemoteEvent()

    @Serializable
    @SerialName("ChannelUp")
    data object ChannelUp : RemoteEvent()

    @Serializable
    @SerialName("ChannelDown")
    data object ChannelDown : RemoteEvent()

    @Serializable
    @SerialName("Home")
    data object Home : RemoteEvent()

    @Serializable
    @SerialName("Power")
    data object Power : RemoteEvent()

    @Serializable
    @SerialName("Voice")
    data object Voice : RemoteEvent()

    @Serializable
    @SerialName("Search")
    data object Search : RemoteEvent()

    @Serializable
    @SerialName("Menu")
    data object Menu : RemoteEvent()

    @Serializable
    @SerialName("Info")
    data object Info : RemoteEvent()

    @Serializable
    @SerialName("Keyboard")
    data class Keyboard(val keyCode: Int, val keyChar: Char? = null) : RemoteEvent()

    @Serializable
    sealed class Contextual : RemoteEvent() {
        @Serializable
        @SerialName("ctx.navigate")
        data class Navigate(
            val screen: String,
            val params: Map<String, String> = emptyMap(),
        ) : Contextual()

        // Faayaverse-specific contextual subtrees. Portal doesn't act on these but keeps
        // the sealed hierarchy complete so JSON for any Faayaverse remote build still
        // deserializes without a kotlinx-serialization error.
        @Serializable
        sealed class CustomerHome : Contextual() {
            @Serializable
            @SerialName("ctx.customerhome.openinfittingroom")
            data class OpenGarmentInFittingRoom(val garmentId: String) : CustomerHome()

            @Serializable
            @SerialName("ctx.customerhome.addgarment")
            data object AddGarment : CustomerHome()
        }

        @Serializable
        sealed class Collections : Contextual() {
            @Serializable
            @SerialName("ctx.collections.opengarment")
            data class OpenGarment(val garmentId: String) : Collections()
        }

        @Serializable
        sealed class FittingRoom : Contextual() {
            @Serializable
            @SerialName("ctx.fittingroom.selectgarment")
            data class SelectGarment(val garmentId: String) : FittingRoom()

            @Serializable
            @SerialName("ctx.fittingroom.selectpose")
            data class SelectPose(val poseId: String) : FittingRoom()

            @Serializable
            @SerialName("ctx.fittingroom.selectscene")
            data class SelectScene(val sceneId: String) : FittingRoom()

            @Serializable
            @SerialName("ctx.fittingroom.addgarment")
            data object AddGarment : FittingRoom()

            @Serializable
            @SerialName("ctx.fittingroom.generationchanged")
            data object GenerationChanged : FittingRoom()
        }

        @Serializable
        sealed class GarmentDetail : Contextual() {
            @Serializable
            @SerialName("ctx.garmentdetail.next")
            data object Next : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.prev")
            data object Prev : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.addtofr")
            data class AddToFittingRoom(val garmentId: String) : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.removefromfr")
            data class RemoveFromFittingRoom(val garmentId: String) : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.openinfr")
            data class OpenInFittingRoom(val garmentId: String) : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.close")
            data object Close : GarmentDetail()

            @Serializable
            @SerialName("ctx.garmentdetail.showimage")
            data class ShowImage(val index: Int) : GarmentDetail()
        }

        @Serializable
        sealed class Reels : Contextual() {
            @Serializable
            @SerialName("ctx.reels.playpause")
            data object PlayPause : Reels()

            @Serializable
            @SerialName("ctx.reels.next")
            data object Next : Reels()

            @Serializable
            @SerialName("ctx.reels.prev")
            data object Prev : Reels()

            @Serializable
            @SerialName("ctx.reels.autoscroll")
            data object ToggleAutoScroll : Reels()

            @Serializable
            @SerialName("ctx.reels.refresh")
            data object Refresh : Reels()
        }
    }
}

@Serializable
enum class Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT,
}
