//
//  ProtocolDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ProtocolDeclSyntaxComposer {
	
	let decl: ProtocolDeclSyntax
	
	var protoConformanceName: String {
		decl.name.text
	}
	
	var members: MemberBlockItemListSyntax {
		decl.memberBlock.members
	}
	
	func compose(
		_ node: AttributeSyntax,
		_ context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Extract arguments from the @Mockable macro attribute
		let accessLevel = extractAccessLevelNodeArgument(node)
		let associatedTypes = extractAssociatedTypesNodeArgument(node)
		let typealiases = extractTypealiases(from: decl.memberBlock.members)
		let mockClass = try composePeer(node, context, accessLevel, associatedTypes, typealiases)

		return [
			DeclSyntax(stringLiteral: mockClass)
		]
	}
	
	private func composePeer(
		_ node: AttributeSyntax,
		_ context: some MacroExpansionContext,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedTypes: [String]? = nil,
		_ typealiases: [TypealiasInfo] = []
	) throws -> String {
		let mockClassName = "Mock\(protoConformanceName)"
		let impl = composeImpl(node, accessLevel, associatedTypes, typealiases)

		// Protocol inheritance: a child mock subclasses its parent's generated
		// mock (Mock<Parent>) so it inherits the parent's mocked requirements.
		// Swift allows a single superclass only, so more than one mockable
		// parent is unsupported.
		let mockableParents = extractMockableParents()
		guard mockableParents.count <= 1 else {
			context.diagnose(
				Diagnostic(
					node: Syntax(node),
					message: MockableDiagnostic.multipleMockableParents(mockableParents)
				)
			)
			return ""
		}
		let superclass = mockableParents.first.map { "Mock\($0)" }

		var inheritedTypes: [String] = []
		if let superclass {
			inheritedTypes.append(superclass)
		}
		inheritedTypes.append(protoConformanceName)
		if decl.isSendable() {
			inheritedTypes.append("@unchecked Sendable")
		}
		let inheritanceList = inheritedTypes.joined(separator: ", ")

		let initDecl: String
		if superclass != nil {
			initDecl = "\(accessLevel.syntax)override init() {\n\t\tsuper.init()\n\t}"
		} else {
			initDecl = "\(accessLevel.syntax)init() { }"
		}

		var mockClass = """
		\(accessLevel.syntax)class \(mockClassName): \(inheritanceList) {
			\(initDecl)

			\(impl)
		}
		"""
		
		// Associated types
		let declAssociatedTypes = extractDeclAssociatedTypes(from: members)
		if  let associatedTypes {
			guard associatedTypes.count == declAssociatedTypes.count else {
				context.diagnose(
					Diagnostic(
						node: Syntax(node),
						message: MockableDiagnostic.notEnoughAssociatedTypes(declAssociatedTypes.count, associatedTypes.count)
					)
				)
				return ""
			}
			for (target, replacement) in zip(declAssociatedTypes, associatedTypes) {
				mockClass = mockClass.replacingOccurrences(of: target.name, with: replacement)
			}
		}
		
		return mockClass
	}
	
	private func composeImpl(
		_ node: AttributeSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedTypes: [String]? = nil,
		_ typealiases: [TypealiasInfo] = []
	) -> String {
		
		let propertiesDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(VariableDeclSyntax.self) }
			.flatMap {
				VariableDeclSyntaxComposer(protoConformanceName, $0, accessLevel, typealiases)
					.compose()
			}
		
		let methodDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
			.map {
				FunctionDeclSyntaxComposer(protoConformanceName, $0, accessLevel, typealiases)
					.compose()
			}
		
		var impl = ""
		if propertiesDecls.count > 0 {
			impl += propertiesDecls.joined(separator: "\n")
			impl += "\n\n"
		}
		if methodDecls.count > 0 {
			impl += methodDecls.joined(separator: "\n\n")
		}
		
		return impl
	}
	
	// MARK: - Extract values

	/// Inherited names that are NOT user protocols carrying mockable
	/// requirements, so they must not be treated as a mockable parent.
	private static let nonMockableInheritedTypes: Set<String> = [
		"Sendable", "AnyObject", "Any", "AnyHashable",
		"Equatable", "Hashable", "Comparable", "Identifiable",
		"Codable", "Encodable", "Decodable",
		"Error", "LocalizedError",
		"CustomStringConvertible", "CustomDebugStringConvertible",
		"CaseIterable", "RawRepresentable",
		"Sequence", "Collection", "IteratorProtocol",
		"ObservableObject",
	]

	/// Protocol names from the inheritance clause that the child mock should
	/// subclass via `Mock<Name>`, excluding well-known stdlib conformances.
	private func extractMockableParents() -> [String] {
		decl.inheritanceClause?.inheritedTypes.compactMap { inherited -> String? in
			let name = inherited.type.trimmedDescription
			guard !Self.nonMockableInheritedTypes.contains(name) else {
				return nil
			}
			return name
		} ?? []
	}

	private func extractAccessLevelNodeArgument(_ node: AttributeSyntax) -> MockableMacroAccessLevel {
		var accessLevel: MockableMacroAccessLevel = .internal
		guard let arguments = node.arguments,
			  case .argumentList(let list) = arguments else { return accessLevel }
		
		for arg in list {
			if let memberAccess = arg.expression.as(MemberAccessExprSyntax.self) {
				accessLevel = MockableMacroAccessLevel(rawValue: memberAccess.declName.baseName.text)!
			}
		}
		return accessLevel
	}
	
	private func extractAssociatedTypesNodeArgument(_ node: AttributeSyntax) -> [String]? {
		guard
			let arguments = node.arguments,
			case .argumentList(let list) = arguments,
			let associatedTypeArg = list.first(where: { $0.label?.text == "associatedTypes" }),
			let listSyntax = associatedTypeArg.expression.as(ArrayExprSyntax.self)
		else {
			return nil
		}
		
		return listSyntax.elements.compactMap {
			if let strSyntax = $0.expression.as(StringLiteralExprSyntax.self) {
				return strSyntax.segments.first?.description
			}
			return nil
		}
	}
	
	private func extractDeclAssociatedTypes(from members: MemberBlockItemListSyntax) -> [AssociatedTypeInfo] {
		members.compactMap { member -> AssociatedTypeInfo? in
			guard let assoc = member.decl.as(AssociatedTypeDeclSyntax.self) else {
				return nil
			}
			
			return AssociatedTypeInfo(
				name: assoc.name.text,
				constraint: assoc.inheritanceClause?
					.inheritedTypes.first?.type.description,
				defaultType: assoc.initializer?
					.value
					.description
			)
		}
	}
	
	private func extractTypealiases(from members: MemberBlockItemListSyntax) -> [TypealiasInfo] {
		members.compactMap { item in
			guard
				let typealiasDecl = item.decl.as(TypeAliasDeclSyntax.self)
			else { return nil }
			
			let initialiser = typealiasDecl.initializer
			return TypealiasInfo(
				name: typealiasDecl.name.text,
				underlyingType: initialiser.value.trimmedDescription
			)
		}
	}
}

struct AssociatedTypeInfo {
	let name: String
	let constraint: String?
	let defaultType: String?
}

struct TypealiasInfo {
	let name: String
	let underlyingType: String
}

enum MockableDiagnostic: DiagnosticMessage {
	case notEnoughAssociatedTypes(Int, Int)
	case multipleMockableParents([String])

	var message: String {
		switch self {
		case .notEnoughAssociatedTypes(let expected, let received):
			return "Not enough associated type replacements declared: expected \(expected), received \(received)."
		case .multipleMockableParents(let parents):
			return "@Mockable cannot synthesize a mock inheriting from multiple mockable parents (\(parents.joined(separator: ", "))). Swift allows a single superclass only; flatten the hierarchy or add the extra requirements manually."
		}
	}

	var diagnosticID: MessageID {
		switch self {
		case .notEnoughAssociatedTypes:
			return MessageID(domain: "MockableMacro", id: "notEnoughAssociatedTypes")
		case .multipleMockableParents:
			return MessageID(domain: "MockableMacro", id: "multipleMockableParents")
		}
	}

	var severity: DiagnosticSeverity {
		.error
	}
}
