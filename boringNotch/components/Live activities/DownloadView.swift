    //
    //  DownloadView.swift
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 17/08/24.
    //

import Foundation
import SwiftUI

private var appIcons: AppIcons = AppIcons()


struct DownloadArea: View {
    @EnvironmentObject var watcher: DownloadWatcher

    var body: some View {
        HStack{
            HStack{
                Image(nsImage: appIcons.getIcon(bundleID: "org.yanex.marta")!)
                VStack (alignment: .leading){
                    Text("Download")
                    Text("In progress").font(.system(.footnote)).foregroundStyle(.gray)
                }
            }
            Spacer()
            HStack (spacing: 12){
                VStack (alignment: .trailing){
                    Text("12%")
                    Text("Filename.mp4").font(.caption2).foregroundStyle(.gray)
                }
                ProgressIndicator(type: .circle, progress: 0.12, color: .accentColor)
            }
        }
    }
}

#Preview{
    DownloadArea().environmentObject(DownloadWatcher(folderPath:  nil, vm: BoringViewModel())).padding()
}
