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
			
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() async {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@MainActor
				internal func run() async {
					runCalled = true
				}
			}
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
			
			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@MainActor @available(iOS 15, *)
				internal func run() async {
					runCalled = true
				}
			}
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
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_noArgs_throwsCustomError() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run() throws(ServiceError)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run() throws(ServiceError)
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runError: ServiceError?
				internal func run() throws(ServiceError) {
					runCalled = true
					if let error = runError {
						throw error
					}
				}
			}
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
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_ommittedArgumentLabel() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(_ arg1: String)
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(_ arg1: String)
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: String?
				internal func run(_ arg1: String) {
					runCalled = true
					runArg1 = arg1
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArgumentArg1: String?
				internal func run(argument arg1: String) {
					runCalled = true
					runArgumentArg1 = arg1
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				var prop: Int?

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				@discardableResult
				internal func run() {
					runCalled = true
				}
			}
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

			internal class MockMyService: MyService, @unchecked Sendable {
				internal init() {
				}

				internal var runCalled = false
				@discardableResult
				internal func run() {
					runCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_publicAccessLevel() {
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

			public class MockMyService: MyService {
				public init() {
				}

				public var runCalled = false
				public func run() {
					runCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_primaryTypes_single() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["CustomType"])
			protocol MyService<PrimaryType> {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService<PrimaryType> {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runReturnValue: CustomType?
				internal func run() -> CustomType {
					runCalled = true
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_single() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["CustomType"])
			protocol MyService {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runReturnValue: CustomType?
				internal func run() -> CustomType {
					runCalled = true
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_primaryTypes_multiple() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["FirstType", "SecondType"])
			protocol MyService<PrimaryType, SecondaryType> {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService<PrimaryType, SecondaryType> {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg: FirstType?
				internal var runReturnValue: SecondType?
				internal func run(arg: FirstType) -> SecondType {
					runCalled = true
					runArg = arg
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_multiple() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["FirstType", "SecondType"])
			protocol MyService {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg: FirstType?
				internal var runReturnValue: SecondType?
				internal func run(arg: FirstType) -> SecondType {
					runCalled = true
					runArg = arg
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_multiple_notEnoughDeclaredReplacements() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["FirstType"])
			protocol MyService {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				associatedtype PrimaryType
				associatedtype SecondaryType
				func run(arg: PrimaryType) -> SecondaryType
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "Not enough associated type replacements declared: expected 2, received 1.",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_typealias_single() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				typealias T = String
				func run() -> T
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				typealias T = String
				func run() -> T
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runReturnValue: MyService.T?
				internal func run() -> MyService.T {
					runCalled = true
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_typealias_multiple() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				typealias K = Int
				typealias V = Double
				typealias T = String
				func run(arg1: K, arg2: V) -> T
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				typealias K = Int
				typealias V = Double
				typealias T = String
				func run(arg1: K, arg2: V) -> T
			}

			internal class MockMyService: MyService {
				internal init() {
				}

				internal var runCalled = false
				internal var runArg1: MyService.K?
				internal var runArg2: MyService.V?
				internal var runReturnValue: MyService.T?
				internal func run(arg1: MyService.K, arg2: MyService.V) -> MyService.T {
					runCalled = true
					runArg1 = arg1
					runArg2 = arg2
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
}
#endif
