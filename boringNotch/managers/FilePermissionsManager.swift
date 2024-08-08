import Cocoa

class FilePermissionManager {
    
    var panel: NSPanel!
    var fileURL: URL
    var completionHandler: ((Bool) -> Void)?
    
    init(filePath: URL) {
        self.fileURL = filePath
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        self.completionHandler = completion
        
        // Initialize NSPanel
        panel = NSPanel(contentRect: NSMakeRect(0, 0, 400, 200),
                        styleMask: [.titled, .closable],
                        backing: .buffered,
                        defer: false)
        
        panel.title = "Access Request"
        panel.isFloatingPanel = true
        
        // Add a label
        let label = NSTextField(labelWithString: "This app requires access to \(fileURL.path). Do you allow access?")
        label.frame = NSMakeRect(20, 120, 360, 40)
        panel.contentView?.addSubview(label)
        
        // Add Allow button
        let allowButton = NSButton(title: "Allow", target: self, action: #selector(allowAccess))
        allowButton.frame = NSMakeRect(220, 40, 80, 30)
        panel.contentView?.addSubview(allowButton)
        
        // Add Deny button
        let denyButton = NSButton(title: "Deny", target: self, action: #selector(denyAccess))
        denyButton.frame = NSMakeRect(120, 40, 80, 30)
        panel.contentView?.addSubview(denyButton)
        
        // Show the panel
        if let window = NSApplication.shared.mainWindow {
            window.beginSheet(panel, completionHandler: nil)
        }
    }
    
    @objc func allowAccess() {
        if let window = NSApplication.shared.mainWindow {
            window.endSheet(panel)
        }
        requestFileAccess()
    }
    
    @objc func denyAccess() {
        if let window = NSApplication.shared.mainWindow {
            window.endSheet(panel)
        }
        completionHandler?(false)
    }
    
    func requestFileAccess() {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                do {
                    // Attempt to read the file
                    let _ = try Data(contentsOf: fileURL)
                    print("Access granted to \(fileURL.path)")
                    // Proceed with your logic here
                    completionHandler?(true)
                } catch {
                    print("Failed to access file: \(error.localizedDescription)")
                    completionHandler?(false)
                }
            }
        } else {
            print("File does not exist at \(fileURL.path)")
            completionHandler?(false)
        }
    }
}
