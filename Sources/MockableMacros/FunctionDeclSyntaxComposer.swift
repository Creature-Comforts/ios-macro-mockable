//
//  FunctionDeclSyntaxComposer.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax
import Foundation

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
		var props = ["\(accessLevel.syntax)var \(funcName)Called = false"]
		
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
			let funcBodyThrow = "\t\(accessLevel.syntax)var \(funcName)Error: \(optionalError)?"
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
				let variableName = name(from: param)
				let variableValue = name(from: param, prefersSecondName: true)
				return "\t\(funcName)\(variableName.capitalisingFirstLetter()) = \(variableValue)"
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
			let typeName = returnType.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let primitiveType = getPrimitiveDefaultValue(typeName)
			if !typeName.hasSuffix("?") && !isTypePrimitive(primitiveType) {
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
				let paramDesc = $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
				guard let colonIndex = paramDesc.firstIndex(of: ":") else {
					return paramDesc // fallback, no type found
				}
				let paramName = paramDesc[..<colonIndex].trimmingCharacters(in: .whitespacesAndNewlines)
				var overriddenType = paramDesc[paramDesc.index(after: colonIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
				
				// Typealiases
				typealiases.forEach {
					overriddenType = overriddenType.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
				}
				
				return "\(paramName): \(overriddenType)"
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
		\(accessLevel.syntax)func \(funcName)(\(params))\(asyncStr)\(throwsStr)\(returnStr) {
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
			let argName = name(from: param).capitalisingFirstLetter()
			
			// Translate type (closures handled)
			var type = translateFunctionParameterListElementToProperty(param)
			
			// Typealiases
			typealiases.forEach {
				type = type.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
			}
			
			// Determine default or optional
			let primitiveType = getPrimitiveDefaultValue(type)
			switch primitiveType {
			case .plain(let value), .array(let value), .set(let value), .dictionary(let value):
				return "\(accessLevel.syntax)var \(funcName)\(argName): \(type) = \(value)"
			case .notPrimitive:
				type = convertToOptionalIfNeeded(type)
				return "\(accessLevel.syntax)var \(funcName)\(argName): \(type)"
			}
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
			return param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
		}
	}
	
	private func translateFunctionTypeSyntaxToProperty(_ funcBaseType: FunctionTypeSyntax) -> String {
		let input = funcBaseType.parameters.description.trimmingCharacters(in: .whitespacesAndNewlines)
		let output = funcBaseType.returnClause.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
		return "((\(input)) -> \(output))"
	}
	
	private func generateReturnProperty(_ returnType: String) -> String {
		var type = returnType.trimmingCharacters(in: .whitespacesAndNewlines)
		if let funcType = decl.signature.returnClause?.type.as(FunctionTypeSyntax.self) {
			// normalize closure return type too
			let input = funcType.parameters.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let output = funcType.returnClause.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
			type = "((\(input)) -> \(output))"
		}
		
		// Typealiases
		typealiases.forEach {
			type = type.replacingOccurrences(of: $0.name, with: "\(protocolName).\($0.name)")
		}
		
		// Determine default or optional
		let defaultValue = getPrimitiveDefaultValue(type)
		switch defaultValue {
		case .plain(let value), .array(let value), .set(let value), .dictionary(let value):
			return "\(accessLevel.syntax)var \(funcName)ReturnValue: \(type) = \(value)"
		case .notPrimitive:
			type = convertToOptionalIfNeeded(type)
			return "\(accessLevel.syntax)var \(funcName)ReturnValue: \(type)"
		}
	}
	
	private func convertToOptionalIfNeeded(_ type: String) -> String {
		var optionalType = type
		let isOptional = optionalType.hasSuffix("?")
		if !isOptional {
			optionalType += "?"
		}
		return optionalType
	}
	
	private func name(from param: FunctionParameterListSyntax.Element, prefersSecondName: Bool = false) -> String {
		let firstName = param.firstName.text
		guard let secondName = param.secondName?.text else {
			return firstName
		}
		if prefersSecondName {
			return secondName
		} else {
			guard firstName != "_" else { return secondName }
			return firstName + (secondName.capitalisingFirstLetter())
		}
	}
	
	private func defaultValue(for type: String) -> ExprSyntax {
		switch type {
		case "Int", "Double", "Decimal", "Float":
			return ExprSyntax("0")
		case "CGFloat": return ExprSyntax("0")
		case "CGSize": return ExprSyntax("CGSize.zero")
		case "CGPoint": return ExprSyntax("CGPoint.zero")
		case "CGRect": return ExprSyntax("CGRect.zero")
		case "Bool": return ExprSyntax("false")
		case "URL": return ExprSyntax("URL(string: \"https://creaturecomforts.co.uk\")")
		case "Data": return ExprSyntax("Data()")
		case "Date": return ExprSyntax("Date()")
		case "String": return ExprSyntax("\"\"")
		case "UUID": return ExprSyntax("UUID()")
		default: return ExprSyntax("")
		}
	}
	
	enum PrimitiveTypeDefaultValue {
		case plain(ExprSyntax)
		case array(ExprSyntax)
		case set(ExprSyntax)
		case dictionary(ExprSyntax)
		case notPrimitive
	}
	
	private func getPrimitiveDefaultValue(_ type: String) -> PrimitiveTypeDefaultValue {
		let fixedPrimitives: Set<String> = [
			"Int", "Double", "Float", "Decimal", "Bool", "String",
			"CGFloat", "CGSize", "CGRect", "CGPoint",
			"URL", "Data", "Date", "UUID"
		]
		
		if fixedPrimitives.contains(type) {
			return .plain(defaultValue(for: type))
		}
		
		let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
		let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
		
		let bracketRegex = try! NSRegularExpression(pattern: #"^\[.*\]$"#)
		let genericRegex = try! NSRegularExpression(pattern: #"^(Array|Set)<.+>$"#)
		let dictGenericRegex = try! NSRegularExpression(pattern: #"^Dictionary<.+,.+>$"#)
		
		if bracketRegex.firstMatch(in: trimmed, range: range) != nil {
			let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
			if isTopLevelDictionary(inner) {
				return .dictionary(ExprSyntax("[:]")) // dictionary
			} else {
				return .array(ExprSyntax("[]"))      // array
			}
		}
		
		if genericRegex.firstMatch(in: trimmed, range: range) != nil {
			if trimmed.hasPrefix("Set<") {
				return .set(ExprSyntax("[]"))
			} else {
				return .array(ExprSyntax("[]"))
			}
		}
		
		if dictGenericRegex.firstMatch(in: trimmed, range: range) != nil {
			return .dictionary(ExprSyntax("[:]"))
		}
		
		return .notPrimitive
	}
	
	private func isTypePrimitive(_ type: PrimitiveTypeDefaultValue) -> Bool {
		switch type {
		case .notPrimitive: return false
		default: return true
		}
	}
	
	// Helper function
	private func isTopLevelDictionary(_ s: String) -> Bool {
		var level = 0
		for char in s {
			if char == "[" { level += 1 }
			if char == "]" { level -= 1 }
			if char == ":" && level == 0 {
				return true
			}
		}
		return false
	}
}
