package twilio.flutter.twilio_programmable_video

import com.twilio.video.TwilioException
import io.flutter.plugin.common.EventChannel.EventSink
import java.lang.Exception

open class BaseListener {
    var events: EventSink? = null

    private fun exceptionToMap(e: Exception?): Map<String, Any?>? {
        if (e == null)
            return null

        if (e is TwilioException)
            return mapOf("code" to e.code, "message" to e.message)

        return mapOf("code" to e.message)
    }

    protected fun sendEvent(name: String, data: Any, e: Exception? = null) {
        val eventData = mapOf("name" to name, "data" to data, "error" to exceptionToMap(e))
        events?.success(eventData)
    }
}
