    //
    //  MicrophoneManager.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import CoreAudio
import Foundation
import Combine
import SwiftUI

var f5Keys: [UInt16] = [
    0xF708,
    0x96,
    0x60
]

class MicrophoneHandler : ObservableObject {
    
    private var vm: BoringViewModel?
    private var hotkeyMonitor: Any?
    
    private var defaultDeviceID: AudioObjectID = kAudioObjectUnknown
    private var firstTime: Bool = true;
    @Published var currentMicStatus: Bool = true {
        didSet {
            if firstTime {return;}
            vm?.toggleSneakPeak(status: true, type: .mic, value: currentMicStatus ? 1 : 0)
        }
    }
    @Published var hotkey: UInt16 = 0xF708 {
        didSet {
            UserDefaults.standard.set(hotkey, forKey: "MicrophoneHotkey")
            setupHotkeyMonitor()
        }
    }
    
    init(vm: BoringViewModel) {
        self.vm = vm
        if UserDefaults.standard.object(forKey: "MicrophoneHotkey") != nil {
            self.hotkey = UInt16(UserDefaults.standard.integer(forKey: "MicrophoneHotkey"))
        }
        self.getDefaultInputDevice()
        self.currentMicStatus = !isMicrophoneMuted()
        setupHotkeyMonitor()
        self.firstTime = false;
    }
    
    func setHotkey(_ newHotkey: UInt16) {
        hotkey = newHotkey
        setupHotkeyMonitor()
    }
    
    private func setupHotkeyMonitor() {
        if let existingMonitor = hotkeyMonitor {
            NSEvent.removeMonitor(existingMonitor)
        }
        
        guard UnicodeScalar(hotkey) != nil else {
            print("Invalid hotkey")
            return
        }
        
        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.function) && f5Keys.contains(UInt16(event.keyCode)) {
                self?.toggleMicrophone()
            }
        }
    }
    
    func toggleMicrophone() {
        
        self.getDefaultInputDevice()
        
        if !self.currentMicStatus {
            unmuteMicrophone()
        } else {
            muteMicrophone()
        }
        DispatchQueue.main.async {
            self.currentMicStatus = !self.isMicrophoneMuted()
        }
    }
    
    private func getDefaultInputDevice() {
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        
        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, 0, nil, &propertySize, &defaultDeviceID)
        if result != noErr || defaultDeviceID == kAudioObjectUnknown {
            print("Error getting default input device")
        }
    }
    
    func muteMicrophone() {
        guard defaultDeviceID != kAudioObjectUnknown else {
            print("No valid input device found")
            return
        }
        
        var mutePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var muteValue: UInt32 = 1
        let setMuteResult = AudioObjectSetPropertyData(defaultDeviceID, &mutePropertyAddress, 0, nil, UInt32(MemoryLayout<UInt32>.size), &muteValue)
        
        if setMuteResult == noErr {
            print("Microphone muted successfully")
            currentMicStatus = false;
        } else {
            print("Error muting microphone: \(setMuteResult)")
        }
    }
    
    func unmuteMicrophone() {
        guard defaultDeviceID != kAudioObjectUnknown else {
            print("No valid input device found")
            return
        }
        
        var mutePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var muteValue: UInt32 = 0
        let setMuteResult = AudioObjectSetPropertyData(defaultDeviceID, &mutePropertyAddress, 0, nil, UInt32(MemoryLayout<UInt32>.size), &muteValue)
        
        if setMuteResult == noErr {
            print("Microphone unmuted successfully")
            currentMicStatus = true;
        } else {
            print("Error unmuting microphone: \(setMuteResult)")
        }
    }
    
    func isMicrophoneMuted() -> Bool {
        guard defaultDeviceID != kAudioObjectUnknown else {
            print("No valid input device found")
            return false
        }
        
        var mutePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var muteValue: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        let getMuteResult = AudioObjectGetPropertyData(defaultDeviceID, &mutePropertyAddress, 0, nil, &propertySize, &muteValue)
        
        if getMuteResult == noErr {
            return muteValue == 1
        } else {
            print("Error checking microphone mute status: \(getMuteResult)")
            return false
        }
    }
}
