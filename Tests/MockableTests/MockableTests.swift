// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MockableMacros)
import XCTest
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import MockableMacros

class MockableTests: XCTestCase {
	
	func test_Mockable_noArgs() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run()
			}
			
			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_async() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run() async
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run() async
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() async {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_hasOneAttribute() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				@MainActor
				func run() async
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				@MainActor
				func run() async
			}
			
			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@MainActor
				internal func run() async {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_hasTwoAttributes() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				@MainActor @available(iOS 15, *)
				func run() async
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				@MainActor @available(iOS 15, *)
				func run() async
			}
			
			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@MainActor @available(iOS 15, *)
				internal func run() async {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_throws() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run() throws
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run() throws
			}
			
			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runError: Error?
				internal func run() throws {
					runCalled = true
					if let error = runError {
						throw error
					}
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_asyncThrows() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run() async throws
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run() async throws
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runError: Error?
				internal func run() async throws {
					runCalled = true
					if let error = runError {
						throw error
					}
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_returnsOptionalValue() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run() -> String?
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run() -> String?
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runReturnValue: String?
				internal func run() -> String? {
					runCalled = true
					return runReturnValue
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(arg1: String)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(arg1: String)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal func run(arg1: String) {
					runCalled = true
					runArg1 = arg1
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_hasArgumentLabel() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(argument arg1: String)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(argument arg1: String)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal func run(argument arg1: String) {
					runCalled = true
					runArg1 = arg1
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_trailingClosure() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(callback: () -> Void)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(callback: () -> Void)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runCallback: (() -> Void)?
				internal func run(callback: () -> Void) {
					runCalled = true
					runCallback = callback
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_twoClosures() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(before: @escaping (Int) -> String, callback: () -> Void)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(before: @escaping (Int) -> String, callback: () -> Void)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runBefore: ((Int) -> String)?
				internal var runCallback: (() -> Void)?
				internal func run(before: @escaping (Int) -> String, callback: () -> Void) {
					runCalled = true
					runBefore = before
					runCallback = callback
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_optionalTrailingClosure() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(callback: (() -> Void)?)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(callback: (() -> Void)?)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runCallback: (() -> Void)?
				internal func run(callback: (() -> Void)?) {
					runCalled = true
					runCallback = callback
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_escapingTrailingClosure() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(callback: @escaping () -> Void)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(callback: @escaping () -> Void)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runCallback: (() -> Void)?
				internal func run(callback: @escaping () -> Void) {
					runCalled = true
					runCallback = callback
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_twoArgs() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(arg1: String, arg2: String)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(arg1: String, arg2: String)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal var runArg2: String?
				internal func run(arg1: String, arg2: String) {
					runCalled = true
					runArg1 = arg1
					runArg2 = arg2
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_multipleArgs() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(arg1: String, arg2: Int, arg3: Bool)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(arg1: String, arg2: Int, arg3: Bool)
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal var runArg2: Int?
				internal var runArg3: Bool?
				internal func run(arg1: String, arg2: Int, arg3: Bool) {
					runCalled = true
					runArg1 = arg1
					runArg2 = arg2
					runArg3 = arg3
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_returnsValue() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(arg1: String) -> String
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(arg1: String) -> String
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal var runReturnValue: String?
				internal func run(arg1: String) -> String {
					runCalled = true
					runArg1 = arg1
					return runReturnValue!
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_returnsOptionalValue_hasPropertyGet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int { get }
				func run() -> String?
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int { get }
				func run() -> String?
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var _prop: Int!
				internal var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				internal var runCalled = false
				internal var runReturnValue: String?
				internal func run() -> String? {
					runCalled = true
					return runReturnValue
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_returnsOptionalValue_hasPropertySet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int { set }
				func run() -> String?
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int { set }
				func run() -> String?
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var _prop: Int!
				internal var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				internal var runCalled = false
				internal var runReturnValue: String?
				internal func run() -> String? {
					runCalled = true
					return runReturnValue
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_returnsOptionalValue_hasPropertyGetSet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int { get set }
				func run() -> String?
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int { get set }
				func run() -> String?
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var _prop: Int!
				internal var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				internal var runCalled = false
				internal var runReturnValue: String?
				internal func run() -> String? {
					runCalled = true
					return runReturnValue
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_hasOptionalPropertyGet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int? { get }
				func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int? { get }
				func run()
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_hasOptionalPropertySet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int? { set }
				func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int? { set }
				func run()
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_hasOptionalPropertyGetSet() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				var prop: Int? { get set }
				func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				var prop: Int? { get set }
				func run()
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_twoMethods_firstOneArgsNoReturn_secondNoArgsAndReturns() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(arg1: String)
				func walk() -> String
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(arg1: String)
				func walk() -> String
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal func run(arg1: String) {
					runCalled = true
					runArg1 = arg1
				}

				internal var walkCalled = false
				internal var walkReturnValue: String?
				internal func walk() -> String {
					walkCalled = true
					return walkReturnValue!
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noSupportToClassAttributes() {
		assertMacroExpansion(
			"""
			@MainActor @Mockable
			protocol MyService {
				func run()
			}
			""",
			expandedSource:
			"""
			@MainActor 
			protocol MyService {
				func run()
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_hasSupportToMethodAttributes() {
		assertMacroExpansion(
			"""
			@MainActor @Mockable
			protocol MyService {
				@discardableResult func run()
			}
			""",
			expandedSource:
			"""
			@MainActor 
			protocol MyService {
				@discardableResult func run()
			}

			#if DEBUG
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@discardableResult
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_sendable() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService: Sendable {
				@discardableResult func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService: Sendable {
				@discardableResult func run()
			}

			#if DEBUG
			internal class MockMyService: MyService, @unchecked Sendable {
				internal init() {
				}

				internal var runCalled = false
				@discardableResult
				internal func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_nodeArgs_publicAccessLevel() {
		assertMacroExpansion(
			"""
			@Mockable(accessLevel: .public)
			protocol MyService {
				func run()
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run()
			}

			#if DEBUG
			public class MockMyService: MyService {
				public init() {
				}

				public var runCalled = false
				public func run() {
					runCalled = true
				}
			}
			#endif
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
}
#endif
