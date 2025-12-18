//
//  VariableDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct VariableDeclSyntaxComposer {
	
	let protocolName: String
	let decl: VariableDeclSyntax
	let accessLevel: MockableMacroAccessLevel
	let associatedType: String?
	let typealiases: [TypealiasInfo]
	
	init(
		_ protocolName: String,
		_ decl: VariableDeclSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ associatedType: String?,
		_ typealiases: [TypealiasInfo]
	) {
		self.protocolName = protocolName
		self.decl = decl
		self.accessLevel = accessLevel
		self.associatedType = associatedType
		self.typealiases = typealiases
	}
	
	func compose() -> [String] {
		decl
			.bindings
			.compactMap { binding -> (PatternBindingSyntax, IdentifierPatternSyntax)? in
				guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
					return nil
				}
				return (binding, pattern)
			}
			.compactMap { binding -> (PatternBindingSyntax, IdentifierPatternSyntax, TypeAnnotationSyntax)? in
				guard let typeAnnotation = binding.0.typeAnnotation else {
					return nil
				}
				return (binding.0, binding.1, typeAnnotation)
			}
			.map { (binding, idPattern, typeAnnotation) -> String in
				let propertyName = idPattern.identifier.text
				var propertyType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
				
				// Typealiases
				typealiases.forEach {
					propertyType = propertyType.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
				}
				
				let variableDefinition = "var \(propertyName): \(propertyType)"
				let updatedVariableDefinition: String
				if !propertyType.hasSuffix("?") {
					updatedVariableDefinition = """
					\(accessLevel) var _\(propertyName): \(propertyType)!
					\(accessLevel) \(variableDefinition) {
						get {
							_\(propertyName)
						}
						set {
							_\(propertyName) = newValue
						}
					}
					"""
					return updatedVariableDefinition
				} else {
					updatedVariableDefinition = variableDefinition
				}
				return updatedVariableDefinition
			}
	}
}

