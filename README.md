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
