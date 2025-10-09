//
//  ProtocolDeclSyntax+Extensions.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntax

extension ProtocolDeclSyntax {
	func isSendable() -> Bool {
		inheritanceClause?
			.inheritedTypes
			.contains { $0.type.trimmedDescription == "Sendable" } ?? false
	}
}
