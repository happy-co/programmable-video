package twilio.flutter.twilio_programmable_video

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper

class BecomingNoisyReceiver : BroadcastReceiver {
    private var applicationContext: Context

    private var audioManager: AudioManager

    private var bluetoothManager: BluetoothManager

    private var hasBluetooth: Boolean = false

    private var hasWiredHeadset: Boolean = false

    private var bluetoothProxyProfile: BluetoothProfile? = null

    constructor(audioManager: AudioManager, applicationContext: Context) {
        this.audioManager = audioManager
        this.applicationContext = applicationContext
        bluetoothManager = applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

        // Start listening for changes in the Bluetooth service (enable/disable Bluetooth)
        bluetoothManager.adapter?.getProfileProxy(applicationContext, object : BluetoothProfile.ServiceListener {
            override fun onServiceDisconnected(profile: Int) {
                if (hasBluetooth && profile == BluetoothProfile.HEADSET) {
                    hasBluetooth = false
//                    audioManager.stopBluetoothSco()
//                    audioManager.isBluetoothScoOn = false
//                    audioManager.isSpeakerphoneOn = !hasWiredHeadset
                    TwilioProgrammableVideoPlugin.debug("bluetoothManager.adapter.getProfileProxy => onServiceDisconnected - hasBluetooth:$hasBluetooth - isBluetoothScoOn:${audioManager.isBluetoothScoOn} - getMode:${audioManager.mode}")
                }
            }

            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                if (profile == BluetoothProfile.HEADSET) {
                    bluetoothProxyProfile = proxy
                    if (proxy!!.connectedDevices.size > 0) {
                        hasBluetooth = true
//                        audioManager.isSpeakerphoneOn = false
//                        audioManager.startBluetoothSco()
//                        audioManager.isBluetoothScoOn = true
                        TwilioProgrammableVideoPlugin.debug("bluetoothManager.adapter.getProfileProxy => onServiceConnected - hasBluetooth:$hasBluetooth - isBluetoothScoOn:${audioManager.isBluetoothScoOn} - getMode:${audioManager.mode}")
                    }
                }
            }
        }, BluetoothProfile.HEADSET)
    }

    override fun onReceive(context: Context?, intent: Intent) {
        TwilioProgrammableVideoPlugin.debug("BecomingNoisyReceiver.onReceive => ${intent.action}")

        /*
         * This intent should also switch back to Bluetooth when there are Bluetooth devices, but everything I try, does not work
         * Also tested Spotify behaviour, and even then Bluetooth does not start after disconnecting audio jack. You need to reset Bluetooth on Spotify, to re-use the headset.
         */
        if (Intent.ACTION_HEADSET_PLUG == intent.action) {
            hasWiredHeadset = intent?.getIntExtra("state", 0) == 1
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//                hasWiredHeadset = audioManager.getDevices(AudioManager.GET_DEVICES_ALL).any {
//                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET || it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES
//                }
//            } else {
//                hasWiredHeadset = audioManager.isWiredHeadsetOn
//            }

//            audioManager.isSpeakerphoneOn = !hasWiredHeadset
            TwilioProgrammableVideoPlugin.debug("hasWiredHeadset: $hasWiredHeadset and hasBluetooth: $hasBluetooth - getMode:${audioManager.mode}")
        }

        if (BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED == intent.action) {
            when (intent.extras!!.getInt(BluetoothAdapter.EXTRA_CONNECTION_STATE)) {
                BluetoothAdapter.STATE_CONNECTED -> {
//                    if (!hasBluetooth) {
//                        /**
//                         * Using a postDelayed here. Seems like we needs to listen to a different state update according to the Android docs:
//                         * https://developer.android.com/reference/android/media/AudioManager#startBluetoothSco()
//                         * Tried implementation like:
//                         * https://github.com/signalapp/Signal-Android/blob/4ea886d05afbf1ca250cfd2b7a6835748828d6ba/app/src/main/java/org/thoughtcrime/securesms/webrtc/audio/BluetoothStateManager.java
//                         * But that does not seem to work! But a delay does work... If someone could improve this, gladly help...
//                         */
//                        Handler(Looper.getMainLooper()).postDelayed({
//                            hasBluetooth = true
////                            audioManager.isSpeakerphoneOn = false
//                            audioManager.startBluetoothSco()
//                            audioManager.isBluetoothScoOn = true
//                            TwilioProgrammableVideoPlugin.debug("BecomingNoisyReceiver::STATE_CONNECTED => isSpeakerPhoneOn: ${audioManager.isSpeakerphoneOn}, hasWiredHeadset:$hasWiredHeadset and hasBluetooth:$hasBluetooth - isBluetoothScoOn:${audioManager.isBluetoothScoOn} - getMode:${audioManager.mode}")
//                        }, 1000)
//                    }
                }
                BluetoothAdapter.STATE_DISCONNECTED -> {
//                    if (hasBluetooth) {
//                        hasBluetooth = false
//                        audioManager.stopBluetoothSco()
//                        audioManager.isBluetoothScoOn = false
////                        audioManager.isSpeakerphoneOn = !hasWiredHeadset
//                        TwilioProgrammableVideoPlugin.debug("BecomingNoisyReceiver::STATE_DISCONNECTED => isSpeakerPhoneOn: ${audioManager.isSpeakerphoneOn}, hasWiredHeadset:$hasWiredHeadset and hasBluetooth:$hasBluetooth - isBluetoothScoOn:${audioManager.isBluetoothScoOn} - getMode:${audioManager.mode}")
//                    }
                }
            }
        }

//        if (intent.action == AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED) {
//            TwilioProgrammableVideoPlugin.debug("BecomingNoisyReceiver::onReceive => ACTION_SCO_AUDIO_STATE_UPDATED")
//        }
    }

    fun dispose() {
        bluetoothManager.adapter?.closeProfileProxy(BluetoothProfile.HEADSET, bluetoothProxyProfile)
        bluetoothProxyProfile = null
    }
}
