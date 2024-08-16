//
//  ClipboardHistoryWindow.swift
//  boringNotch
//
//  Created by Richard Kunkli on 16/08/2024.
//

import SwiftUI
import KeyboardShortcuts

fileprivate struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let contentRect: CGRect
    @ViewBuilder let view: () -> PanelContent
    @State private var panel: FloatingPanel<PanelContent>?
    
    init(isPresented: Binding<Bool>, contentRect: CGRect, @ViewBuilder view: @escaping () -> PanelContent) {
        self._isPresented = isPresented
        self.contentRect = contentRect
        self.view = view
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                setupPanel()
            }
            .onDisappear {
                panel?.close()
            }
            .onChange(of: isPresented) { oldValue, newValue in
                print("panel", isPresented)
                if newValue {
                    present()
                } else {
                    panel?.close()
                }
            }
    }
    
    private func setupPanel() {
        guard panel == nil else { return }
        panel = FloatingPanel(view: view, contentRect: NSRect(origin: .zero, size: contentRect.size), isPresented: $isPresented)
        panel?.setFrameTopLeftPoint(NSPoint(x: 0, y: NSScreen.main?.frame.height ?? 0))
        if isPresented {
            present()
        }
    }
    
    private func present() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let panelHeight = panel.frame.height
        let startRect = NSRect(x: 0, y: screenRect.maxY + panelHeight, width: screenRect.width, height: panelHeight)
        let endRect = NSRect(x: 0, y: screen.frame.maxY - panelHeight, width: screenRect.width, height: panelHeight)
        
        panel.setFrame(startRect, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(endRect, display: true)
            panel.animator().alphaValue = 1
        }, completionHandler: nil)
    }
}

extension View {
    func floatingPanel<Content: View>(
        isPresented: Binding<Bool>,
        contentRect: CGRect = CGRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 300, height: 300),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}

