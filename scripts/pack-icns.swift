import Foundation

let directory = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
let types = [
    ("icp4", 16), ("icp5", 32), ("ic12", 64), ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024),
]

func bigEndian(_ value: Int) -> Data { withUnsafeBytes(of: UInt32(value).bigEndian) { Data($0) } }

var body = Data()
for (type, pixels) in types {
    let png = try! Data(contentsOf: URL(fileURLWithPath: "\(directory)/\(pixels).png"))
    body += Data(type.utf8) + bigEndian(png.count + 8) + png
}
try! (Data("icns".utf8) + bigEndian(body.count + 8) + body).write(to: URL(fileURLWithPath: output))
