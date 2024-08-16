//
//  FloatingPanel.swift
//  boringNotch
//
//  Created by Richard Kunkli on 16/08/2024.
//

import SwiftUI

import SwiftUI

class FloatingPanel<Content: View>: NSPanel {
    @Binding var isPresented: Bool
    
    init(view: () -> Content,
         contentRect: NSRect,
         backing: NSWindow.BackingStoreType = .buffered,
         defer flag: Bool = false,
         isPresented: Binding<Bool>) {
        
        self._isPresented = isPresented
        
        super.init(contentRect: contentRect,
                   styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless, .utilityWindow],
                   backing: backing,
                   defer: flag)
        
        /// Allow the panel to be on top of other windows
        isFloatingPanel = true
        level = .mainMenu + 2
        /// Remove the border and shadow
        hasShadow = false
        
        /// Allow the panel to be overlaid in a fullscreen space
        collectionBehavior = [.stationary, .canJoinAllSpaces, .fullScreenAuxiliary]
        
        /// Don't show a window title, even if it's set
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        
        /// Hide all traffic light buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        /// Sets animations
        animationBehavior = .alertPanel
        
        isMovableByWindowBackground = false
        
        /// Set the content view
        /// The safe area is ignored because the title bar still interferes with the geometry
        contentView = NSHostingView(rootView: view()
            .ignoresSafeArea()
            .environment(\.floatingPanel, self))
        
        contentView?.needsDisplay = true
        contentView?.wantsLayer = true
        
    }
    
    /// Close automatically when out of focus
    override func resignMain() {
        self.close()
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.close()
    }
    
    @objc func updatePanelVisibility() {
        if isPresented {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
    
    override func orderFrontRegardless() {
        super.orderFrontRegardless()
        makeKeyAndOrderFront(nil)
    }
    
    /// Close and toggle presentation, so that it matches the current state of the panel
    override func close() {
        DispatchQueue.main.async {
            let screenRect = NSScreen.main!.visibleFrame
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                self.animator().setFrame(NSRect(x: 0, y: NSScreen.main!.frame.height, width: screenRect.size.width, height: (self.frame.height)), display: true, animate: true)
            }, completionHandler: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            super.close()
            self.isPresented = false
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
}

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
    var floatingPanel: NSPanel? {
        get { self[FloatingPanelKey.self] }
        set { self[FloatingPanelKey.self] = newValue }
    }
}

