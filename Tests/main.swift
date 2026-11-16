import Foundation

var failures = 0

func expect(_ condition: Bool, _ description: String) {
    guard !condition else { return }
    print("FAIL: \(description)")
    failures += 1
}

expect(Updater.isNewer("1.10", than: "1.9"), "1.10 is newer than 1.9")
expect(Updater.isNewer("1.1", than: "1.0.2"), "1.1 is newer than 1.0.2")
expect(Updater.isNewer("1.0.2", than: "1.0"), "1.0.2 is newer than 1.0")
expect(!Updater.isNewer("1.1", than: "1.1"), "1.1 is not newer than itself")
expect(!Updater.isNewer("1.0.2", than: "1.1"), "1.0.2 is not newer than 1.1")
expect(Updater.version(fromTag: "v1.1") == "1.1", "v1.1 is version 1.1")
expect(Updater.version(fromTag: "1.1") == "1.1", "1.1 is version 1.1")

print(failures == 0 ? "All updater tests passed" : "\(failures) updater test(s) failed")
exit(failures == 0 ? 0 : 1)
