import Foundation
import Combine
import AppKit

public class SafariDownloadModel: ObservableObject {
    public enum Error: LocalizedError {
        case openFileHandleFailed(URL, code: Int32)
        case noFolderPermission(URL)
    }
    
    @Published public var bytesDownloaded: Int
    @Published public var bytesTotal: Int
    @Published public var deleted = false
    public let fileURL: URL
    public let plistURL: URL
    public let originURL: URL
    public let dateAdded: Date
    
    public let id: UUID
    public let sandboxID: UUID
    private var source: DispatchSourceFileSystemObject!
    private let decoder = PropertyListDecoder()
    
    public init(url: URL, noObservation: Bool = false) throws {
        let plist = try decoder.decode(DownloadPlist.self, from: Data(contentsOf: url))
        self.bytesDownloaded = plist.DownloadEntryProgressBytesSoFar
        self.bytesTotal = plist.DownloadEntryProgressTotalToLoad
        self.fileURL = URL(fileURLWithPath: plist.DownloadEntryPath)
        guard let originURL = URL(string: plist.DownloadEntryURL) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "DownloadEntryURL: Not a valid URL string")
            )
        }
        self.originURL = originURL
        self.dateAdded = plist.DownloadEntryDateAddedKey
        self.id = plist.DownloadEntryIdentifier
        self.sandboxID = plist.DownloadEntrySandboxIdentifier
        
            // Set the plist URL
        self.plistURL = url
        
            // Check for folder permission before proceeding
        try checkFolderPermission(for: plistURL)
        
            // Initialize with actual file size if available
        self.updateFileSize()
        
            // Set up observation unless it's disabled
        if !noObservation {
            try observeFileChanges()
        }
    }
    
    deinit {
        source?.cancel()
    }
    
    private func observeFileChanges() throws {
        let fileDescriptor = open(plistURL.path, O_EVTONLY)
        if fileDescriptor == -1 {
            throw Error.openFileHandleFailed(plistURL, code: Darwin.errno)
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .extend],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let event = source.data
            self.process(event: event)
        }
        source.setCancelHandler {
            close(fileDescriptor)
        }
        source.resume()
        self.source = source
    }
    
    private func process(event: DispatchSource.FileSystemEvent) {
        if event.contains(.delete) {
            deleted = true
            source?.cancel()
            return
        }
        guard event.contains(.write) || event.contains(.extend) else {
            return
        }
        guard let plist = try? decoder.decode(DownloadPlist.self, from: Data(contentsOf: plistURL)) else {
            return
        }
        bytesDownloaded = plist.DownloadEntryProgressBytesSoFar
        bytesTotal = plist.DownloadEntryProgressTotalToLoad
        
            // Update with actual file size
        updateFileSize()
    }
    
    private func updateFileSize() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("Helo", fileSize, fileURL)
            if fileSize > 0 {
                bytesDownloaded = Int(fileSize)
                if bytesTotal == 0 {
                    bytesTotal = bytesDownloaded
                }
            }
        } catch {
            print("Error getting file attributes: \(error)")
        }
    }
    
    private func checkFolderPermission(for url: URL) throws {
        let folderURL = url.deletingLastPathComponent()
        let fileManager = FileManager.default
        if !fileManager.isReadableFile(atPath: folderURL.path) {
            throw Error.noFolderPermission(folderURL)
        }
    }
}
