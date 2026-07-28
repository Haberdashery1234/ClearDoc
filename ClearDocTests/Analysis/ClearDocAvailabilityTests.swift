//
//  ClearDocAvailabilityTests.swift
//  ClearDocTests
//
//  Created by Christian Grise on 7/26/26.
//

import XCTest
import FoundationModels
@testable import ClearDoc

final class ClearDocAvailabilityTests: XCTestCase {

    /// Deterministic stand-in for `SystemLanguageModel` — lets every
    /// branch of `current()`'s mapping logic be exercised without needing
    /// the real device to actually be in each state.
    private struct FakeProvider: LanguageModelAvailabilityProviding {
        let availability: SystemLanguageModel.Availability
    }

    func testMapsAvailable() {
        let result = ClearDocAvailability.current(provider: FakeProvider(availability: .available))
        guard case .available = result else {
            XCTFail("Expected .available, got \(result)")
            return
        }
    }

    func testMapsDeviceNotEligible() {
        let result = ClearDocAvailability.current(provider: FakeProvider(availability: .unavailable(.deviceNotEligible)))
        guard case .unavailable(let reason) = result else {
            XCTFail("Expected .unavailable, got \(result)")
            return
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testMapsAppleIntelligenceNotEnabled() {
        let result = ClearDocAvailability.current(provider: FakeProvider(availability: .unavailable(.appleIntelligenceNotEnabled)))
        guard case .unavailable(let reason) = result else {
            XCTFail("Expected .unavailable, got \(result)")
            return
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testMapsModelNotReady() {
        let result = ClearDocAvailability.current(provider: FakeProvider(availability: .unavailable(.modelNotReady)))
        guard case .unavailable(let reason) = result else {
            XCTFail("Expected .unavailable, got \(result)")
            return
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testCurrentDoesNotCrash() {
        _ = ClearDocAvailability.current()
    }
}
