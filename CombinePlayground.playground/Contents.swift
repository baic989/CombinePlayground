import Foundation
import Combine

// MARK: - Notification PubSub

print("Notification PubSub")

// NotificationCenter now implements Combine to publish broadcasted notifications
// just to use notifications in a reactive way
let testNotification = Notification.Name("TestNotification")

// Notification will be sent from the publisher
let notificationPublisher = NotificationCenter.default.publisher(for: testNotification)

// Subscriber for the notification publisher
let notificationSubscriber = notificationPublisher.sink { notification in
    print(notification)
}

NotificationCenter.default.post(Notification(name: testNotification))

// Cancel the subscription manually if it is stored in a variable
// If not, it will get cancelled automatically when it exists the scope
notificationSubscriber.cancel()

// MARK: - Primitive type Just PubSub

print("Primitive type Just PubSub")

// Just represents a primitive type publisher
let just = Just("Hello World!")

// First subscriber
_ = just.sink(receiveCompletion: {
    print("Completion", $0)
}, receiveValue: {
    print("Value", $0)
})

// Second subscriber
// Just publishes and finishes for every subscriber it has
_ = just.sink(receiveCompletion: {
    print("Completion", $0)
}, receiveValue: {
    print("Value", $0)
})

// MARK: - KVO PubSub

print("KVO PubSub")

// A class which will have changed the property value by the publisher
class TestClass {
    var testValue: String = "" {
        didSet {
            print(testValue)
        }
    }
}

let testObject = TestClass()

let publisher = ["Hello", "World"].publisher
_ = publisher.assign(to: \.testValue, on: testObject)


