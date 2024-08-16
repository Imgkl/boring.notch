    //
    //  ClipboardView.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import Foundation
import SwiftUI


struct ClipboardItemUI: View {
    let content: String
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick){
            Text(content)
                .frame(width: (NSScreen.main?.frame.size.width ?? 1800) / 6)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black.opacity(0.08))
                        .strokeBorder(Color(nsColor: .textColor).opacity(0.08))
                )
        }.buttonStyle(PlainButtonStyle())
    }
}

struct ClipboardView: View {
    var clipboardManager: ClipboardManager
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                
                Spacer()
                
                Group {
                    Button {self.clipboardManager.clearHistory()} label: {
                        Label("Clear all", systemImage: "trash")
                            .padding(.horizontal, 8)
                    }
                    SettingsLink(label: {
                        Label("Settings", systemImage: "gear")
                            .padding(.horizontal, 8)
                    })
                }
                .controlSize(.extraLarge)
                .buttonStyle(AccessoryBarButtonStyle())
            }
            .padding()
            Group {
                if self.clipboardManager.clipboardItems.count == 0 {
                    ContentUnavailableView("Clipboard history is empty",
                                           systemImage: "clipboard",
                                           description: Text("Keep using the app and your copied content will be shown here"))
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            ForEach(0..<self.clipboardManager.clipboardItems.count, id: \.self) { index in
                                ClipboardItemUI(content: self.clipboardManager.clipboardItems[index], onClick: {
                                    clipboardManager.copyItem(self.clipboardManager.clipboardItems[index])
                                })
                                .padding(.leading, index == 0 ? nil : 0)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom)
            Divider()
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

struct ClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardView(clipboardManager:ClipboardManager(vm:.init())).frame(width: 140, height: 60).padding()
    }
}
