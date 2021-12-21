package twilio.flutter.twilio_programmable_video

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager

class AudioNotificationListener() : BaseListener() {
    private val TAG = "AudioNotificationListener"
    private val intentFilter: IntentFilter = IntentFilter()
    private val activeAudioPlayers: MutableSet<String> = mutableSetOf()

    private var bluetoothProfileProxy: BluetoothProfile.ServiceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceDisconnected(profile: Int) {
            debug("onServiceDisconnected => profile: $profile")
            if (profile == BluetoothProfile.HEADSET) {
                bluetoothProfile = null
                TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
            }
        }

        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
            debug("onServiceConnected => profile: $profile, proxy: $proxy")
            if (profile == BluetoothProfile.HEADSET) {
                bluetoothProfile = proxy
                if (bluetoothProfile!!.connectedDevices.size > 0 &&
                    TwilioProgrammableVideoPlugin.pluginHandler.audioSettings.bluetoothPreferred) {
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

        // Other actions we could listen for:
        // 1. AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED
        //      https://developer.android.com/reference/android/media/AudioManager#ACTION_SCO_AUDIO_STATE_UPDATED
        // to handle changes in the BluetoothSco state

        // 2. BluetoothAdapter.ACTION_STATE_CHANGED
        //      https://developer.android.com/reference/android/bluetooth/BluetoothAdapter#ACTION_STATE_CHANGED
        // to handle Bluetooth being toggled at the OS level, but the BluetoothProfile.ServiceListener above
        // also fills that role.
    }

    fun listenForRouteChanges(context: Context) {
        debug("listenForRouteChanges")
        context.registerReceiver(receiver, intentFilter)
        BluetoothAdapter.getDefaultAdapter()?.getProfileProxy(context, getProfileProxy(), BluetoothProfile.HEADSET)
    }

    fun stopListeningForRouteChanges(context: Context) {
        debug("stopListeningForRouteChanges")
        context.unregisterReceiver(receiver)
        BluetoothAdapter.getDefaultAdapter()?.closeProfileProxy(BluetoothProfile.HEADSET, bluetoothProfile)
    }

    private fun getBroadcastReceiver(): BroadcastReceiver {
        debug("getBroadcastReceiver")
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val wiredEvent = intent?.action.equals(AudioManager.ACTION_HEADSET_PLUG)
                val bluetoothEvent = intent?.action.equals(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)

                val connected: Boolean = when {
                    wiredEvent -> {
                        intent?.getIntExtra("state", 0) == 1
                    }
                    bluetoothEvent -> {
                        val state = intent?.getIntExtra(BluetoothProfile.EXTRA_STATE, 0)
                        if (state == BluetoothProfile.STATE_CONNECTING || state == BluetoothProfile.STATE_DISCONNECTING) {
                            return
                        }
                        state == BluetoothProfile.STATE_CONNECTED
                    }
                    else -> null
                } ?: return

                val event = if (connected) "newDeviceAvailable" else "oldDeviceUnavailable"

                val deviceName = if (bluetoothEvent) intent?.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)?.name
                    else intent?.getStringExtra("portName") ?: return

                debug("onReceive => connected: $connected\n\tevent: $event\n\tbluetoothEvent: $bluetoothEvent\n\twiredEvent: $wiredEvent\n\tdeviceName: $deviceName")

                if (bluetoothEvent) {
                    TwilioProgrammableVideoPlugin.pluginHandler.applyAudioSettings()
                }

                debug("onReceive => event: $event, connected: $connected, bluetooth: $bluetoothEvent, wired: $wiredEvent")
                sendEvent(event, mapOf(
                        "connected" to connected,
                        "bluetooth" to bluetoothEvent,
                        "wired" to wiredEvent,
                        "deviceName" to deviceName
                ))
            }
        }
    }

    fun getProfileProxy(): BluetoothProfile.ServiceListener {
        debug("getProfileProxy")
        return bluetoothProfileProxy
    }

    internal fun audioPlayerEventListener(url: String, isPlaying: Boolean) {
        debug("audioPlayerEventListener => url: $url, isPlaying: $isPlaying")

        val anyAudioPlayersAlreadyActive = anyAudioPlayersActive()
        updateActiveAudioPlayerList(url, isPlaying)
        val anyAudioPlayersNowActive = anyAudioPlayersActive()

        val isConnected = TwilioProgrammableVideoPlugin.isConnected()

        debug("audioPlayerEventListener =>\n\tisConnected: $isConnected\n\talreadyActive: $anyAudioPlayersAlreadyActive\n\tnowActive: $anyAudioPlayersNowActive")
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
            debug("audioPlayerEventListener => setAudioFocus: $anyAudioPlayersNowActive")
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

    internal fun debug(msg: String) {
        TwilioProgrammableVideoPlugin.debugAudio("$TAG::$msg")
    }
}
