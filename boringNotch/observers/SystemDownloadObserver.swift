import SwiftUI
import Foundation

struct DownloadFile: Identifiable {
    let id: UUID
    let url: URL
    var progress: Double = 0.0
    var totalSize: Int64 = 0
    var progressPercentage: Double = 0.0
}


class DownloadWatcher: ObservableObject {
    @Published var downloadFiles: [DownloadFile] = []
    private var watcher: DispatchSourceFileSystemObject?
    private let folderURL: URL
    private var timer: Timer?
    
    
    init(folderPath: URL?) {
        let folders:[String] = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let defaultPath = URL(fileURLWithPath: folders.first!).resolvingSymlinksInPath()
        
        self.folderURL = defaultPath
        startWatching()
    }
    
    private func startProgressTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        if !downloadFiles.isEmpty {
            
            for (index, file) in downloadFiles.enumerated() {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.url.path)
                    var fileSize = file.totalSize
                    var bytesDownloaded = attributes[.size] as? Int64 ?? 0
                    
                    
                    
                    //                    if fileSize == 0 {
                    //
                    //                        let pList:URL = NSURL(fileURLWithPath: "~/Library/Safari/Downloads.plist").filePathURL!
                    //
                    //                        let filePermissionManager = FilePermissionManager(filePath: pList)
                    //
                    //                        filePermissionManager.requestPermission { granted in
                    //                            if granted {
                    //                                do {
                    //                                    let download = try SafariDownloadModel(url:pList, noObservation: true)
                    //                                    fileSize = Int64(download.bytesTotal)
                    //                                    bytesDownloaded = Int64(download.bytesDownloaded)
                    //                                } catch {
                    //                                    print("Error decoding plist: \(error)")
                    //                                    fileSize = 0
                    //                                }
                    //                            }
                    //                        }
                    //
                    //                    }
                    
                    if fileSize == 0 {
                        continue
                    }
                    
                    let progress = calculateProgress(bytesDownloaded: bytesDownloaded, totalSize: fileSize)
                    
                    if progress == 1.0 || progress.isNaN || progress.isInfinite {
                        removeFileFromDownloads(file: file)
                    }
                    
                    self.downloadFiles[index].progress = progress
                    
                } catch {
                    removeFileFromDownloads(file: file)
                    print("Error getting file attributes: \(error)")
                }
            }
        } else {
            timer?.invalidate()
        }
    }
    
    
    private func removeFileFromDownloads(file: DownloadFile) {
        downloadFiles = downloadFiles.filter { $0.url != file.url }
    }
    
    private func startWatching() {
        let folderDescriptor = open(folderURL.path, O_EVTONLY)
        watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: folderDescriptor, eventMask: .write, queue: .main)
        watcher?.setEventHandler { [weak self] in
            self?.checkForNewDownloads()
        }
        
        watcher?.resume()
    }
    
    func getContentsOfFolder(folderURL: URL, types:[String]) -> [URL]? {
        do {
            let fileManager = FileManager.default
            let folderContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]).filter { $0.lastPathComponent.contains("crdownload") }
            return folderContents
        } catch {
            NSLog("Error: %@","\(error)")
            return nil
        }
    }
    
    func calculateProgress(bytesDownloaded: Int64, totalSize: Int64) -> Double {
        guard totalSize > 0 else { return 0.0 }
        let progress = (Double(bytesDownloaded) / Double(totalSize)) * 100
        return progress
    }
    
    private func checkForNewDownloads() {
        let contents:[URL]? = getContentsOfFolder(folderURL: folderURL, types: ["crdownload", "download"])
        
        if let contents = contents {
            for file in contents {
                let totalSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                let newFile = DownloadFile(id: UUID(), url: file, totalSize: Int64(totalSize))
                print("New file: \(newFile)")
                DispatchQueue.main.async {
                    if !self.downloadFiles.contains(where: { $0.url == newFile.url }) {
                        self.downloadFiles.append(newFile)
                        if self.timer == nil {
                            self.startProgressTimer()
                        }
                    }
                }
            }
        }
        
    }
}

struct DownloadArea: View {
    @StateObject private var watcher: DownloadWatcher
    
    init() {
        _watcher = StateObject(wrappedValue: DownloadWatcher(folderPath: nil))
    }
    
    var body: some View {
        VStack {
            
            ForEach(watcher.downloadFiles) { file in
                HStack {
                    Text(file.url.lastPathComponent)
                    Spacer()
                    Text("\(file.progress)")
                }
            }
        }
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview{
    DownloadArea()
}
