//
//  ProtocolDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct ProtocolDeclSyntaxComposer {
	
	let decl: ProtocolDeclSyntax
	
	var protoConformanceName: String {
		decl.name.text
	}
	
	func compose(_ node: AttributeSyntax) -> [DeclSyntax] {
		// Extract arguments from the @Mockable macro attribute
		let accessLevel = extractAccessLevelNodeArgument(node)
		let associatedType = extractAssociatedTypeNodeArgument(node)
		let typealiases = extractTypealiases(from: decl.memberBlock.members)
		let mockClass = composePeer(node, accessLevel, associatedType, typealiases)

		return [
			DeclSyntax(stringLiteral: mockClass)
		]
	}
	
	private func composePeer(
		_ node: AttributeSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedType: String? = nil,
		_ typealiases: [TypealiasInfo] = []
	) -> String {
		let mockClassName = "Mock\(protoConformanceName)"
		let impl = composeImpl(node, accessLevel, associatedType, typealiases)
		
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
		let declAssociatedType = extractDeclAssociatedTypes(from: decl.memberBlock.members).first?.name
		if  let associatedType, let declAssociatedType {
			mockClass = mockClass.replacingOccurrences(of: declAssociatedType, with: associatedType)
		}
		
		return mockClass
	}
	
	private func composeImpl(
		_ node: AttributeSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedType: String? = nil,
		_ typealiases: [TypealiasInfo] = []
	) -> String {
		
		let propertiesDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(VariableDeclSyntax.self) }
			.flatMap {
				VariableDeclSyntaxComposer(protoConformanceName, $0, accessLevel, associatedType, typealiases)
					.compose()
			}
		
		let methodDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
			.map {
				FunctionDeclSyntaxComposer(protoConformanceName, $0, accessLevel, associatedType, typealiases)
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
	
	private func extractAssociatedTypeNodeArgument(_ node: AttributeSyntax) -> String? {
		guard
			let arguments = node.arguments,
			case .argumentList(let list) = arguments,
			let associatedTypeArg = list.first(where: { $0.label?.text == "associatedType" })
		else {
			return nil
		}
		
		return associatedTypeArg.stringLiteralValue
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

extension LabeledExprSyntax {
	var stringLiteralValue: String? {
		guard
			let literal = expression.as(StringLiteralExprSyntax.self),
			literal.segments.count == 1,
			let segment = literal.segments.first?.as(StringSegmentSyntax.self)
		else {
			return nil
		}
		return segment.content.text
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
