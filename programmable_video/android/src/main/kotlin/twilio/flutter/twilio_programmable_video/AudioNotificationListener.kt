package twilio.flutter.twilio_programmable_video

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager

class AudioNotificationListener() : BaseListener() {
    private val intentFilter: IntentFilter = IntentFilter()

    lateinit var bluetoothProfileProxy: BluetoothProfile.ServiceListener

    var bluetoothProfile: BluetoothProfile? = null

    private val receiver: BroadcastReceiver = getBroadcastReceiver()

    init {
        // https://developer.android.com/reference/android/media/AudioManager#ACTION_HEADSET_PLUG
        intentFilter.addAction(AudioManager.ACTION_HEADSET_PLUG)
        // https://developer.android.com/reference/android/bluetooth/BluetoothHeadset#ACTION_CONNECTION_STATE_CHANGED
        intentFilter.addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
        // https://developer.android.com/reference/android/media/AudioManager#ACTION_SCO_AUDIO_STATE_UPDATED
         intentFilter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)
    }

    fun listenForRouteChanges(context: Context) {
        context.registerReceiver(receiver, intentFilter)
        BluetoothAdapter.getDefaultAdapter().getProfileProxy(context, getProfileProxy(), BluetoothProfile.HEADSET)
    }

    fun stopListeningForRouteChanges(context: Context) {
        context.unregisterReceiver(receiver)
        BluetoothAdapter.getDefaultAdapter().closeProfileProxy(BluetoothProfile.HEADSET, bluetoothProfile)
    }

    fun getBroadcastReceiver(): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val wiredEvent = intent?.action.equals(AudioManager.ACTION_HEADSET_PLUG)
                val bluetoothEvent = intent?.action.equals(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)

                val connected: Boolean? = when {
                    wiredEvent -> {
                        intent?.getIntExtra("state", 0) == 1
                    }
                    bluetoothEvent -> {
                        val state = intent?.getIntExtra(BluetoothProfile.EXTRA_STATE, 0)
                        state == BluetoothProfile.STATE_CONNECTED
                    }
                    else -> null
                }

                if (connected != null) {
                    val event = if (connected) "newDeviceAvailable" else "oldDeviceUnavailable"
                    val anyBluetoothHeadsetConnected = BluetoothAdapter.getDefaultAdapter().getProfileConnectionState(BluetoothProfile.HEADSET) == BluetoothProfile.STATE_CONNECTED

                    if (bluetoothEvent) {
                        // TODO: review whether this is necessary since disconnecting the active bluetooth headset while another is connected does not automatically switch back to the remaining one
                        if (!connected && anyBluetoothHeadsetConnected) {
                            TwilioProgrammableVideoPlugin.pluginHandler.setBluetoothSco(false)
                        }
                        TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
                    }

                    TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::onReceive => event: $event, connected: $connected, bluetooth: $bluetoothEvent, wired: $wiredEvent headsetState: $anyBluetoothHeadsetConnected")
                    sendEvent(event, mapOf(
                            "connected" to connected,
                            "bluetooth" to bluetoothEvent,
                            "wired" to wiredEvent
                    ))
                }
            }
        }
    }

    fun getProfileProxy(): BluetoothProfile.ServiceListener {
        if (bluetoothProfileProxy == null) {
            bluetoothProfileProxy = object : BluetoothProfile.ServiceListener {
                override fun onServiceDisconnected(profile: Int) {
                    TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::onServiceDisconnected => profile: $profile")
                    if (profile == BluetoothProfile.HEADSET) {
                        bluetoothProfile = null
                        // TODO: review whether this can be switch to applyAudioSettings. Maybe improve applyBluetoothSettings to look at .getProfileConnectionState(BluetoothProfile.HEADSET)
                        TwilioProgrammableVideoPlugin.pluginHandler.applySpeakerPhoneSettings()
                    }
                }

                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                    TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::onServiceConnected => profile: $profile, proxy: $proxy")
                    if (profile == BluetoothProfile.HEADSET) {
                        bluetoothProfile = proxy
                        if (bluetoothProfile!!.connectedDevices.size > 0
                                && TwilioProgrammableVideoPlugin.pluginHandler.audioSettings.bluetoothPreferred) {
                            TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
                        }
                    }
                }
            }
        }
        return bluetoothProfileProxy
    }
}