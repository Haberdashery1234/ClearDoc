//
//  ClearDocAnalyzer.swift
//  ClearDoc
//
//  Created by Christian Grise on 7/25/26.
//

import Foundation
import FoundationModels

/// Turns raw text into a structured, plain-language ``ClearDocSummary``
/// using Apple's on-device Foundation Models framework.
///
/// This is ``ClearDoc``'s main entry point. Create one, optionally
/// supplying tailored `instructions` for your app's use case, then call
/// ``analyze(_:)`` with the text you want broken down. Everything runs
/// on-device — no network call is made.
///
/// An analyzer can be used either way, depending on what fits your app:
/// - **Fresh per call** — construct a new `ClearDocAnalyzer` each time you
///   need to analyze something. Simple, and guarantees each analysis is
///   isolated from every other, at the cost of never benefiting from
///   ``FoundationModels/LanguageModelSession/prewarm()``.
/// - **Shared, long-lived** — hold on to one instance (for example as
///   `@State` in a SwiftUI view) and reuse it across multiple calls to
///   ``analyze(_:)``, calling ``reset()`` between unrelated documents so
///   earlier content doesn't influence later analyses or fill up the
///   context window. This lets prewarming actually pay off, since it only
///   helps when it happens ahead of when a result is needed.
public final class ClearDocAnalyzer {
    /// Stored so ``reset()`` can rebuild the session with the same
    /// instructions this analyzer was created with, without the caller
    /// needing to remember or re-supply them.
    private let instructions: String
    private var session: LanguageModelSession

    private static let defaultInstructions = "help reorganize what someone wrote, don't sound diagnostic"

    /// Rough, character-based heuristic for a safe input size — NOT an
    /// exact token count. The on-device context window is ~4K tokens
    /// shared between prompt and response, and token-to-character ratio
    /// varies by content, so this is a conservative guess (~3 chars/token)
    /// meant to fail fast with a clear `ClearDocError` before hitting the
    /// model's own `exceededContextWindowSize`. Adjust if it proves too
    /// strict or too loose in practice.
    private static let maxInputLength = 12_000

    /// Errors ``ClearDocAnalyzer`` itself raises, before or instead of
    /// letting a raw `FoundationModels` error surface.
    ///
    /// Errors that originate from the model itself — for example a safety
    /// guardrail refusal — are **not** wrapped in this type. Those
    /// propagate as `LanguageModelSession.GenerationError` directly, so
    /// callers can branch on Apple's own documented cases. This type only
    /// covers pre-flight validation this analyzer performs itself, plus a
    /// catch-all for truly unexpected failures.
    public enum ClearDocError: Error {

        /// The text passed to ``analyze(_:)`` was empty, or contained
        /// only whitespace.
        case emptyInput

        /// The text passed to ``analyze(_:)`` exceeded this analyzer's
        /// length heuristic, meant to fail fast before the model's own
        /// context-window limit would be hit.
        case inputTooLong

        /// `analyze(_:)` failed for a reason other than input validation
        /// or a documented `LanguageModelSession.GenerationError`.
        ///
        /// - Parameter underlying: The original error, preserved so it can
        ///   actually be inspected — losing this detail is exactly what
        ///   made an earlier version of this case hard to debug.
        case generationFailed(underlying: Error)
    }

    /// Creates a new analyzer with its own on-device session.
    ///
    /// - Parameter instructions: System instructions that frame the
    ///   model's role and tone for every call to ``analyze(_:)`` made with
    ///   this instance — this is how a consuming app tunes ClearDoc for
    ///   its own use case (for example, framing results as "reorganize
    ///   what someone wrote" rather than anything diagnostic). Pass `nil`
    ///   to use a sensible generic default.
    public init(instructions: String? = nil) {
        self.instructions = instructions ?? Self.defaultInstructions
        self.session = LanguageModelSession(instructions: self.instructions)
        session.prewarm()
    }

    /// Resets this analyzer's session to a clean slate, discarding any
    /// conversation transcript accumulated from prior ``analyze(_:)``
    /// calls.
    ///
    /// There's no "reset" API on `LanguageModelSession` itself — the only
    /// documented way to get a blank transcript is a new session instance.
    /// This method does exactly that under the hood (same instructions,
    /// re-prewarmed) so callers holding a long-lived, shared
    /// ``ClearDocAnalyzer`` don't need to know that detail themselves.
    ///
    /// Call this between unrelated documents if you're reusing one
    /// analyzer across the app, to avoid two problems: earlier documents'
    /// content influencing later analyses, and the on-device context
    /// window (small — ~4K tokens shared between prompt and response)
    /// filling up with accumulated history from calls that have nothing
    /// to do with each other.
    public func reset() {
        session = LanguageModelSession(instructions: instructions)
        session.prewarm()
    }

    /// Analyzes a block of text and returns a structured, plain-language
    /// breakdown of it.
    ///
    /// Input is validated before anything is sent to the model: empty or
    /// whitespace-only text throws ``ClearDocError/emptyInput``, and text
    /// longer than this analyzer's length heuristic throws
    /// ``ClearDocError/inputTooLong``. Beyond that, this method runs
    /// entirely on-device via Guided Generation — nothing is sent over
    /// the network, and the returned ``ClearDocSummary`` is constrained
    /// to match its declared schema.
    ///
    /// - Parameter text: The raw text to analyze — for example a personal
    ///   note, a short document, or any other free-form string.
    /// - Returns: A ``ClearDocSummary`` describing the input text.
    /// - Throws: ``ClearDocError/emptyInput`` or ``ClearDocError/inputTooLong``
    ///   if validation fails before the model is called;
    ///   `LanguageModelSession.GenerationError` (unwrapped, as thrown by
    ///   Foundation Models itself) if the model refuses the input, exceeds
    ///   its context window, or otherwise fails to generate a response;
    ///   or ``ClearDocError/generationFailed`` for any other unexpected
    ///   failure.
    public func analyze(_ text: String) async throws -> ClearDocSummary {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw ClearDocError.emptyInput
        }
        guard trimmed.count <= Self.maxInputLength else {
            throw ClearDocError.inputTooLong
        }

        do {
            let response = try await session.respond(to: text, generating: ClearDocSummary.self)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            // Let FoundationModels' own error type propagate as-is rather
            // than wrapping it — it's already meaningful (refusal, exceeded
            // context window, etc.) and callers may want to branch on the
            // specific case, same as we did while diagnosing the guardrail
            // refusal earlier in this project.
            throw error
        } catch {
            throw ClearDocError.generationFailed(underlying: error)
        }
    }
}

extension ClearDocAnalyzer.ClearDocError: Equatable {
    /// Compares cases by identity only — `.generationFailed`'s underlying
    /// error isn't compared, since `Error` itself isn't `Equatable`. This
    /// is enough for tests that just need to confirm *which* case was
    /// thrown, not the wrapped error's exact value.
    public static func == (lhs: ClearDocAnalyzer.ClearDocError, rhs: ClearDocAnalyzer.ClearDocError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyInput, .emptyInput):
            return true
        case (.inputTooLong, .inputTooLong):
            return true
        case (.generationFailed, .generationFailed):
            return true
        default:
            return false
        }
    }
}
