    //
    //  KeyLightManager.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 11/08/24.
    //

import Foundation
import IOKit
import KeyboardShortcuts

class KeyLightManager: ObservableObject {
    private var vm: BoringViewModel?
    var service: io_service_t = IO_OBJECT_NULL
    private var first_time:Bool = true
    
    @Published var current_brightness: Int32 = 255
    @Published var current_brightness_progress: Float = 0.0 {
        didSet {
            if(!first_time){
                current_brightness = Int32(current_brightness_progress * 255)
                self.vm?.toggleSneakPeak(status: true, type: .backlight, value: CGFloat(self.current_brightness_progress))
                
            }
           }
    }
    
    init(vm: BoringViewModel) {
        self.vm = vm;
        registerService()
        if (self.keyboardHasBacklight()){
            KeyboardManager.configure()
            current_brightness_progress = Float(getBrightness())
            setupListners()
        }
    }
    
    func registerService(){
        let port: mach_port_t
        if #available(macOS 12.0, *) {
            port = kIOMainPortDefault // New name as of macOS 12
        } else {
            port = kIOMasterPortDefault // Old name up to macOS 11
        }
        let service = IOServiceGetMatchingService(port, IOServiceMatching(kIOResourcesClass))
        guard service != IO_OBJECT_NULL else {
                // Could not read IO registry node. You have to decide whether
                // to treat this as a fatal error or not.
            self.service = IO_OBJECT_NULL
            return;
        }
        self.service = service
    }
    
    func setupListners() {
       
        KeyboardShortcuts.onKeyDown(for: .decreaseBacklight) {
            print("Somee  sds")
            self.current_brightness = max(0, self.current_brightness - 32)
            self.setKeyboardBacklight(brightness: Float(self.current_brightness) / 255)
        }
        
        KeyboardShortcuts.onKeyDown(for: .increaseBacklight) {
            print("Im logging it up")
            self.current_brightness = min(255, self.current_brightness + 32)
            self.setKeyboardBacklight(brightness: Float(self.current_brightness) / 255)
        }
    }
    
    func keyboardHasBacklight() -> Bool {
        
        guard let cfProp = IORegistryEntryCreateCFProperty(service, "KeyboardBacklight" as CFString,
                                                           kCFAllocatorDefault, 0)?.takeRetainedValue(),
              let hasBacklight = cfProp as? Bool
        else {
                // "KeyboardBacklight" property not present, or not a boolean.
                // This happens on Macs without keyboard backlight.
            return false
        }
            // Successfully read boolean "KeyboardBacklight" property:
        return hasBacklight
    }
    
    func getBrightness() -> Double {
        let currentBrightness = BrightnessControl.getBrightness()
        let statusBrightness = currentBrightness > 0.1 ? currentBrightness : self.current_brightness_progress
        return Double(statusBrightness)
    }
    
    func setKeyboardBacklight(brightness: Float) {
        self.first_time = false
        BrightnessControl.setBrightness(brightness)
        self.current_brightness_progress = brightness
    }
}
