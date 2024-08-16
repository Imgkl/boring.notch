import CoreAudio
import Foundation

class VolumeChangeListener: ObservableObject {
    
    private var vm: BoringViewModel
    private var gVolumeEvents = false
    private var gAudioID: AudioObjectID = 0
    
    @Published var gLastVolume: Float = 0.4
    @Published var gVolumeChanging = false {
        didSet {
            vm.toggleSneakPeak(status: gVolumeChanging, type: .volume, value: CGFloat(gLastVolume))
        }
    }
    
    init(vm: BoringViewModel) {
        self.vm = vm
        self.gLastVolume = getInitialVolume()
        startListening()
    }
    
    func getInitialVolume() -> Float {
        var id: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &kHardwareDevicePropertyAddress, 0, nil, &size, &id)
        
        var volume: Float = 0
        var mutedMain: UInt32 = 0
        var mutedLeft: UInt32 = 0
        
        AudioObjectGetPropertyData(id, &kMuteMainPropertyAddress, 0, nil, &size, &mutedMain)
        AudioObjectGetPropertyData(id, &kMuteLeftPropertyAddress, 0, nil, &size, &mutedLeft)
        
        size = UInt32(MemoryLayout<Float>.size)
        var volumeMain: Float = 0
        var volumeLeft: Float = 0
        
        AudioObjectGetPropertyData(id, &kVolumeMainPropertyAddress, 0, nil, &size, &volumeMain)
        AudioObjectGetPropertyData(id, &kVolumeLeftPropertyAddress, 0, nil, &size, &volumeLeft)
        
        if volumeLeft > 0 {
            volume = (mutedLeft != 0 || mutedMain != 0) ? 0 : volumeLeft
        } else {
            volume = mutedMain != 0 ? 0 : volumeMain
        }
        
        return volume
    }
    
    private var kHardwareDevicePropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    private var kVolumeMainPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    
    private var kVolumeLeftPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: 1
    )
    
    private var kMuteMainPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    
    private var kMuteLeftPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: 1
    )
    
    func startListening() {
        print("Starting to listen")
        
        guard !gVolumeEvents else { return }
        gVolumeEvents = true
        
        var id: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &kHardwareDevicePropertyAddress, 0, nil, &size, &id)
        
        gAudioID = id
        addListeners(for: id)
        
        let status = AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &kHardwareDevicePropertyAddress,
            { (inObjectID, inNumberAddresses, inAddresses, inClientData) -> OSStatus in
                let listener = Unmanaged<VolumeChangeListener>.fromOpaque(inClientData!).takeUnretainedValue()
                return listener.deviceChanged(id: inObjectID, addressCount: inNumberAddresses, addresses: inAddresses)
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        if status != noErr {
            print("Error setting up device change listener: \(status)")
        }
    }
    
    private func handleVolumeChange(id: AudioObjectID, addressCount: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>?) -> OSStatus {
        var volume: Float = 0
        var mutedMain: UInt32 = 0
        var mutedLeft: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(id, &kMuteMainPropertyAddress, 0, nil, &size, &mutedMain)
        AudioObjectGetPropertyData(id, &kMuteLeftPropertyAddress, 0, nil, &size, &mutedLeft)
        
        size = UInt32(MemoryLayout<Float>.size)
        var volumeMain: Float = 0
        var volumeLeft: Float = 0
        
        AudioObjectGetPropertyData(id, &kVolumeMainPropertyAddress, 0, nil, &size, &volumeMain)
        AudioObjectGetPropertyData(id, &kVolumeLeftPropertyAddress, 0, nil, &size, &volumeLeft)
        
        if volumeLeft > 0 {
            volume = (mutedLeft != 0 || mutedMain != 0) ? 0 : volumeLeft
        } else {
            volume = mutedMain != 0 ? 0 : volumeMain
        }
        
        if abs(volume - gLastVolume) > 1e-2 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.gLastVolume = volume
                self.gVolumeChanging = true
                if volume == 1.0 {
                    self.gVolumeChanging = false
                }
            }
        }
        
        return noErr
    }
    
    
    private func deviceChanged(id: AudioObjectID, addressCount: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>?) -> OSStatus {
        var newID: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &kHardwareDevicePropertyAddress, 0, nil, &size, &newID)
        
        if gAudioID != 0 {
            removeListeners(for: gAudioID)
        }
        
        gAudioID = newID
        addListeners(for: newID)
        
        gLastVolume = -1.0
        
        let status = handleVolumeChange(id: gAudioID, addressCount: addressCount, addresses: addresses)
        
        print("Device changed")
        
        return status
    }
    
    private func addListeners(for id: AudioObjectID) {
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: AudioObjectPropertyListenerProc = { (inObjectID, inNumberAddresses, inAddresses, inClientData) -> OSStatus in
            let listener = Unmanaged<VolumeChangeListener>.fromOpaque(inClientData!).takeUnretainedValue()
            return listener.handleVolumeChange(id: inObjectID, addressCount: inNumberAddresses, addresses: inAddresses)
        }
        
        AudioObjectAddPropertyListener(id, &kMuteMainPropertyAddress, callback, context)
        AudioObjectAddPropertyListener(id, &kMuteLeftPropertyAddress, callback, context)
        AudioObjectAddPropertyListener(id, &kVolumeMainPropertyAddress, callback, context)
        AudioObjectAddPropertyListener(id, &kVolumeLeftPropertyAddress, callback, context)
    }
    
    private func removeListeners(for id: AudioObjectID) {
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: AudioObjectPropertyListenerProc = { (inObjectID, inNumberAddresses, inAddresses, inClientData) -> OSStatus in
            let listener = Unmanaged<VolumeChangeListener>.fromOpaque(inClientData!).takeUnretainedValue()
            return listener.handleVolumeChange(id: inObjectID, addressCount: inNumberAddresses, addresses: inAddresses)
        }
        
        AudioObjectRemovePropertyListener(id, &kMuteMainPropertyAddress, callback, context)
        AudioObjectRemovePropertyListener(id, &kMuteLeftPropertyAddress, callback, context)
        AudioObjectRemovePropertyListener(id, &kVolumeMainPropertyAddress, callback, context)
        AudioObjectRemovePropertyListener(id, &kVolumeLeftPropertyAddress, callback, context)
    }
    
    func setVolume(_ newVolume: Float) {
        guard newVolume >= 0 && newVolume <= 1 else {
            print("Volume must be between 0 and 1")
            return
        }
        
        var id: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &kHardwareDevicePropertyAddress, 0, nil, &size, &id)
        
        size = UInt32(MemoryLayout<Float>.size)
        var volumeToSet = newVolume
        
        let statusMain = AudioObjectSetPropertyData(id, &kVolumeMainPropertyAddress, 0, nil, size, &volumeToSet)
        let statusLeft = AudioObjectSetPropertyData(id, &kVolumeLeftPropertyAddress, 0, nil, size, &volumeToSet)
        
        if statusMain != noErr || statusLeft != noErr {
            print("Error setting volume: Main status: \(statusMain), Left status: \(statusLeft)")
        } else {
                // Unmute the device if it was muted
            var unmute: UInt32 = 0
            size = UInt32(MemoryLayout<UInt32>.size)
            AudioObjectSetPropertyData(id, &kMuteMainPropertyAddress, 0, nil, size, &unmute)
            AudioObjectSetPropertyData(id, &kMuteLeftPropertyAddress, 0, nil, size, &unmute)
            
            DispatchQueue.main.async {
                self.gLastVolume = newVolume
                self.gVolumeChanging = true
                if newVolume == 1.0 {
                    self.gVolumeChanging = false
                }
            }
        }
    }
}
