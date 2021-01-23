//
//  AppResetHelper.swift
//  FileDownloaderTest
//
//  Created by Rakitha Perera on 22.01.21.
//  Copyright © 2021 Sanggeon Park. All rights reserved.
//

import Foundation

class AppResetHelper {
    
    func resetAppData() {
        clearUserDefaults()
        clearAllFile()
    }
    
    private func clearUserDefaults() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return
        }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }
    
    private func clearAllFile() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "mp4" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  {
            print(error)
        }
    }
    
}


