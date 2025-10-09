//
//  VariableDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct VariableDeclSyntaxComposer {
	
	let decl: VariableDeclSyntax
	let accessLevel: MockableMacroAccessLevel
	
	init(_ decl: VariableDeclSyntax, _ accessLevel: MockableMacroAccessLevel) {
		self.decl = decl
		self.accessLevel = accessLevel
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
				let propertyType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
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

