    //
    //  ClipboardManager.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import Foundation
import AppKit
import Combine
import KeyboardShortcuts

struct ClipboardItemStruct {
    let content: Data
    let type: NSPasteboard.PasteboardType
    let sourceAppBundle: String?
    let date: Date
    
    func getAttributedString() -> NSAttributedString? {
        if type == .rtf {
            return NSAttributedString(rtf: content, documentAttributes: nil)
        } else if type == .html {
            return try? NSAttributedString(data: content, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        } else if type == .string {
            return NSAttributedString(string: String(data: content, encoding: .utf8) ?? "")
        } else if type == .fileURL {
            return NSAttributedString(string: String(data: content, encoding: .utf8) ?? "")
        }
        return nil
    }
    
    func getImage() -> NSImage? {
        if type == .tiff {
            return NSImage(data: content)
        } else if type == .png {
            return NSImage(data: content)
        }
        return NSImage()
    }
    
    func isImage() -> Bool {
        return type == .tiff || type == .png
    }
    
    func isText() -> Bool {
        return type == .string || type == .html || type == .rtf || type == .fileURL
    }
}

class ClipboardManager : ObservableObject {
    
    private var vm: BoringViewModel?
    var clipboardItems: [ClipboardItemStruct] = [] {
        didSet {
            if self.searchQuery.isEmpty {
                self.searchResults = clipboardItems
            }
        }
    }
    let maxRecords: Int
    private let plistFileName = "ClipboardManager.plist"
    private var changeCount = 0
    private var clipboard = NSPasteboard.general
    private var eventMonitor: Any?
    @Published var searchResults: [ClipboardItemStruct] = []
    @Published var searchQuery: String = "" // Search query
    private var cancellables = Set<AnyCancellable>()
    
    
    private let supportedTypes: Set<NSPasteboard.PasteboardType> = [
        .fileURL,
        .html,
        .png,
        .rtf,
        .string,
        .tiff
    ]
    
    private var ignoredPasteBoardTypes: [NSPasteboard.PasteboardType] = [
        "de.petermaurer.TransientPasteboardType",
        "com.typeit4me.clipping",
        "Pasteboard generator type",
        "com.agilebits.onepassword",
        "net.antelle.keeweb"
    ].map({NSPasteboard.PasteboardType($0)})
    
    private var sourceApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
    
    
    init(vm: BoringViewModel) {
        self.vm = vm
        self.maxRecords = vm.maxClipboardRecords
        loadClipboardItems()
        startMonitoring()
        
            // Listen to searchQuery changes and debounce
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fuzzySearch(query)
            }
            .store(in: &cancellables)
    }
    
    func clearHistory() {
        clipboardItems.removeAll()
        saveClipboardItems()
    }
    
    func copyItem(_ item: String) {
        clipboard.clearContents()
        clipboard.setString(item, forType: .string)
    }
    
    func fuzzySearch(_ query: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var results: [ClipboardItemStruct]
            
            if query.isEmpty {
                results = self.clipboardItems
            } else {
                results = self.clipboardItems.filter { item in
                    let content = item.getAttributedString()?.string ?? ""
                    return content.range(of: query, options: .caseInsensitive) != nil
                }
            }
            
            DispatchQueue.main.async {
                self.searchResults = results
            }
        }
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
    
    func alreadyExists(_ item: Data) -> Bool {
        return clipboardItems.contains { $0.content == item }
    }
    
        // Method to add a new item to the clipboard history
    func addClipboardItem(_ item: NSPasteboardItem) {
            // Check if the item already exists
        
        let itemType = item.availableType(from: item.types) ?? .string
        
        var itemData: Data = item.data(forType: itemType) ?? Data()
        
        let sourceAppBundle = sourceApp?.bundleIdentifier?.lowercased()
        
        if !alreadyExists(itemData) {
            clipboardItems.insert(ClipboardItemStruct(content: itemData, type: itemType, sourceAppBundle: sourceAppBundle, date: Date()), at: 0)
            
                // Trim the list if it exceeds the max number of records
            if clipboardItems.count > maxRecords {
                clipboardItems.removeLast()
            }
            
            saveClipboardItems()
        }
    }
    
