// The Swift Programming Language
// https://docs.swift.org/swift-book

public enum MockableAccessLevel {
	case `public`
	case `internal`
	case `private`
}

@attached(peer, names: prefixed(Mock))
public macro Mockable(accessLevel: MockableAccessLevel = .public) = #externalMacro(module: "MockableMacros", type: "MockableMacro")
