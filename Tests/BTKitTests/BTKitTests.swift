import XCTest
@testable import BTKit

final class BTKitTests: XCTestCase {
    func testRequestAddress() {
        let address = LedgerServiceType.address
        guard let apdu = address.requestAddress(path: "44'/60'/0'/0/0", verify: false) else { XCTFail(); return }
        let expected: [UInt8] = [5,0,0,0,26,224,2,0,0,21,5,128,0,0,44,128,0,0,60,128,0,0,0,0,0,0,0,0,0,0,0]
        let actual = apdu.map { UInt8($0) }
        XCTAssertEqual(expected, actual)
    }

    func testAddressRequst() {
        let address = LedgerServiceType.address
        let expected: [UInt8] = [224,2,0,0,21,5,128,0,0,44,128,0,0,60,128,0,0,0,0,0,0,0,0,0,0,0]
        guard let apdu = address.addressAPDU(path: "44'/60'/0'/0/0", verify: false) else { XCTFail(); return }
        guard let request = address.addressRequest(verify: false, apdu: apdu) else { XCTFail(); return }
        let actual = request.map { UInt8($0) }
        XCTAssertEqual(expected, actual)
    }

    func testAddressAPDU() {
        let expected: [UInt8] = [5, 128, 0, 0, 44, 128, 0, 0, 60, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        let address = LedgerServiceType.address
        guard let apdu = address.addressAPDU(path: "44'/60'/0'/0/0", verify: false) else { XCTFail(); return }
        let actual = apdu.map { UInt8($0) }
        print(actual.count)
        XCTAssertEqual(expected, actual)
    }

    func testSplitPath() {
        let address = LedgerServiceType.address
        let path = address.splitPath(path: "44'/60'/0'/0/0")
        XCTAssertEqual([2147483692, 2147483708, 2147483648, 0, 0], path)
    }
}
