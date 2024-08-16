    //
    //  BoringSystemTiles.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import Foundation
import SwiftUI


struct SystemItemButton: View {
    
    @State var icon: String = "gear"
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .frame(width: 22, height: 22)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 20/255, green: 20/255, blue: 20/255))
                )
        }.buttonStyle(PlainButtonStyle())
    }
}

func logout() {
    DispatchQueue.global(qos: .background).async {
        let appleScript = """
        tell application "System Events" to log out
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
}

struct BoringSystemTiles: View {
    var vm: BoringViewModel?
    
    @StateObject var microphoneHandler:MicrophoneHandler
    
    
    struct ItemButton {
        var icon: String
        var onTap: () -> Void
    }
    
    
    var items :[ItemButton]
    
    init(vm: BoringViewModel, items: Array<ItemButton> = [], microphoneHandler: MicrophoneHandler) {
        self.vm = vm
        self.items = [
            ItemButton(icon: "clipboard", onTap: {
                vm.openClipboard()
            }),
            ItemButton(icon: "speaker.wave.2.fill", onTap: {}),
            ItemButton(icon: "mic", onTap: microphoneHandler.toggleMicrophone),
            ItemButton(icon: "sun.max", onTap: {}),
            ItemButton(icon: "keyboard", onTap: {}),
            ItemButton(icon: "lock", onTap: logout),
        ]
        _microphoneHandler = StateObject(wrappedValue: microphoneHandler)
    }
    
    var body: some View {
        GridView(rows: 2, cols: 3) { row, col in
            VStack {
                switch (row, col)
                {
                    case (0, 0):
                        SystemItemButton(icon: items[0].icon, onTap: items[0].onTap)
                    case (0, 1):
                        SystemItemButton(icon: items[1].icon, onTap: items[1].onTap)
                    case (0, 2):
                        SystemItemButton(icon: self.microphoneHandler.currentMicStatus ?  items[2].icon : "mic.slash", onTap: items[2].onTap)
                    case (1, 0):
                        SystemItemButton(icon: items[3].icon, onTap: items[3].onTap)
                    case (1, 1):
                        SystemItemButton(icon: items[4].icon, onTap: items[4].onTap)
                    case (1, 2):
                        SystemItemButton(icon: items[5].icon, onTap: items[5].onTap)
                    case (_, _):
                        EmptyView()
                }
            }
        }
    }
    
}

struct GridView<Content: View>: View {
    let rows: Int
    let cols: Int
    let content: (Int, Int) -> Content
    
    var body: some View {
        Grid {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<cols, id: \.self) { col in
                        content(row, col)
                    }
                }
            }
        }
    }
}



#Preview {
    BoringSystemTiles(vm:BoringViewModel(), microphoneHandler: MicrophoneHandler(vm:.init())).padding()
}