        // Method to get all clipboard items
    func getClipboardItems() -> [ClipboardItemStruct] {
        return clipboardItems
    }
    
        // Method to capture text from the clipboard and add to history
    func captureClipboardText() {
        DispatchQueue.main.async {
            if self.clipboard.changeCount != self.changeCount {
                for item in self.clipboard.pasteboardItems ?? [] {
                    let sourceAppBundle = self.sourceApp?.bundleIdentifier
                    
                        // ignore if the source app is the same as the current app
                    
                    if sourceAppBundle == Bundle.main.bundleIdentifier {
                        return;
                    }
                    
                        // Reading types on NSPasteboard gives all the available
                        // types - even the ones that are not present on the NSPasteboardItem.
                        // See https://github.com/p0deje/Maccy/issues/241.
                    if self.shouldIgnore(Set(self.clipboard.types ?? [])) {
                        return
                    }
                    
                    let types = Set(item.types)
                    if types.contains(.string) && self.isEmptyString(item) && !self.richText(item) {
                        return
                    }
                    
                    self.addClipboardItem(item)
                }
                
                self.changeCount = self.clipboard.changeCount
            }
        }
    }
    
    
    private func isEmptyString(_ item: NSPasteboardItem) -> Bool {
        guard let string = item.string(forType: .string) else {
            return true
        }
        
        return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func richText(_ item: NSPasteboardItem) -> Bool {
        if let rtf = item.data(forType: .rtf) {
            if let attributedString = NSAttributedString(rtf: rtf, documentAttributes: nil) {
                return !attributedString.string.isEmpty
            }
        }
        
        if let html = item.data(forType: .html) {
            if let attributedString = NSAttributedString(html: html, documentAttributes: nil) {
                return !attributedString.string.isEmpty
            }
        }
        
        return false
    }
    
    private func shouldIgnore(_ types: Set<NSPasteboard.PasteboardType>) -> Bool {
        let ignoredTypes = self.ignoredPasteBoardTypes
        
        return types.isDisjoint(with: supportedTypes) ||
        !types.isDisjoint(with: ignoredTypes)
    }
    
    private func expiryDate(_ date: Date) -> Date {
        return date.addingTimeInterval(TimeInterval(60 * 60 * 24 * vm!.clipBoardHistoryDuration)) //
    }
    
        // Save clipboard items to .plist file
    
    private func saveClipboardItems() {
        let plistPath = getPlistPath()
        let plistArray = clipboardItems.map(
            
            { item in
                return [
                    "content": item.content,
                    "type": item.type.rawValue,
                    "sourceAppBundle": item.sourceAppBundle ?? "",
                    "date": item.date,
                    "expiry": expiryDate(item.date)
                ]
            }
        ) as NSArray
        plistArray.write(toFile: plistPath, atomically: true)
    }
    
        // Load clipboard items from .plist file
    func loadClipboardItems() {
        let plistPath = getPlistPath()
        if let plistArray = NSArray(contentsOfFile: plistPath) as? [[String: Any]] {
            clipboardItems = plistArray.map({
                return ClipboardItemStruct(
                    content: $0["content"] as! Data,
                    type: NSPasteboard.PasteboardType($0["type"] as! String),
                    sourceAppBundle: $0["sourceAppBundle"] as? String,
                    date: $0["date"] as! Date
                )
            })
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
    
    func copyItem(_ item: ClipboardItemStruct) {
        clipboard.clearContents()
        if item.isText() {
            clipboard.setString(item.getAttributedString()?.string ?? "", forType: .string)
        } else if item.isImage() {
            clipboard.setData(item.content, forType: item.type)
        }
    }
}
