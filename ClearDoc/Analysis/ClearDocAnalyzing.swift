//
//  ClearDocAnalyzing.swift
//  ClearDoc
//
//  Created by Christian Grise on 7/29/26.
//

import Foundation

/// An abstraction over ``ClearDocAnalyzer``'s public API.
///
/// This mirrors the seam ``LanguageModelAvailabilityProviding`` already
/// provides for ``ClearDocAvailability`` — a way for a consuming app to
/// substitute a fake implementation in its own tests, without invoking the
/// real on-device model. A view model that depends on `any ClearDocAnalyzing`
/// instead of the concrete `ClearDocAnalyzer` can be tested with a fake that
/// returns canned ``ClearDocSummary`` values or throws specific errors on
/// demand, the same way ``ClearDocAvailabilityTests`` exercises every
/// availability branch deterministically today.
///
/// `ClearDocAnalyzer` conforms below, so existing call sites that hold a
/// concrete `ClearDocAnalyzer` don't need to change — this protocol is
/// opt-in for code that wants the testability seam.
public protocol ClearDocAnalyzing: Sendable {

    /// See ``ClearDocAnalyzer/analyze(_:)``.
    func analyze(_ text: String) async throws -> ClearDocSummary

    /// See ``ClearDocAnalyzer/analyzeStream(_:)``.
    func analyzeStream(_ text: String) throws -> AsyncThrowingStream<ClearDocSummary.PartiallyGenerated, Error>

    /// See ``ClearDocAnalyzer/reset()``.
    func reset() async
}

extension ClearDocAnalyzer: ClearDocAnalyzing {}
