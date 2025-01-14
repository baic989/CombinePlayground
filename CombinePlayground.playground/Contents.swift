import Foundation
import UIKit
import Combine

// MARK: - Subscription storage & consts

var subscriptions = Set<AnyCancellable>()
let numbersPublisher = (1...10).publisher
let waitingPublisher = PassthroughSubject<Int, Never>()
let awaitedPublisher = PassthroughSubject<Void, Never>()

// MARK: - Delayed publisher

Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    .delay(for: 5, scheduler: DispatchQueue.main)
    .sink(receiveValue: { date in
        print(date)
    })
    .store(in: &subscriptions)

// MARK: - Zip

// Difference with combine latest is that zip waits for all publishers
// to emit a value (just like Swift's zip which pairs indexes)

let zip1 = PassthroughSubject<Int, Never>()
let zip2 = PassthroughSubject<String, Never>()

zip1.zip(zip2).sink { number, text in
    print(number, text)
}.store(in: &subscriptions)

zip1.send(1)
zip1.send(2)

zip2.send("a")
zip2.send("b")

zip1.send(3)

// MARK: - Combine latest

let comb1 = PassthroughSubject<Int, Never>()
let comb2 = PassthroughSubject<String, Never>()

comb1.combineLatest(comb2).sink { number, text in
    print(number, text)
}.store(in: &subscriptions)

comb1.send(1)
comb1.send(2)

comb2.send("a")
comb2.send("b")

comb1.send(3)

// MARK: - Merge

let merge1 = PassthroughSubject<Int, Never>()
let merge2 = PassthroughSubject<Int, Never>()

merge1.merge(with: merge2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

merge1.send(1)
merge1.send(2)

merge2.send(3)

merge1.send(4)

// MARK: - Switch to latest

let randomImageURL = URL(string: "https://source.unsplash.com/random")!
func getRandomImage() -> AnyPublisher<UIImage?, Never> {

    return URLSession.shared
        .dataTaskPublisher(for: randomImageURL)
        .map{ data, _ in UIImage(data: data) }
        .print("image")
        .replaceError(with: nil)
        .eraseToAnyPublisher()
}

let taps = PassthroughSubject<Void, Never>()
taps
    .map({ _ in getRandomImage() })
    .switchToLatest()
    .sink(receiveValue: { _ in })
    .store(in: &subscriptions)

taps.send()

DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    taps.send()
}

DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
    taps.send()
}

// MARK: - Append publisher

let append1 = [1, 2].publisher
let append2 = [3, 4].publisher

