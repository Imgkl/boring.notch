//
//  ClipboardView.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 16/08/24.
//

import Foundation
import SwiftUI


struct ClipboardItemUI: View {
    @State private var hovered: Bool = false
    @State private var clicked: Bool = false
    let content: String
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            ZStack(alignment: .bottomLeading) {
                Text(content)
                    .blur(radius: !clicked ? 0 : 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hovered ? .white.opacity(0.08) : .black.opacity(0.08))
                            .strokeBorder(Color(nsColor: .textColor).opacity(0.08))
                    )
                    .onTapGesture {
                        withAnimation {
                            clicked = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                clicked = false
                            }
                        }
                    }
                    .overlay {
                        if clicked {
                            VStack(spacing: 15) {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .font(.system(size: 24))
                                    .symbolRenderingMode(.hierarchical)
                                Text("Copied to clipboard")
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
                    .onContinuousHover { phase in
                        switch phase {
                            case .active:
                                withAnimation(.smooth(duration: 0.4)) {
                                    hovered = true
                                }
                            case .ended:
                                withAnimation(.smooth(duration: 0.4)) {
                                    hovered = false
                                }
                        }
                    }
                    .padding([.leading, .bottom], 7)
                
                if hovered {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.gray)
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .transition(.scale.combined(with: .blurReplace))
                }
            }
            .frame(width: (NSScreen.main?.frame.size.width ?? 1800) / 6)
        }
        .buttonStyle(PlainButtonStyle())
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
                                .padding(.trailing, (index == self.clipboardManager.clipboardItems.count - 1) ? nil : 0)
                            }
                        }
                        .padding(.bottom)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
