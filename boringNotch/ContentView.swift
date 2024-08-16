import SwiftUI
import AVFoundation
import Combine
import KeyboardShortcuts

struct ContentView: View {
    let onHover: () -> Void
    @EnvironmentObject var vm: BoringViewModel
    @StateObject var batteryModel: BatteryStatusViewModel
    var body: some View {
        BoringNotch(vm: vm, batteryModel: batteryModel, onHover: onHover)
            .frame(maxWidth: .infinity, maxHeight: Sizes().size.opened.height! + 20, alignment: .top)
            .edgesIgnoringSafeArea(.top)
            .transition(.slide.animation(vm.animation))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    withAnimation(vm.animation){
                        if vm.firstLaunch {
                            vm.open()
                        }
                    }
                })
            })
            .animation(.smooth().delay(0.3), value: vm.firstLaunch)
            .contextMenu {
                SettingsLink(label: {
                    Text("Settings")
                })
                .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                Button("Edit") {
                    let dn = DynamicNotch(content: EditPanelView())
                    dn.toggle()
                }
                #if DEBUG
                .disabled(false)
                #else
                .disabled(true)
                #endif
                .keyboardShortcut("E", modifiers: .command)
            }
            .floatingPanel(isPresented: $vm.showCHPanel) {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        
                        Spacer()
                        
                        Group {
                            Button { } label: {
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
                        if false { // TODO: change true to history.empty
                            ContentUnavailableView("Clipboard history is empty",
                                                   systemImage: "clipboard",
                                                   description: Text("Keep using the app and your copied content will be shown here"))
                        } else {
                            ScrollView(.horizontal) {
                                HStack(spacing: 20) {
                                    ForEach(["a", "b"].indices, id: \.self) { index in
                                        ClipboardItem(content: "test")
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
}

struct ClipboardItem: View {
    let content: String
    var body: some View {
        Text(content)
            .frame(width: (NSScreen.main?.frame.size.width ?? 1800) / 6)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black.opacity(0.08))
                    .strokeBorder(Color(nsColor: .textColor).opacity(0.08))
            )
    }
}
