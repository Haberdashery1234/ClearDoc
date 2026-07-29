//
//  ClearDocAnalyzingTests.swift
//  ClearDocTests
//
//  Created by Christian Grise on 7/29/26.
//

import XCTest
@testable import ClearDoc

/// Confirms the ``ClearDocAnalyzing`` seam is actually usable the way it's
/// meant to be: a consuming app substituting a fake for `ClearDocAnalyzer`
/// in its own tests, without invoking the real on-device model.
final class ClearDocAnalyzingTests: XCTestCase {

    private actor FakeAnalyzer: ClearDocAnalyzing {
        private let cannedSummary: ClearDocSummary
        private(set) var resetCallCount = 0

        init(cannedSummary: ClearDocSummary) {
            self.cannedSummary = cannedSummary
        }

        func analyze(_ text: String) async throws -> ClearDocSummary {
            cannedSummary
        }

        func analyzeStream(_ text: String) throws -> AsyncThrowingStream<ClearDocSummary.PartiallyGenerated, Error> {
            AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }

        func reset() async {
            resetCallCount += 1
        }
    }

    private func makeSummary() -> ClearDocSummary {
        ClearDocSummary(
            title: "Test Title",
            plainLanguageSummary: "Test summary.",
            keyPoints: ["One", "Two", "Three"],
            flaggedTerms: [],
            category: .general
        )
    }

    func testFakeAnalyzerCanStandInForAnalyze() async throws {
        let fake = FakeAnalyzer(cannedSummary: makeSummary())
        let dependency: any ClearDocAnalyzing = fake

        let summary = try await dependency.analyze("anything")

        XCTAssertEqual(summary.title, "Test Title")
    }

    func testFakeAnalyzerTracksResetCalls() async {
        let fake = FakeAnalyzer(cannedSummary: makeSummary())
        let dependency: any ClearDocAnalyzing = fake

        await dependency.reset()
        await dependency.reset()

        let count = await fake.resetCallCount
        XCTAssertEqual(count, 2)
    }
}
