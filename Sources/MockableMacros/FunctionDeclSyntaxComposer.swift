//
//  FunctionDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct FunctionDeclSyntaxComposer {
	
	let protocolName: String
	let decl: FunctionDeclSyntax
	let accessLevel: MockableMacroAccessLevel
	let typealiases: [TypealiasInfo]
	
	init(
		_ protocolName: String,
		_ decl: FunctionDeclSyntax,
		_ accessLevel: MockableMacroAccessLevel,
		_ typealiases: [TypealiasInfo]
	) {
		self.protocolName = protocolName
		self.decl = decl
		self.accessLevel = accessLevel
		self.typealiases = typealiases
	}
	
	var funcName: String {
		decl.name.text
	}
	
	var parameters: FunctionParameterListSyntax {
		decl.signature.parameterClause.parameters
	}
	
	var returnType: String? {
		decl.signature.returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	var props: [String] = []
	var funcBodyPropAssignments: [String] = []
	
	func generateFuncProperties() -> Self {
		// Called tracking property
		var props = ["\(accessLevel) var \(funcName)Called = false"]
		
		// Argument tracking properties (for all parameters)
		let argProps = generateParameterProperties()
		props.append(contentsOf: argProps)
		
		// Throws
		if let throwsClause = decl.signature.effectSpecifiers?.throwsClause {
			let optionalError: String
			if let errorType = throwsClause.type {
				optionalError = errorType.description
			} else {
				optionalError = "Error"
			}
			let funcBodyThrow = "\t\(accessLevel) var \(funcName)Error: \(optionalError)?"
			props.append(funcBodyThrow)
		}
		
		// Return value property (if method returns something)
		if let returnType = returnType, returnType != "Void" {
			let returnProp = generateReturnProperty(returnType)
			props.append(returnProp)
		}
		
		var updatedCopy = self
		updatedCopy.props = props
		
		return updatedCopy
	}
	
	func generateFuncBody() -> Self {
		// Function body
		var funcBodyComponents = [String]()
		funcBodyComponents.append("\(funcName)Called = true")
		
		// Assign arguments inside function
		let argsAssignment: String = parameters
			.map { param in
				let name = name(from: param)
				return "\t\(funcName)\(name.capitalized) = \(name)"
			}
			.joined(separator: "\n")
		
		if argsAssignment.count > 0 {
			funcBodyComponents.append(argsAssignment)
		}
		
		// Throws
		let isThrow = decl.signature.effectSpecifiers?.throwsClause != nil
		if  isThrow {
			let funcBodyThrow = """
			\tif let error = \(funcName)Error {
				\tthrow error
			\t}
			"""
			funcBodyComponents.append(funcBodyThrow)
		}
		
		// Returns value
		if let returnType = returnType, returnType != "Void" {
			var funcBodyReturn = "\treturn \(funcName)ReturnValue"
			if let funcReturnType = decl.signature.returnClause?.description, !funcReturnType.hasSuffix("?") {
				funcBodyReturn += "!"
			}
			funcBodyComponents.append(funcBodyReturn)
		}
		
		var updatedCopy = self
		updatedCopy.funcBodyPropAssignments = funcBodyComponents
		
		return updatedCopy
	}
	
	func buildFunction() -> String {
		let funcBody = funcBodyPropAssignments.joined(separator: "\n")
		let params = parameters
			.map {
				let components = $0.description.components(separatedBy: ": ")
				var overridenType = components[1]
				// Typealiases
				typealiases.forEach {
					overridenType = overridenType.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
				}
				return "\(components[0]): \(overridenType)"
			}
			.joined(separator: "")
		
		let attrsText = decl.attributes.description.trimmingCharacters(in: .whitespacesAndNewlines)
		let asyncStr = decl.signature.effectSpecifiers?.asyncSpecifier.map { _ in " async" } ?? ""
		let throwsClause = decl.signature.effectSpecifiers?.throwsClause.map { clause in
			if let errorType = clause.type {
				return " throws(\(errorType.description))"
			} else {
				return " throws"
			}
		}
		let throwsStr = throwsClause ?? ""
		let returnClauseStr = decl.signature.returnClause?.description ?? ""
		var returnStr = returnClauseStr.isEmpty ? "" : "\(returnClauseStr)"
		
		// Typealiases
		typealiases.forEach {
			returnStr = returnStr.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
		}
		
		let funcText = """
		\(accessLevel) func \(funcName)(\(params))\(asyncStr)\(throwsStr)\(returnStr) {
			\(funcBody)
		}
		"""
		
		if attrsText != "" {
			return """
			\(props.joined(separator: "\n"))
			\(attrsText)
			\(funcText)
			"""
		} else {
			return """
			\(props.joined(separator: "\n"))
			\(funcText)
			"""
		}
	}
	
	func compose() -> String {
		generateFuncProperties()
			.generateFuncBody()
			.buildFunction()
	}
	
	// MARK: - Private methods
	
	private func generateParameterProperties() -> [String] {
		return parameters.map { param in
			let argName = name(from: param).capitalized
			var type = translateFunctionParameterListElementToProperty(param)
			
			// Typealiases
			typealiases.forEach {
				type = type.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
			}
			
			return "\(accessLevel) var \(funcName)\(argName): \(type)"
		}
	}
	
	private func translateFunctionParameterListElementToProperty(_ param: FunctionParameterListSyntax.Element) -> String {
		// Escaping closures
		if let funcType = param.type.as(AttributedTypeSyntax.self),
		   let funcBaseType = funcType.baseType.as(FunctionTypeSyntax.self) {
			return translateFunctionTypeSyntaxToProperty(funcBaseType)
		}
		// Non-escaping closures
		else if let funcBaseType = param.type.as(FunctionTypeSyntax.self) {
			return translateFunctionTypeSyntaxToProperty(funcBaseType)
		} else {
			// Non-closure: ensure it's optional if not already
			var type = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let isOptional = type.hasSuffix("?")
			if !isOptional {
				type += "?"
			}
			return type
		}
	}
	
	private func translateFunctionTypeSyntaxToProperty(_ funcBaseType: FunctionTypeSyntax) -> String {
		let input = funcBaseType.parameters.description.trimmingCharacters(in: .whitespacesAndNewlines)
		let output = funcBaseType.returnClause.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
		let type = "((\(input)) -> \(output))?"
		return type
	}
	
	private func generateReturnProperty(_ returnType: String) -> String {
		var type = returnType.trimmingCharacters(in: .whitespacesAndNewlines)
		if let funcType = decl.signature.returnClause?.type.as(FunctionTypeSyntax.self) {
			// normalize closure return type too
			let input = funcType.parameters.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let output = funcType.returnClause.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
			type = "((\(input)) -> \(output))?"
		} else {
			let isOptional = type.hasSuffix("?")
			if !isOptional {
				type += "?"
			}
		}
		
		// Typealiases
		typealiases.forEach {
			type = type.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
		}
		
		let returnProperty = "\(accessLevel) var \(funcName)ReturnValue: \(type)"
		return returnProperty
	}
	
	private func name(from param: FunctionParameterListSyntax.Element) -> String {
		let firstName = param.firstName.text
		let secondName = param.secondName?.text
		if let secondName = secondName {
			return secondName
		} else {
			return firstName
		}
	}
}
