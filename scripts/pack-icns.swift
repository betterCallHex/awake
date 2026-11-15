import Foundation

let iconset = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
let types = [
    ("icp4", "16x16"), ("ic11", "16x16@2x"), ("icp5", "32x32"), ("ic12", "32x32@2x"),
    ("ic07", "128x128"), ("ic13", "128x128@2x"), ("ic08", "256x256"), ("ic14", "256x256@2x"),
    ("ic09", "512x512"), ("ic10", "512x512@2x"),
]

func bigEndian(_ value: Int) -> Data { withUnsafeBytes(of: UInt32(value).bigEndian) { Data($0) } }

var body = Data()
for (type, name) in types {
    let png = try! Data(contentsOf: URL(fileURLWithPath: "\(iconset)/icon_\(name).png"))
    body += Data(type.utf8) + bigEndian(png.count + 8) + png
}
try! (Data("icns".utf8) + bigEndian(body.count + 8) + body).write(to: URL(fileURLWithPath: output))
