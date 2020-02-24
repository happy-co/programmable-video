package twilio.flutter.twilio_programmable_video

import com.twilio.video.TwilioException
import io.flutter.plugin.common.EventChannel.EventSink

open class BaseListener {
    var events: EventSink? = null

    private fun exceptionToMap(e: TwilioException?): Map<String, Any?>? {
        if (e == null)
            return null
        return mapOf("code" to e.code, "message" to e.message)
    }

    protected fun sendEvent(name: String, data: Any, e: TwilioException? = null) {
        val eventData = mapOf("name" to name, "data" to data, "error" to exceptionToMap(e))
        events?.success(eventData)
    }
}
