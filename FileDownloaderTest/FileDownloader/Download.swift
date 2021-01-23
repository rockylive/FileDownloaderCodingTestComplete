//
//  Download.swift
//  FileDownloaderTest
//
//  Created by Rakitha Perera on 21.01.21.
//  Copyright © 2021 Sanggeon Park. All rights reserved.
//

import Foundation

protocol DownloadProtocol {
    
    func download(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL, completion: (_ download: Download) -> ())
    func download(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func download(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    
}

class Download: Codable {
    
    //MARK: - Public
    var task: URLSessionDownloadTask?
    var identifier: String
    var downloadModel: DownloadModel {
        return DownloadModel(identifier: identifier, status: status, progress: progress, remoteFilePath: remoteFilePath, localFilePath: fileManager.localFileURL(for: localFilePath)?.path)
    }
    var statusModel: DownloadStatusUpdateModel {
        return DownloadStatusUpdateModel(identifier: identifier, status: status, progress: progress, error: error)
    }
    
    //MARK: - Private
    private var error: Error?
    private var status: DownloadStatus = .NONE
    private var progress: Float = 0.0
    private var localFilePath: String?
    private var remoteFilePath: String
    
    private let userDefaults = UserDefaults.standard
    private let fileManager: FileManagerProtocol = DownloadFileManager()
    private lazy var kResumeData: String = {
        return "CacheResumeData-\(identifier)"
    }()
    
    private enum CodingKeys: String, CodingKey {
        case identifier
        case status
        case progress
        case localFilePath
        case remoteFilePath
    }
    
    init(session: URLSession, identifier: String, url: URL) {
        self.identifier = identifier
        remoteFilePath = url.absoluteString
        if let resumeData = userDefaults.value(forKey: kResumeData) as? Data {
            task = session.downloadTask(withResumeData: resumeData)
            userDefaults.removeObject(forKey: kResumeData)
        } else {
            task = session.downloadTask(with: url)
        }
        status = .WAITING
    }

}

//MARK: - Public Methods

extension Download {
    
    /// Resume download
    func resume() {
        task?.resume()
        status = .DOWNLOADING
    }
    
    /// Pause download
    func pause(_ completion: @escaping () -> ()) {
        status = .PAUSED
        task?.cancel { [weak self] resumeData in
            if let key = self?.kResumeData, let resumeData = resumeData {
                self?.userDefaults.set(resumeData, forKey: key)
            }
            completion()
        }
    }
    
    /// Remove download
    func remove() -> Bool {
        switch status {
        case .DOWNLOADING, .WAITING, .NONE:
            task?.cancel()
        case .PAUSED:
            userDefaults.removeObject(forKey: kResumeData)
        case .DOWNLOADED:
            guard let path = localFilePath, fileManager.removeFile(atPath: path) else {
                return false
            }
        }
        status = .NONE
        return true
    }
    
}

//MARK: - DownloadProtocol

extension Download: DownloadProtocol {
    
    func download(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL, completion: (Download) -> ()) {
        let fileName = identifier + (downloadTask.response?.suggestedFilename ?? ".mp4")
        fileManager.moveFile(location: location, toPath: fileName ) { fileUrl, error in
            localFilePath = fileUrl
            completion(self)
        }
    }
    
    func download(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percent = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        progress = percent * 100
    }
    
    func download(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            status = .DOWNLOADED
            return
        }
        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            status = .PAUSED
            userDefaults.set(resumeData, forKey: kResumeData)
        } else {
            status = .WAITING
            self.error = error
        }
    }
    
}
