//
//  ClearDocAvailability.swift
//  ClearDoc
//
//  Created by Christian Grise on 7/25/26.
//

import Foundation
import FoundationModels

// MARK: - Purpose
// Exposes whether Foundation Models is actually usable right now (device
// eligibility, Apple Intelligence enabled, model downloaded, etc.) so a
// consuming app can decide whether to show a "clarify"-style action at
// all rather than showing it and failing on tap.

/// A source of `SystemLanguageModel.Availability`, abstracted behind a
/// protocol so tests can inject a fake result instead of depending on the
/// real device actually being in each state.
///
/// `SystemLanguageModel` conforms via the extension below, and is what
/// ``ClearDocAvailability/current(provider:)`` reads from by default.
public protocol LanguageModelAvailabilityProviding {

    /// The current availability of the underlying language model.
    var availability: SystemLanguageModel.Availability { get }
}

extension SystemLanguageModel: LanguageModelAvailabilityProviding {}

/// Whether Foundation Models is usable right now on this device, mapped
/// to a human-readable reason when it isn't.
///
/// Check this before calling ``ClearDocAnalyzer/analyze(_:)`` so a
/// consuming app can show a fallback UI rather than let a call fail.
public enum ClearDocAvailability {

    /// The on-device model is ready to use.
    case available

    /// The on-device model can't be used right now.
    ///
    /// - Parameter reason: A human-readable explanation suitable for
    ///   showing directly to a user, already tailored to the specific
    ///   cause (ineligible device, Apple Intelligence disabled, or the
    ///   model still downloading).
    case unavailable(reason: String)

    /// Checks the current availability of the on-device language model.
    ///
    /// - Parameter provider: What to read availability from. Defaults to
    ///   the real system model; tests can pass a fake conforming to
    ///   ``LanguageModelAvailabilityProviding`` to exercise every branch
    ///   deterministically, without needing the real device to actually
    ///   be in each state.
    /// - Returns: The current availability, with a human-readable reason
    ///   attached if unavailable.
    public static func current(provider: LanguageModelAvailabilityProviding = SystemLanguageModel.default) -> ClearDocAvailability {
        switch provider.availability {
        case .available:
            return .available
            
        case .unavailable(.deviceNotEligible):
            return .unavailable(reason: "This device doesn't support on-device clarification. Apple Intelligence features require a compatible device.")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(reason: "Apple Intelligence is not enabled. Please enable it in Settings to use on-device clarification.")
            
        case .unavailable(.modelNotReady):
            return .unavailable(reason: "The on-device model is downloading or not ready. Please try again later.")
            
        case .unavailable(let other):
            return .unavailable(reason: "On-device clarification is currently unavailable: \(other)")
        }
    }
}
