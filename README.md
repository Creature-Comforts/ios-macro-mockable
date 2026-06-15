# ios-macro-mockable

`@Mockable` — a Swift macro that generates a `Mock<ProtocolName>` peer class for a protocol, with call-tracking flags, captured arguments, and stubbable return values.

```swift
@Mockable
protocol APIService {
	func fetchData() -> String
	func upload(data: String)
}

// Generates:
// class MockAPIService: APIService {
//     var fetchDataCalled = false
//     var fetchDataReturnValue: String = ""
//     func fetchData() -> String { ... }
//
//     var uploadCalled = false
//     var uploadData: String = ""
//     func upload(data: String) { ... }
// }
```

## Options

| Argument | Default | Description |
| --- | --- | --- |
| `accessLevel` | `.public` | Access level of the generated mock (`.public`, `.internal`, `.private`). |
| `associatedTypes` | `[]` | Concrete type names that replace the protocol's associated types in the mock, in declaration order. |

## Associated & primary associated types

When a protocol declares associated types (including [primary associated types](https://github.com/apple/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md), the `<...>` clause on the protocol name), pass `associatedTypes:` with one concrete type per `associatedtype` declaration, in order. The generated mock is a concrete (non-generic) class, so each associated type is replaced by the concrete type you supply.

```swift
@Mockable(associatedTypes: ["CustomResponse"])
protocol NetworkService<Response> {
	associatedtype Response
	func fetch() -> Response
}

// Generates a concrete mock — the `<Response>` clause is dropped and
// `Response` is replaced with `CustomResponse`:
//
// class MockNetworkService: NetworkService {
//     var fetchCalled = false
//     var fetchReturnValue: CustomResponse?
//     func fetch() -> CustomResponse { ... }
// }
```

This works whether or not the associated type is declared as *primary* (`protocol NetworkService<Response>`), and the primary-associated-type clause may carry a `where` constraint (e.g. `protocol NetworkService<Response> where Response: Equatable`). The number of entries in `associatedTypes` must match the number of `associatedtype` declarations, or the macro emits a diagnostic.

## Protocol inheritance

A peer macro only sees the protocol it is attached to — it cannot read the members of a parent protocol (those live in a separate declaration, often another file). To mock an inheritance chain, apply `@Mockable` to **every** protocol in the chain. The child mock then subclasses the parent's generated mock and inherits its mocked requirements:

```swift
@Mockable
protocol Animal {
	func eat()
}

@Mockable
protocol Dog: Animal {
	func bark()
}

// Generates:
// class MockAnimal: Animal {
//     var eatCalled = false
//     func eat() { ... }
// }
//
// class MockDog: MockAnimal, Dog {   // subclasses the parent mock
//     override init() { super.init() }
//     var barkCalled = false
//     func bark() { ... }
// }

let dog = MockDog()
dog.eat()   // inherited tracking from MockAnimal
dog.bark()
```

Notes:

- Every inherited name is treated as a mockable parent (i.e. the mock will subclass `Mock<Name>`) **except** well-known standard-library conformances — `Sendable`, `AnyObject`, `Equatable`, `Hashable`, `Comparable`, `Identifiable`, `Codable`/`Encodable`/`Decodable`, `Error`, `CaseIterable`, `RawRepresentable`, and similar — which are ignored.
- Swift allows a single superclass, so a protocol may inherit at most **one** mockable parent. Inheriting more than one (e.g. `Dog: Animal, Pet`) is a compile-time error; flatten the hierarchy or add the extra requirements to the mock manually.
- If you inherit a custom protocol but don't apply `@Mockable` to it, the generated child mock will reference a non-existent `Mock<Parent>` superclass and fail to compile.
