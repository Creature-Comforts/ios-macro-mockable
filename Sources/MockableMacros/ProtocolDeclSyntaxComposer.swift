//
//  ProtocolDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

enum ProtocolDeclSyntaxComposerError: Error {
	case notEnoughAssociatedTypes
}

struct ProtocolDeclSyntaxComposer {
	
	let decl: ProtocolDeclSyntax
	
	var protoConformanceName: String {
		decl.name.text
	}
	
	var members: MemberBlockItemListSyntax {
		decl.memberBlock.members
	}
	
	func compose(_ node: AttributeSyntax) throws -> [DeclSyntax] {
		// Extract arguments from the @Mockable macro attribute
		let accessLevel = extractAccessLevelNodeArgument(node)
		let associatedTypes = extractAssociatedTypesNodeArgument(node)
		let typealiases = extractTypealiases(from: decl.memberBlock.members)
		let mockClass = try composePeer(node, accessLevel, associatedTypes, typealiases)

		return [
			DeclSyntax(stringLiteral: mockClass)
		]
	}
	
	private func composePeer(
		_ node: AttributeSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedTypes: [String]? = nil,
		_ typealiases: [TypealiasInfo] = []
	) throws -> String {
		let mockClassName = "Mock\(protoConformanceName)"
		let impl = composeImpl(node, accessLevel, associatedTypes, typealiases)
		
		let sendableConformance: String
		if !decl.isSendable() {
			sendableConformance = ""
		} else {
			sendableConformance = ", @unchecked Sendable"
		}
		
		var mockClass = """
		\(accessLevel) class \(mockClassName): \(protoConformanceName)\(sendableConformance) {
			\(accessLevel) init() { }
			
			\(impl)
		}
		"""
		
		// Associated types
		let declAssociatedTypes = extractDeclAssociatedTypes(from: members)
		if  let associatedTypes {
			guard associatedTypes.count == declAssociatedTypes.count else {
				throw ProtocolDeclSyntaxComposerError.notEnoughAssociatedTypes
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
