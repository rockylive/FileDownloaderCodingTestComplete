//
//  ViewModel.swift
//  FileDownloaderTest
//
//  Created by Sanggeon Park on 13.06.19.
//  Copyright © 2019 Sanggeon Park. All rights reserved.
//

import Foundation

class DownloadViewModel {
    let identifier: String
    let remoteFilePath: String
    var downloadStatus: DownloadStatus = .NONE
    var progress: Float = 0

    init(with id: String, remotePath: String) {
        identifier = id
        remoteFilePath = remotePath
    }
}
