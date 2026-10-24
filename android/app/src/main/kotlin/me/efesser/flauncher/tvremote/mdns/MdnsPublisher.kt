package me.efesser.flauncher.tvremote.mdns

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log

// Vendored from Faayaverse MdnsPublisher.android.kt. Service type and TXT keys must
// stay identical to Faayaverse so the phone's discovery sees Portal the same way.
const val FAAYA_TV_MDNS_SERVICE_TYPE: String = "_faaya-tv._tcp"

object MdnsTxtKeys {
    const val DEVICE_ID: String = "deviceId"
    const val WORKSPACE_ID: String = "workspaceId"
    const val SECTION_ID: String = "sectionId"
    const val SECTION_NAME: String = "sectionName"
    const val DEVICE_NAME: String = "deviceName"
    const val VERSION: String = "version"
}

class MdnsPublisher(private val context: Context) {
    private val nsdManager: NsdManager by lazy {
        context.getSystemService(Context.NSD_SERVICE) as NsdManager
    }

    private var registrationListener: NsdManager.RegistrationListener? = null

    fun start(port: Int, attributes: Map<String, String>) {
        if (registrationListener != null) {
            Log.w(TAG, "start() called while already registered — treating as republish")
            republish(port, attributes)
            return
        }
        val listener = buildListener()
        registrationListener = listener
        try {
            nsdManager.registerService(
                buildServiceInfo(port, attributes),
                NsdManager.PROTOCOL_DNS_SD,
                listener,
            )
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "registerService threw — dropping registration", e)
            registrationListener = null
        }
    }

    fun republish(port: Int, attributes: Map<String, String>) {
        stop()
        start(port, attributes)
    }

    fun stop() {
        val listener = registrationListener ?: return
        registrationListener = null
        try {
            nsdManager.unregisterService(listener)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "unregisterService no-op ($e)")
        }
    }

    private fun buildServiceInfo(port: Int, attributes: Map<String, String>): NsdServiceInfo =
        NsdServiceInfo().apply {
            serviceName = attributes[MdnsTxtKeys.DEVICE_NAME]?.takeIf { it.isNotBlank() } ?: "Faaya TV"
            serviceType = "$FAAYA_TV_MDNS_SERVICE_TYPE."
            this.port = port
            attributes.forEach { (key, value) ->
                setAttribute(key, value)
            }
        }

    private fun buildListener(): NsdManager.RegistrationListener =
        object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(info: NsdServiceInfo) {
                Log.i(TAG, "registered as ${info.serviceName} on port ${info.port}")
            }

            override fun onRegistrationFailed(info: NsdServiceInfo, errorCode: Int) {
                Log.e(TAG, "registration failed — code=$errorCode, name=${info.serviceName}")
            }

            override fun onServiceUnregistered(info: NsdServiceInfo) {
                Log.i(TAG, "unregistered ${info.serviceName}")
            }

            override fun onUnregistrationFailed(info: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG, "unregistration failed — code=$errorCode, name=${info.serviceName}")
            }
        }

    companion object {
        private const val TAG = "MdnsPublisher"
    }
}
