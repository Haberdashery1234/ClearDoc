//
//  ClearDocAnalyzerTests.swift
//  ClearDocTests
//
//  Created by Christian Grise on 7/26/26.
//

import XCTest
import FoundationModels
@testable import ClearDoc

/// Pre-flight validation tests for ``ClearDocAnalyzer``. These never touch
/// the model — they confirm `analyze(_:)` rejects bad input before any
/// generation call is made — so they always run, regardless of whether
/// Apple Intelligence is available on this machine.
final class ClearDocAnalyzerValidationTests: XCTestCase {

    func testEmptyInputThrows() async {
        let analyzer = ClearDocAnalyzer()
        do {
            _ = try await analyzer.analyze("")
            XCTFail("Expected .emptyInput to be thrown")
        } catch let error as ClearDocAnalyzer.ClearDocError {
            XCTAssertEqual(error, .emptyInput)
        } catch {
            XCTFail("Expected ClearDocError.emptyInput, got \(error)")
        }
    }

    func testWhitespaceOnlyInputThrows() async {
        let analyzer = ClearDocAnalyzer()
        do {
            _ = try await analyzer.analyze("   \n\t  ")
            XCTFail("Expected .emptyInput to be thrown")
        } catch let error as ClearDocAnalyzer.ClearDocError {
            XCTAssertEqual(error, .emptyInput)
        } catch {
            XCTFail("Expected ClearDocError.emptyInput, got \(error)")
        }
    }

    func testOversizedInputThrows() async {
        let analyzer = ClearDocAnalyzer()
        let oversized = String(repeating: "a", count: 20_000)
        do {
            _ = try await analyzer.analyze(oversized)
            XCTFail("Expected .inputTooLong to be thrown")
        } catch let error as ClearDocAnalyzer.ClearDocError {
            XCTAssertEqual(error, .inputTooLong)
        } catch {
            XCTFail("Expected ClearDocError.inputTooLong, got \(error)")
        }
    }
}

/// Model-calling tests for ``ClearDocAnalyzer``. Written with XCTest after
/// the same three tests, written with Swift Testing, consistently hit an
/// environment-level `GenerationError -1 / ModelManagerError 1026` failure
/// specifically in this test target — even though identical calls worked
/// reliably through the ClearDocDemo app. Switching to XCTest didn't
/// change that outcome, which points at the test host process itself
/// rather than either testing framework.
///
/// **Currently disabled** (`setUpWithError()` unconditionally skips) —
/// left in place rather than deleted so the test bodies aren't lost if a
/// working way to invoke Foundation Models from this test target turns up
/// later. Model behavior is verified manually via the ClearDocDemo app in
/// the meantime. To re-enable, replace the `XCTSkip` below with the
/// commented-out `XCTSkipUnless(isModelAvailable, ...)` line.
final class ClearDocAnalyzerModelTests: XCTestCase {

    private enum Fixture {
        static let personalHealthNote = "Woke up around 3am with a sharp pain on my right side, kind of under the ribs. Took some ibuprofen around 4. Also been feeling really tired the past few days and my ankles look a little swollen."

        static let clinicalDiagnosticNote = "Patient presents with a 3-day history of intermittent epigastric pain radiating to the back, associated with nausea and one episode of vomiting. Plan: obtain CBC, lipase, and abdominal ultrasound to evaluate for cholelithiasis vs pancreatitis."
    }

    private var isModelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    override func setUpWithError() throws {
        throw XCTSkip("Model-calling tests are disabled for now — see class doc comment.")
        // try XCTSkipUnless(isModelAvailable, "Apple Intelligence isn't available on this machine/simulator.")
    }

    func testAnalyzePersonalNote() async throws {
        let analyzer = ClearDocAnalyzer()
        let summary = try await analyzer.analyze(Fixture.personalHealthNote)

        XCTAssertFalse(summary.title.isEmpty)
        XCTAssertFalse(summary.plainLanguageSummary.isEmpty)
        XCTAssertTrue((3...6).contains(summary.keyPoints.count))
    }

    func testAnalyzeClinicalNoteIsRefused() async throws {
        // Documents real, observed behavior: text written like an actual
        // differential diagnosis ("evaluate for X vs Y") trips Apple's
        // on-device safety guardrail and throws GenerationError.refusal.
        // Not a ClearDoc bug — there's no supported way to disable or
        // loosen the guardrail from app code.
        let analyzer = ClearDocAnalyzer()

        do {
            _ = try await analyzer.analyze(Fixture.clinicalDiagnosticNote)
            XCTFail("Expected clinical/diagnostic text to be refused, but analyze(_:) succeeded.")
        } catch let error as LanguageModelSession.GenerationError {
            if case .refusal = error {
                // Expected.
            } else {
                XCTFail("Expected .refusal, but got a different GenerationError case: \(error)")
            }
        } catch {
            XCTFail("Expected a LanguageModelSession.GenerationError, got \(error)")
        }
    }

    func testResetLeavesAnalyzerUsable() async throws {
        let analyzer = ClearDocAnalyzer()
        _ = try await analyzer.analyze(Fixture.personalHealthNote)

        analyzer.reset()

        // Confirms reset() doesn't leave the analyzer broken — a second,
        // unrelated analysis still succeeds after resetting.
        let summary = try await analyzer.analyze(Fixture.personalHealthNote)
        XCTAssertFalse(summary.title.isEmpty)
    }
}
