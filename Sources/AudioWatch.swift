import CoreAudio

final class AudioWatch {
    var onChange: () -> Void = {}
    private(set) var isPlaying = false
    private var device = AudioObjectID(kAudioObjectUnknown)
    private lazy var defaultDeviceChanged: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.followDefaultDevice() }
    private lazy var runningChanged: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.refresh() }

    func start() {
        var address = Self.address(kAudioHardwarePropertyDefaultOutputDevice)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, defaultDeviceChanged)
        followDefaultDevice()
    }

    func stop() {
        var address = Self.address(kAudioHardwarePropertyDefaultOutputDevice)
        AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, defaultDeviceChanged)
        stopListeningToDevice()
        isPlaying = false
    }

    private func followDefaultDevice() {
        stopListeningToDevice()
        var address = Self.address(kAudioHardwarePropertyDefaultOutputDevice)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        var running = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        AudioObjectAddPropertyListenerBlock(device, &running, .main, runningChanged)
        refresh()
    }

    private func stopListeningToDevice() {
        guard device != kAudioObjectUnknown else { return }
        var running = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        AudioObjectRemovePropertyListenerBlock(device, &running, .main, runningChanged)
        device = AudioObjectID(kAudioObjectUnknown)
    }

    private func refresh() {
        var address = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &running)
        let playing = status == noErr && running != 0
        guard playing != isPlaying else { return }
        isPlaying = playing
        onChange()
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    }
}
