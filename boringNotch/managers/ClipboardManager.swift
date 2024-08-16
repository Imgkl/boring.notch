    //
    //  ClipboardManager.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import Foundation
import AppKit

class ClipboardManager {
    
    private var vm: BoringViewModel?
    
    var clipboardItems: [String] = []
    let maxRecords: Int
    private let plistFileName = "ClipboardManager.plist"
    private var changeCount = 0
    private var clipboard = NSPasteboard.general
    private var eventMonitor: Any?
    
    
    init(vm: BoringViewModel) {
        self.vm = vm
        self.maxRecords = vm.maxClipboardRecords
        loadClipboardItems()
        startMonitoring()
    }
    
    func clearHistory() {
        clipboardItems.removeAll()
        saveClipboardItems()
    }
    
    func copyItem(_ item: String) {
        clipboard.clearContents()
        clipboard.setString(item, forType: .string)
    }
    
    func startMonitoring() {
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
                self?.captureClipboardText()
            }
        }
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
    
        // Method to add a new item to the clipboard history
    func addClipboardItem(_ item: String) {
            // Check if the item already exists
        if !clipboardItems.contains(item) {
                // Add item to the clipboard items
            clipboardItems.insert(item, at: 0)
            
                // Trim the list if it exceeds the max number of records
            if clipboardItems.count > maxRecords {
                clipboardItems.removeLast()
            }
            
            saveClipboardItems()
        }
    }
    
        // Method to get all clipboard items
    func getClipboardItems() -> [String] {
        return clipboardItems
    }
    
        // Method to capture text from the clipboard and add to history
    func captureClipboardText() {
        print(self.clipboard.changeCount)
        if self.clipboard.changeCount != changeCount {
            for _ in 0..<self.clipboard.changeCount {
                for item in self.clipboard.pasteboardItems ?? [] {
                    if let clipboardString = item.string(forType: .string) {
                        addClipboardItem(clipboardString)
                    }
                }
            }
            
            changeCount = clipboard.changeCount
        }
    }
    
    private func saveClipboardItems() {
        let plistPath = getPlistPath()
        let plistArray = clipboardItems as NSArray
        plistArray.write(toFile: plistPath, atomically: true)
    }
    
        // Load clipboard items from .plist file
    private func loadClipboardItems() {
        let plistPath = getPlistPath()
        if let plistArray = NSArray(contentsOfFile: plistPath) as? [String] {
            clipboardItems = plistArray
        }
    }
    
        // Get the path for the .plist file
    private func getPlistPath() -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if let documentsDirectory = documentsDirectory {
            let plistURL = documentsDirectory.appendingPathComponent(plistFileName)
            print(plistURL.path)
            return plistURL.path
        }
        
        return ""
    }
}
