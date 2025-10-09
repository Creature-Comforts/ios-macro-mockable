//
//  MockableMacroPlugin.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct MockablePlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		MockableMacro.self,
	]
}
