import Flutter
import Foundation
import TwilioVideo

public class BaseListener: NSObject {
    public var events: FlutterEventSink?

    private func errorToDict(_ error: Error?) -> [String: Any]? {
        if let error = error as NSError? {
            return [
                "code": error.code,
                "message": error.description
            ]
        }
        return nil
    }

    public func sendEvent(_ name: String, data: [String: Any?]? = nil, error: Error? = nil) {
        let eventData = ["name": name, "data": data, "error": errorToDict(error)] as [String: Any?]

        if let events = events {
            events(eventData)
        }
    }
}
