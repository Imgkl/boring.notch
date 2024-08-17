//
//  ClipboardView.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 16/08/24.
//

import Foundation
import SwiftUI


private var appIcons: AppIcons = AppIcons()

struct CopiedItemView: View {
    let item: ClipboardItemStruct
    var body: some View {
        VStack {
            if item.isImage() {
                Image(nsImage: item.getImage()!)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(item.getAttributedString()?.string ?? "")
            }
        }
        
    }
}

struct ClipboardItemUI: View {
    @State private var hovered: Bool = false
    @State private var clicked: Bool = false
    let item: ClipboardItemStruct
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            ZStack(alignment: .bottomLeading) {
                CopiedItemView(item: item)
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
                    Image(nsImage: appIcons.getIcon(bundleID: item.sourceAppBundle!) ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
    @StateObject var clipboardManager: ClipboardManager
    @EnvironmentObject var vm: BoringViewModel
    @State private var showAlert: Bool = false
    @State var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ExpandingSearch(isExpanded: $isExpanded, text: $clipboardManager.searchQuery)
                
                Spacer()
                
                Group {
                    Button {
                        showAlert = true
                    } label: {
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
                if self.clipboardManager.searchResults.count == 0 {
                    ContentUnavailableView("Clipboard history is empty",
                                           systemImage: "clipboard",
                                           description: Text("Keep using the app and your copied content will be shown here"))
                } else {
                    ScrollViewReader { reader in
                        ScrollView(.horizontal, showsIndicators: !vm.clipboardHistoryHideScrollbar) {
                            LazyHStack(spacing: 20) {
                                ForEach(0..<self.clipboardManager.searchResults.count, id: \.self) { index in
                                    ClipboardItemUI(
                                        item: self.clipboardManager.searchResults[index],
                                        onClick: {
                                            self.clipboardManager.copyItem(self.clipboardManager.searchResults[index])
                                        }
                                    )
                                    .padding(.leading, index == 0 ? nil : 0)
                                    .padding(.trailing, (index == self.self.clipboardManager.searchResults.count - 1) ? nil : 0)
                                }
                            }
                            .padding(.bottom)
                        }
                        .onChange(of: self.vm.showCHPanel) { _, _ in
                            if !vm.clipboardHistoryPreserveScrollPosition {
                                reader.scrollTo(0)
                            }
                            isExpanded = false
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .alert("Are you sure you want to clear your clipboard history?", isPresented: self.$showAlert) {
            Button("Delete", role: .destructive) {
                self.clipboardManager.clearHistory()
            }
        } message: {
            Text("This action cannot be undone")
                .foregroundStyle(.secondary)
        }.onAppear(perform: {
            clipboardManager.captureClipboardText()
        }).onDisappear(perform: {
            clipboardManager.searchQuery = ""
        })
    }
}

struct ExpandingSearch: View {
    @Binding var isExpanded: Bool
    @State private var hovered: Bool = false
    @Binding var text: String
    @FocusState var inputFocus
    var body: some View {
        HStack {
            if isExpanded {
                TextField("Search", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(maxWidth: 200)
                    .focused($inputFocus)
            } else {
                Text("Search")
                    .opacity(0.7)
            }
            Image(systemName: "magnifyingglass")
                .opacity(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textColor).opacity((isExpanded || hovered) ? 0.1 : 0))
        )
        .onTapGesture {
            withAnimation(.smooth) {
                isExpanded = true
                inputFocus = true
            }
        }
        .onContinuousHover { phase in
            switch phase {
                case .active:
                    withAnimation(.smooth) {
                        hovered = true
                    }
                case .ended:
                    withAnimation(.smooth) {
                        hovered = false
                    }
            }
        }
        .onExitCommand(perform: {
            withAnimation(.smooth) {
                isExpanded = false
            }
        })
    }
}

#Preview {
    ClipboardView(clipboardManager: ClipboardManager(vm: BoringViewModel())).frame(width: .infinity, height: 300).padding().environmentObject(BoringViewModel())
}
