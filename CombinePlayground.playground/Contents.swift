import Foundation
import Combine

// MARK: - Subscription storage

var subscriptions = Set<AnyCancellable>()

// MARK: - Futures

let valueToIncrementInTheFuture = 1

let futureIncrement = Future<Int, Never> { promise in
    print("Start future increment")
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        promise(.success(valueToIncrementInTheFuture + 1))
    }
}

//let s = futureIncrement.sink(receiveCompletion: {
//    print($0)
//}) {
//    print($0)
//}

// Storing directly in subscriptions set instead of variable
futureIncrement.sink(receiveCompletion: {
    print($0)
}) {
    print($0)
}.store(in: &subscriptions)

futureIncrement.sink(receiveCompletion: {
    print("Second", $0)
}) {
    print("Second", $0)
}.store(in: &subscriptions)

// Start future increment printed only once which means that future does not re-execute a promise. It replays the output.
// Also, prmise executes right away, without a subscriber like standard publisher

// MARK: - Custom Subscriber

// Int subscriber
final class IntSubscriber: Subscriber {

    typealias Input = Int
    typealias Failure = Never // Guarantee not to produce an error

    func receive(completion: Subscribers.Completion<Never>) {
        print("Completion: ", completion)
    }

    func receive(subscription: Subscription) {
        // Receive subscription and request a max number of items from publisher
        subscription.request(.max(4))
    }

    func receive(_ input: Int) -> Subscribers.Demand {
        print(input)
        return .none
    }
}

// Int publisher
let intPublisher = (1...6).publisher

// Subscribe to publisher
let intSubscriber = IntSubscriber()
intPublisher.subscribe(intSubscriber)

// MARK: - Subject

let intSubject = PassthroughSubject<Int, Never>()

intSubject.subscribe(intSubscriber)

let intSubscription = intSubject.sink(receiveCompletion: { completion in
    print("Completion: \(completion)")
}) { value in
    print("Value: \(value)")
}

intSubject.send(42)
intSubscription.cancel()
intSubject.send(completion: .finished)
intSubject.send(24)

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
final class TestClass {
    var testValue: String = "" {
        didSet {
            print(testValue)
        }
    }
}

let testObject = TestClass()

let stringPublisher = ["Hello", "World"].publisher
_ = stringPublisher.assign(to: \.testValue, on: testObject)