append1
    .append(append2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Append passthrough

let appPass = PassthroughSubject<Int, Never>()
appPass
    .append(3)
    .append(4)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

appPass.send(1)
appPass.send(2)
appPass.send(completion: .finished)

// MARK: - Append output

numbersPublisher
    .append([11, 12])
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: Prepend passtrough

let prepPass = PassthroughSubject<Int, Never>()
numbersPublisher
    .prepend(prepPass)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

prepPass.send(-1)
prepPass.send(-0)
prepPass.send(completion: .finished)

// MARK: - Prepend publisher

let prepend = [-1, 0].publisher
numbersPublisher
    .prepend(prepend)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Prepend output

numbersPublisher
    .prepend([-1, 0])
    .prepend([-3, -2])
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Prefix until output from

waitingPublisher
    .prefix(untilOutputFrom: awaitedPublisher)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

(1...10).forEach { value in
    waitingPublisher.send(value)

    if value == 3 {
        awaitedPublisher.send()
    }
}

// MARK: - Prefix while

numbersPublisher
    .prefix(while: { $0 < 5 })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Prefix / take first

numbersPublisher
    .prefix(5)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Drop until output from

waitingPublisher.drop(untilOutputFrom: awaitedPublisher).sink(receiveValue: { print($0) }).store(in: &subscriptions)

(1...5).forEach { value in

    waitingPublisher.send(value)

    if value == 3 {
        awaitedPublisher.send()
    }
}

// MARK: - Drop while

// Drop while doesnt really behave as I was expecting
// Having $0 % 5 == 0 I expected it to drop all values untill it found one divisible by 5
// But once it gets false, it just sinks all the other values
numbersPublisher
    .drop(while: {
        print($0 % 5 != 0)
        return $0 % 5 != 0
    })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Drop first

numbersPublisher
    .dropFirst(3)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Filter

let findEven = (1...9).publisher
findEven
    .filter({ $0 % 2 == 0 })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Last where

findEven.last { value in
    value % 2 == 0
}.sink(receiveCompletion: { completion in
    print("Completion:", completion)
}) { value in
    print("Last even:", value)
}

// MARK: - First where

findEven.first { value in
    value % 2 == 0
}.sink { value in
    print("First even value:", value)
}

// MARK: - Ignore output

let bigArray = (0...10000).publisher
bigArray.ignoreOutput().sink(receiveCompletion: { completion in
    print("Completion:", completion)
}) { value in
    print("Got:", value)
}.store(in: &subscriptions)

// MARK: - Compact map

let mixed = ["asdf", "1.2", "fdsa", "2.1"].publisher
mixed
    .compactMap({ Float($0) })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Remove duplicates

let duplicates = [1, 2, 2, 2, 3, 4, 5, 5, 6].publisher
duplicates.removeDuplicates().sink { value in
    print(value)
}.store(in: &subscriptions)

// MARK: - Scan

var dailyGainLoss: Int {
    .random(in: -10...10)
}
let october2019 = (0..<22)
    .map({ _ in dailyGainLoss })
    .publisher

october2019.scan(100) { (last, current) in
    max(0, last + current)
    }
    .sink { _ in }
    .store(in: &subscriptions)

// MARK: - Replace empty

[String]().publisher
    .replaceEmpty(with: "IT'S EMPTY!")
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Replace nil

["A", nil, "C"].publisher
    .replaceNil(with: "-")
    .map{ $0! }
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// MARK: - Flat map

struct Human {
    let name: String
    let health: CurrentValueSubject<Int, Never>

    init(name: String, health: Int) {
        self.name = name
        self.health = CurrentValueSubject(health)
    }
}

let humanWarrior = Human(name: "War", health: 100)
let humanMage = Human(name: "Mag", health: 50)

// Flat map will dig into the arena publisher and access it's inner publisher's value
let arena = CurrentValueSubject<Human, Never>(humanWarrior)
arena.flatMap({
    return $0.health
}).sink(receiveCompletion: { completion in
    print("Completion: \(completion)")
}) { value in
    print("health at: \(value)")
}.store(in: &subscriptions)

humanWarrior.health.value = 90

arena.value = humanMage

// MARK: - Try map

// Handle possible error
Just("Invalid path").tryMap {
    try FileManager.default.contentsOfDirectory(atPath: $0)
}.sink(receiveCompletion: { completion in
    print(completion)
}) { data in
    print(data)
}.store(in: &subscriptions)

// MARK: - Map oprator on key paths

struct Player {
    let hp: Int
    let mana: Int
}

let mage = Player(hp: 10, mana: 30)
let magePublisher = PassthroughSubject<Player, Never>()

// Access properties on struct via map and key path
magePublisher.map(\.hp, \.mana).sink { hp, mana in
    print("Mage has \(hp)hp and \(mana)mana")
}.store(in: &subscriptions)

magePublisher.send(mage)

// MARK: - Map

[1, 2, 3, 4, 5].publisher.map({ input -> Int in
    input * input
}).sink(receiveCompletion: { completion in
    print(completion)
}) { value in
    print(value)
}

// MARK: - Collect operator

// Collects and spits 2 by 2
["A", "B", "C", "D", "E"].publisher.collect(2).sink(receiveCompletion: { completion in
    print("Completion", completion)
}) { value in
    print(value)
}.store(in: &subscriptions)

// MARK: - Futures

let valueToIncrementInTheFuture = 1

let futureIncrement = Future<Int, Never> { promise in
    print("Start future increment")
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        promise(.success(valueToIncrementInTheFuture + 1))
    }
}

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
//intSubscription.cancel()
//intSubject.send(completion: .finished)
intSubject.send(24)

// MARK: - Type erased publisher

// Useful to hide subject implementation
// subject wraps publisher in AnyPublisher
let typeErasedPublisher = intSubject.eraseToAnyPublisher()

typeErasedPublisher.sink { value in
    print("type erased \(value)")
}.store(in: &subscriptions)

intSubject.send(99)

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
