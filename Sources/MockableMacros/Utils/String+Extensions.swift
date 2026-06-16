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

	/// Replaces whole-token occurrences of `token` with `replacement`.
	///
	/// Unlike `replacingOccurrences(of:with:)`, this only matches `token` when it
	/// is not part of a larger identifier, so a typealias named `Item` is not
	/// corrupted inside `PKPaymentSummaryItem`. A token preceded by a `.` (member
	/// access, e.g. `Foo.Item`) is also left untouched, since it refers to a
	/// qualified member rather than the bare typealias.
	func replacingToken(_ token: String, with replacement: String) -> String {
		guard !token.isEmpty else { return self }
		let escaped = NSRegularExpression.escapedPattern(for: token)
		let pattern = "(?<![A-Za-z0-9_.])\(escaped)(?![A-Za-z0-9_])"
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
		let range = NSRange(startIndex..<endIndex, in: self)
		let template = NSRegularExpression.escapedTemplate(for: replacement)
		return regex.stringByReplacingMatches(in: self, range: range, withTemplate: template)
	}
}
