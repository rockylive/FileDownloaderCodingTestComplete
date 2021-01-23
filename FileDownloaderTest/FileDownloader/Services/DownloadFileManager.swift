//
//  DownloadFileManager.swift
//  FileDownloaderTest
//
//  Created by Rakitha Perera on 19.01.21.
//  Copyright © 2021 Sanggeon Park. All rights reserved.
//

import Foundation

protocol FileManagerProtocol {
    
    func moveFile(location: URL, toPath: String, completion: (_ filePath: String?, _ error: Error?) -> ())
    func removeFile(atPath: String) -> Bool
    func localFileURL(for filePath: String?) -> URL?
    
}

class DownloadFileManager: FileManagerProtocol {
    
    private let manager = FileManager.default
    
    func moveFile(location: URL, toPath: String, completion: (_ filePath: String?, _ error: Error?) -> ()) {
        guard let destinationUrl = localFileURL(for: toPath) else {
            assert(false, "Can not generate url")
            return
        }
        do {
            if manager.fileExists(atPath:  destinationUrl.path) {
                try manager.removeItem(at: destinationUrl)
            }
            try manager.moveItem(at: location, to: destinationUrl)
            completion(toPath, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    func removeFile(atPath: String) -> Bool {
        guard let destinationUrl = localFileURL(for: atPath) else {
            return false
        }
        do {
            if manager.fileExists(atPath:  destinationUrl.path) {
                try manager.removeItem(at: destinationUrl)
            }
            return true
        } catch {
            return false
        }
    }
    
    func localFileURL(for filePath: String?) -> URL? {
        guard let filePath = filePath, let documentPath = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentPath.appendingPathComponent(filePath)
    }
    
}
