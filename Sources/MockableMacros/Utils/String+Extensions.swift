//
//  String+Extensions.swift
//  Mockable
//
//  Created by Felipe Ricieri on 09/10/2025.
//

import Foundation

extension String {
	
	func erasePreffix(_ occurrence: String) -> Self {
		hasPrefix(occurrence) ? replacingOccurrences(of: occurrence, with: "") : self
	}
	
	func eraseSuffix(_ occurrence: String) -> Self {
		hasSuffix(occurrence) ? replacingOccurrences(of: occurrence, with: "") : self
	}
	
	func capitalisingFirstLetter() -> String {
		guard let first = first else { return self }
		return first.uppercased() + dropFirst()
	}
}
