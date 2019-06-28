import XCTest
@testable import LibPQ

final class LibPQTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LibPQ().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
