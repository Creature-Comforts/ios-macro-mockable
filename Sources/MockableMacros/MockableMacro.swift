//
//  MockableMacro.swift
//  Mockable
//
//  Created by Felipe Ricieri on 27/08/2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum MockableMacroAccessLevel: String {
	case `open`
	case `public`
	case `internal`
	case `private`

	/// Access level for the generated mock's *class declaration*.
	var syntax: String {
		switch self {
		case .internal: ""
		case .open: "open "
		case .public: "public "
		case .private: "private "
		}
	}

	/// Access level for the mock's *members* (init, stored properties, etc.).
	/// `open` is only valid on the class itself and overridable members —
	/// initializers and stored properties can't be `open` — so it is
	/// downgraded to `public`, which is sufficient for cross-module use.
	var memberSyntax: String {
		switch self {
		case .open: "public "
		default: syntax
		}
	}
}

enum MacroError: Error {
	case message(String)
}

// MARK: - Macro

public struct MockableMacro: PeerMacro {
	
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {

		guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
			throw MacroError.message("@Mockable can only be applied to protocols")
		}
		
		let protocolComposer = ProtocolDeclSyntaxComposer(decl: proto)
		return try protocolComposer.compose(node, context)
	}
}
