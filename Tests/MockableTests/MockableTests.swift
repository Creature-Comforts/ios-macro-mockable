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
			
			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				func run() async {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				@MainActor
				func run() async {
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
			
			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				@MainActor @available(iOS 15, *)
				func run() async {
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
			
			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runError: Error?
				func run() throws {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runError: ServiceError?
				func run() throws(ServiceError) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runError: Error?
				func run() async throws {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runReturnValue: String?
				func run() -> String? {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				func run(arg1: String) {
					runCalled = true
					runArg1 = arg1
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_oneArg_dictionaryAndArrayShorthands() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(array: [String], dict: [String: String], arrayOfDict: [[String: String]], dictOfArray: [String: [String]])
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(array: [String], dict: [String: String], arrayOfDict: [[String: String]], dictOfArray: [String: [String]])
			}

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArray: [String] = []
				var runDict: [String: String] = [:]
				var runArrayOfDict: [[String: String]] = []
				var runDictOfArray: [String: [String]] = [:]
				func run(array: [String], dict: [String: String], arrayOfDict: [[String: String]], dictOfArray: [String: [String]]) {
					runCalled = true
					runArray = array
					runDict = dict
					runArrayOfDict = arrayOfDict
					runDictOfArray = dictOfArray
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				func run(_ arg1: String) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArgumentArg1: String = ""
				func run(argument arg1: String) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runCallback: (() -> Void)?
				func run(callback: () -> Void) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runBefore: ((Int) -> String)?
				var runCallback: (() -> Void)?
				func run(before: @escaping (Int) -> String, callback: () -> Void) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runCallback: (() -> Void)?
				func run(callback: (() -> Void)?) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runCallback: (() -> Void)?
				func run(callback: @escaping () -> Void) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				var runArg2: String = ""
				func run(arg1: String, arg2: String) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				var runArg2: Int = 0
				var runArg3: Bool = false
				func run(arg1: String, arg2: Int, arg3: Bool) {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				var runReturnValue: String = ""
				func run(arg1: String) -> String {
					runCalled = true
					runArg1 = arg1
					return runReturnValue
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

			class MockMyService: MyService {
				init() {
				}

				var _prop: Int!
				var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				var runCalled = false
				var runReturnValue: String?
				func run() -> String? {
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

			class MockMyService: MyService {
				init() {
				}

				var _prop: Int!
				var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				var runCalled = false
				var runReturnValue: String?
				func run() -> String? {
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

			class MockMyService: MyService {
				init() {
				}

				var _prop: Int!
				var prop: Int {
					get {
						_prop
					}
					set {
						_prop = newValue
					}
				}

				var runCalled = false
				var runReturnValue: String?
				func run() -> String? {
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

			class MockMyService: MyService {
				init() {
				}

				var prop: Int?

				var runCalled = false
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var prop: Int?

				var runCalled = false
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var prop: Int?

				var runCalled = false
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: String = ""
				func run(arg1: String) {
					runCalled = true
					runArg1 = arg1
				}

				var walkCalled = false
				var walkReturnValue: String = ""
				func walk() -> String {
					walkCalled = true
					return walkReturnValue
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				@discardableResult
				func run() {
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

			class MockMyService: MyService, @unchecked Sendable {
				init() {
				}

				var runCalled = false
				@discardableResult
				func run() {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runReturnValue: CustomType?
				func run() -> CustomType {
					runCalled = true
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}
	
	func test_Mockable_associatedType_primaryTypes_usedInProperty() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["CustomType"])
			protocol MyService<PrimaryType> {
				associatedtype PrimaryType
				var current: PrimaryType { get }
				func run() -> PrimaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService<PrimaryType> {
				associatedtype PrimaryType
				var current: PrimaryType { get }
				func run() -> PrimaryType
			}

			class MockMyService: MyService {
				init() {
				}

				var _current: CustomType!
				var current: CustomType {
					get {
						_current
					}
					set {
						_current = newValue
					}
				}

				var runCalled = false
				var runReturnValue: CustomType?
				func run() -> CustomType {
					runCalled = true
					return runReturnValue!
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_associatedType_primaryTypes_withWhereClause() {
		assertMacroExpansion(
			"""
			@Mockable(associatedTypes: ["CustomType"])
			protocol MyService<PrimaryType> where PrimaryType: Equatable {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}
			""",
			expandedSource:
			"""
			protocol MyService<PrimaryType> where PrimaryType: Equatable {
				associatedtype PrimaryType
				func run() -> PrimaryType
			}

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runReturnValue: CustomType?
				func run() -> CustomType {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runReturnValue: CustomType?
				func run() -> CustomType {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg: FirstType?
				var runReturnValue: SecondType?
				func run(arg: FirstType) -> SecondType {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg: FirstType?
				var runReturnValue: SecondType?
				func run(arg: FirstType) -> SecondType {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runReturnValue: MyService.T?
				func run() -> MyService.T {
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

			class MockMyService: MyService {
				init() {
				}

				var runCalled = false
				var runArg1: MyService.K?
				var runArg2: MyService.V?
				var runReturnValue: MyService.T?
				func run(arg1: MyService.K, arg2: MyService.V) -> MyService.T {
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
	
	func test_Mockable_primitivesCollections_assignDefaults() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol MyService {
				func run(intArg: Int, stringArg: String, uuidArg: UUID, arrayArg: [Int], setArg: Set<String>, dictArg: [String: Bool], customArg: CustomType) -> String
			}
			""",
			expandedSource:
			"""
			protocol MyService {
				func run(intArg: Int, stringArg: String, uuidArg: UUID, arrayArg: [Int], setArg: Set<String>, dictArg: [String: Bool], customArg: CustomType) -> String
			}

			class MockMyService: MyService {
				init() {
				}
			
				var runCalled = false
				var runIntArg: Int = 0
				var runStringArg: String = ""
				var runUuidArg: UUID = UUID()
				var runArrayArg: [Int] = []
				var runSetArg: Set<String> = []
				var runDictArg: [String: Bool] = [:]
				var runCustomArg: CustomType?
				var runReturnValue: String = ""
				func run(intArg: Int, stringArg: String, uuidArg: UUID, arrayArg: [Int], setArg: Set<String>, dictArg: [String: Bool], customArg: CustomType) -> String {
					runCalled = true
					runIntArg = intArg
					runStringArg = stringArg
					runUuidArg = uuidArg
					runArrayArg = arrayArg
					runSetArg = setArg
					runDictArg = dictArg
					runCustomArg = customArg
					return runReturnValue
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_inheritance_single() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol Animal {
				func eat()
			}
			@Mockable
			protocol Dog: Animal {
				func bark()
			}
			""",
			expandedSource:
			"""
			protocol Animal {
				func eat()
			}

			class MockAnimal: Animal {
				init() {
				}

				var eatCalled = false
				func eat() {
					eatCalled = true
				}
			}
			protocol Dog: Animal {
				func bark()
			}

			class MockDog: MockAnimal, Dog {
				override init() {
					super.init()
				}

				var barkCalled = false
				func bark() {
					barkCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_inheritance_sendableParent() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol Dog: Animal, Sendable {
				func bark()
			}
			""",
			expandedSource:
			"""
			protocol Dog: Animal, Sendable {
				func bark()
			}

			class MockDog: MockAnimal, Dog, @unchecked Sendable {
				override init() {
					super.init()
				}

				var barkCalled = false
				func bark() {
					barkCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_inheritance_publicAccessLevel() {
		assertMacroExpansion(
			"""
			@Mockable(accessLevel: .public)
			protocol Dog: Animal {
				func bark()
			}
			""",
			expandedSource:
			"""
			protocol Dog: Animal {
				func bark()
			}

			public class MockDog: MockAnimal, Dog {
				public override init() {
					super.init()
				}

				public var barkCalled = false
				public func bark() {
					barkCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_inheritance_onlyDenylistedParentsAreIgnored() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol Dog: Sendable, Equatable {
				func bark()
			}
			""",
			expandedSource:
			"""
			protocol Dog: Sendable, Equatable {
				func bark()
			}

			class MockDog: Dog, @unchecked Sendable {
				init() {
				}

				var barkCalled = false
				func bark() {
					barkCalled = true
				}
			}
			""",
			macros: ["Mockable": MockableMacro.self]
		)
	}

	func test_Mockable_inheritance_multipleParents_emitsError() {
		assertMacroExpansion(
			"""
			@Mockable
			protocol Dog: Animal, Pet {
				func bark()
			}
			""",
			expandedSource:
			"""
			protocol Dog: Animal, Pet {
				func bark()
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@Mockable cannot synthesize a mock inheriting from multiple mockable parents (Animal, Pet). Swift allows a single superclass only; flatten the hierarchy or add the extra requirements manually.",
					line: 1,
					column: 1,
					severity: .error
				)
			],
			macros: ["Mockable": MockableMacro.self]
		)
	}
}
#endif
