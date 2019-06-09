import XCTest
@testable import BTKit

class RuuviTests: XCTestCase {

    private let scanner = Ruuvi.scanner
    private var tags = Set<RuuviTag>()
    
    func testRuuviTag() {
        let e = expectation(description: "Found 3 tags")
        e.expectedFulfillmentCount = 3
        scanner.observeDevice(self) { (observer, device) in
            if let ruuviTag = device.ruuviTag {
                if !observer.tags.contains(ruuviTag) {
                    e.fulfill()
                    observer.tags.insert(ruuviTag)
                }
            }
        }
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

}
