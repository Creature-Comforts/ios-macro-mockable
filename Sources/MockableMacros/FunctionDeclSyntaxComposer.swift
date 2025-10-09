//
//  FunctionDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

struct FunctionDeclSyntaxComposer {
	
	let decl: FunctionDeclSyntax
	let accessLevel: MockableMacroAccessLevel
	
	init(_ decl: FunctionDeclSyntax, _ accessLevel: MockableMacroAccessLevel) {
		self.decl = decl
		self.accessLevel = accessLevel
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
		let isThrow = decl.signature.effectSpecifiers?.throwsSpecifier != nil
		if isThrow {
			let funcBodyThrow = "\t\(accessLevel) var \(funcName)Error: Error?"
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
		let isThrow = decl.signature.effectSpecifiers?.throwsSpecifier != nil
		if isThrow {
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
		let params = parameters.map { $0.description }.joined(separator: "")
		
		let attrsText = decl.attributes.description.trimmingCharacters(in: .whitespacesAndNewlines)
		let asyncStr = decl.signature.effectSpecifiers?.asyncSpecifier.map { _ in " async" } ?? ""
		let throwsStr = decl.signature.effectSpecifiers?.throwsSpecifier.map { _ in " throws" } ?? ""
		let returnClauseStr = decl.signature.returnClause?.description ?? ""
		let returnStr = returnClauseStr.isEmpty ? "" : "\(returnClauseStr)"
		
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
	
	private func generateParameterProperties() -> [String] {
		return parameters.map { param in
			let argName = name(from: param).capitalized
			let type = translateFunctionParameterListElementToProperty(param)
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
