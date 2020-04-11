import Foundation

extension String {
    var hex: Data? {
        var value = self
        var data = Data()

        while value.count > 0 {
            let subIndex = value.index(value.startIndex, offsetBy: 2)
            let c = String(value[..<subIndex])
            value = String(value[subIndex...])

            var char: UInt8
            if #available(iOS 13.0, *) {
                guard let int = Scanner(string: c).scanInt32(representation: .hexadecimal) else { return nil }
                char = UInt8(int)
            } else {
                var int: UInt32 = 0
                Scanner(string: c).scanHexInt32(&int)
                char = UInt8(int)
            }
            data.append(&char, count: 1)
        }

        return data
    }
}
