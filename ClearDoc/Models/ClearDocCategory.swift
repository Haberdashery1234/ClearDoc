//
//  ClearDocCategory.swift
//  ClearDoc
//
//  Created by Christian Grise on 7/25/26.
//

import Foundation
import FoundationModels

/// A coarse classification assigned to a piece of text as part of
/// ``ClearDocSummary``.
///
/// ``ClearDocAnalyzer`` asks the on-device model to choose one of these
/// cases based on the content it's given. The case list is deliberately
/// short — Guided Generation classification tends to work better with a
/// small, well-separated set of options than a large, fine-grained
/// taxonomy — and deliberately generic, since ``ClearDoc`` itself has no
/// knowledge of any one consuming app's domain.
@Generable
public enum ClearDocCategory: String, Codable, CaseIterable {

    /// Text that doesn't clearly fit either of the other two categories —
    /// for example business, legal, or otherwise non-medical content.
    case general

    /// A casual, first-person note someone wrote about their own health —
    /// the kind of free-text entry a symptom-tracking app would collect,
    /// as opposed to a clinical document authored by a provider.
    case personalHealthNote

    /// Clinical or provider-authored medical content, such as text that
    /// reads like a clinical assessment or diagnostic note.
    ///
    /// - Note: Text in this category is more likely to trip Apple's
    ///   on-device safety guardrail (`LanguageModelSession.GenerationError.refusal`)
    ///   if it reads like actual diagnostic reasoning — this was observed
    ///   directly while testing ``ClearDocAnalyzer``, not merely assumed.
    case medical
}
