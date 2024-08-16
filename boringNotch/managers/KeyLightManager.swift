    //
    //  KeyLightManager.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 11/08/24.
    //

import Foundation
import IOKit


class KeyLightManager: ObservableObject {
    var service: io_service_t = IO_OBJECT_NULL
    
    @Published var current_brightness: Int32 = 255 {
        didSet {
            print("current_brightness updated to: \(current_brightness)")
            current_brightness_progress = Float(current_brightness) / 255
        }
    }
    @Published var current_brightness_progress: Float = 0.0 {
        didSet {
            print("current_brightness_progress updated to: \(current_brightness_progress)")
        }
    }
    
    init() {
        registerService()
        if (self.keyboardHasBacklight()){
//            KeyboardManager.configure()
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
//        let currentBrightness = BrightnessControl.getBrightness()
//        let statusBrightness = currentBrightness > 0.1 ? currentBrightness : self.current_brightness_progress
//        return Double(statusBrightness)
        return 0
    }
    
    func setKeyboardBacklight(brightness: Float) {
//        BrightnessControl.setBrightness(brightness)
        self.current_brightness_progress = brightness
    }
}
