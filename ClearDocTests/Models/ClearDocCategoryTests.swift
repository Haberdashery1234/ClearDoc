//
//  ClearDocCategoryTests.swift
//  ClearDocTests
//
//  Created by Christian Grise on 7/26/26.
//

import XCTest
@testable import ClearDoc

final class ClearDocCategoryTests: XCTestCase {

    func testHasExpectedCases() {
        XCTAssertEqual(ClearDocCategory.allCases.count, 3)
        XCTAssertTrue(ClearDocCategory.allCases.contains(.general))
        XCTAssertTrue(ClearDocCategory.allCases.contains(.personalHealthNote))
        XCTAssertTrue(ClearDocCategory.allCases.contains(.medical))
    }
}
