package unofficial.twilio.flutter.twilio_unofficial_programmable_video

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager

class BecomingNoisyReceiver(private val audioManager: AudioManager) : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent) {
        if (Intent.ACTION_HEADSET_PLUG.equals(intent.getAction())) {
            TwilioUnofficialProgrammableVideoPlugin.debug("BecomingNoisyReceiver.onReceive => setSpeakerphoneOn(${!audioManager.isWiredHeadsetOn()})")
            audioManager.setSpeakerphoneOn(!audioManager.isWiredHeadsetOn())
        }
    }
}
