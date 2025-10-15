//
//  ProtocolDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct ProtocolDeclSyntaxComposer {
	
	let decl: ProtocolDeclSyntax
	
	func compose(_ node: AttributeSyntax) -> [DeclSyntax] {
		// Extract arguments from the @Mockable macro attribute
		let accessLevel = extractAccessLevelNodeArgument(node)
		let mockClass = composePeer(node, accessLevel)

		return [
			DeclSyntax(stringLiteral: mockClass)
		]
	}
	
	private func composePeer(_ node: AttributeSyntax, _ accessLevel: MockableMacroAccessLevel) -> String {
		let protoConformanceName = decl.name.text
		let mockClassName = "Mock\(protoConformanceName)"
		let impl = composeImpl(node, accessLevel)
		
		let sendableConformance: String
		if !decl.isSendable() {
			sendableConformance = ""
		} else {
			sendableConformance = ", @unchecked Sendable"
		}
		
		let mockClass = """
		\(accessLevel) class \(mockClassName): \(protoConformanceName)\(sendableConformance) {
			\(accessLevel) init() { }
			
			\(impl)
		}
		"""
		
		return mockClass
	}
	
	private func composeImpl(_ node: AttributeSyntax, _ accessLevel: MockableMacroAccessLevel) -> String {
		
		let propertiesDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(VariableDeclSyntax.self) }
			.flatMap {
				VariableDeclSyntaxComposer($0, accessLevel)
					.compose()
			}
		
		let methodDecls = decl.memberBlock.members
			.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
			.map {
				FunctionDeclSyntaxComposer($0, accessLevel)
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
		
		// Attributes
//		let filteredAttrs = decl.attributes.filter {
//			$0.as(AttributeSyntax.self)?.attributeName.description != "Mockable"
//		}
//		let protoAttrsText = filteredAttrs.description
		
		return impl
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
}
