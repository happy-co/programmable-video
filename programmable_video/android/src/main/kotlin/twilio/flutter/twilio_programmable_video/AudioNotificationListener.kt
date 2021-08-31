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
    private val activeAudioPlayers: MutableSet<String> = mutableSetOf()

    private var bluetoothProfileProxy: BluetoothProfile.ServiceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceDisconnected(profile: Int) {
            TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::onServiceDisconnected => profile: $profile")
            if (profile == BluetoothProfile.HEADSET) {
                bluetoothProfile = null
                TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
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

    var bluetoothProfile: BluetoothProfile? = null

    private val receiver: BroadcastReceiver = getBroadcastReceiver()

    init {
        // https://developer.android.com/reference/android/media/AudioManager#ACTION_HEADSET_PLUG
        intentFilter.addAction(AudioManager.ACTION_HEADSET_PLUG)
        // https://developer.android.com/reference/android/bluetooth/BluetoothHeadset#ACTION_CONNECTION_STATE_CHANGED
        intentFilter.addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
        // https://developer.android.com/reference/android/media/AudioManager#ACTION_SCO_AUDIO_STATE_UPDATED
         intentFilter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)

        // We could also addAction for BluetoothAdapter.ACTION_STATE_CHANGED per
        // https://developer.android.com/reference/android/bluetooth/BluetoothAdapter#ACTION_STATE_CHANGED
        // to handle Bluetooth being toggled at the OS level, but the BluetoothProfile.ServiceListener above
        // also fills that role.
    }

    fun listenForRouteChanges(context: Context) {
        TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::listenForRouteChanges")
        context.registerReceiver(receiver, intentFilter)
        BluetoothAdapter.getDefaultAdapter().getProfileProxy(context, getProfileProxy(), BluetoothProfile.HEADSET)
    }

    fun stopListeningForRouteChanges(context: Context) {
        TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::stopListeningForRouteChanges")
        context.unregisterReceiver(receiver)
        BluetoothAdapter.getDefaultAdapter().closeProfileProxy(BluetoothProfile.HEADSET, bluetoothProfile)
    }

    fun getBroadcastReceiver(): BroadcastReceiver {
        TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::getBroadcastReceiver")
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

                    TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::onReceive => connected: $connected\n\tevent: $event\n\tbluetoothEvent: $bluetoothEvent")

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
        TwilioProgrammableVideoPlugin.debug("AudioNotificationListener::getProfileProxy")
        return bluetoothProfileProxy
    }

    internal fun audioPlayerEventListener(url: String, isPlaying: Boolean) {
        TwilioProgrammableVideoPlugin.debug("TwilioProgrammableVideoPlugin::audioPlayerEventListener => url: $url, isPlaying: $isPlaying")

        val anyAudioPlayersAlreadyActive = anyAudioPlayersActive()
        updateActiveAudioPlayerList(url, isPlaying)
        val anyAudioPlayersNowActive = anyAudioPlayersActive()

        val isConnected = TwilioProgrammableVideoPlugin.isConnected()

        TwilioProgrammableVideoPlugin.debug("TwilioProgrammableVideoPlugin::audioPlayerEventListener =>\n\tisConnected: $isConnected\n\talreadyActive: $anyAudioPlayersAlreadyActive\n\tnowActive: $anyAudioPlayersNowActive")
        if (anyAudioPlayersNowActive && !anyAudioPlayersAlreadyActive) {
            TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
        } else if (!isConnected && !anyAudioPlayersNowActive && anyAudioPlayersAlreadyActive) {
            // BluetoothSco being enabled functions similarly to holding Audio Focus when it comes
            // to external apps audio, if that external app would normally be using the connected
            // bluetooth device. That is, it prevents the external app from resuming playback.
            TwilioProgrammableVideoPlugin.pluginHandler.setBluetoothSco(false)
        }

        // Do not setAudioFocus here if we are Connected, because if we are we presumably already have
        // audio focus, and want to keep it.
        if (!isConnected && anyAudioPlayersAlreadyActive != anyAudioPlayersNowActive) {
            TwilioProgrammableVideoPlugin.debug("TwilioProgrammableVideoPlugin::audioPlayerEventListener => setAudioFocus: $anyAudioPlayersNowActive")
            TwilioProgrammableVideoPlugin.pluginHandler.setAudioFocus(anyAudioPlayersNowActive)
        }
    }

    private fun updateActiveAudioPlayerList(url: String, isPlaying: Boolean) {
        if (isPlaying) {
            activeAudioPlayers.add(url)
        } else {
            activeAudioPlayers.remove(url)
        }
    }

    internal fun anyAudioPlayersActive(): Boolean {
        return activeAudioPlayers.isNotEmpty()
    }
}