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
	case `public`
	case `internal`
	case `private`
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
		return try protocolComposer.compose(node)
	}
}
