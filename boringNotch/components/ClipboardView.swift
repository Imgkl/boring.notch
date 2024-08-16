    //
    //  ClipboardView.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 16/08/24.
    //

import Foundation
import SwiftUI

struct ClipboardItem: Identifiable {
    var id = UUID()
    var text: String
}

struct ClipboardItemView: View {
    var item: ClipboardItem
    @State var showCopyButton: Bool = false
    
    var body: some View {
        Button(action:{}){
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(red: 36/255, green: 36/255, blue: 36/255), lineWidth: 0.5)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 20/255, green: 20/255, blue: 20/255))
                    )
                    .frame(height: 16)
                HStack{
                    Text(item.text).font(.system(size: 6, weight: .regular)).lineLimit(1).padding(.leading, 5)
                    Spacer()
                    if showCopyButton {
                        Button(action: {}){
                            Image(systemName: "doc.on.doc").font(.system(size: 6, weight: .bold))
                        }.buttonStyle(PlainButtonStyle()).padding(.trailing, 5)
                    }
                }
            }
        }.buttonStyle(PlainButtonStyle()).onHover(perform: { hovering in
            if hovering {
                self.showCopyButton = true
            } else {
                self.showCopyButton = false
            }
        })
    }
}

struct ClipboardView: View {
    var clipboardManager: ClipboardManager
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Clipboard history")
                    .font(.system(size: 8, weight: .regular))
                Spacer()
                Button(action: {}){
                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
                }.buttonStyle(PlainButtonStyle())
            }
            ScrollView(.vertical) {
                LazyVStack(spacing: 2) {
                    ForEach(0..<clipboardManager.clipboardItems.count, id: \.self) {item in
                        ClipboardItemView(item: ClipboardItem(text: clipboardManager.clipboardItems[
                            item
                        ]))
                    }
                }
            }
        }.onAppear() {
            clipboardManager.captureClipboardText()
        }
    }
}

struct ClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardView(clipboardManager:ClipboardManager(vm:.init())).frame(width: 140, height: 60).padding()
    }
}
