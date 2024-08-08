//
//  Sources:SafariDownload:DownloadPlist.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 08/08/24.
//

import Foundation

struct DownloadPlist: Codable {
    var DownloadEntryProgressBytesSoFar: Int
    var DownloadEntryProgressTotalToLoad: Int
    var DownloadEntryPath: String
    var DownloadEntryDateAddedKey: Date
    var DownloadEntryURL: String
    var DownloadEntryIdentifier: UUID
    var DownloadEntrySandboxIdentifier: UUID
}
