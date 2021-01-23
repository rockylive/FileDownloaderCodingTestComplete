//
//  Downloader.swift
//  FileDownloaderTest
//
//  Created by Sanggeon Park on 13.06.19.
//  Copyright © 2019 Sanggeon Park. All rights reserved.
//

import Foundation
import UIKit

public protocol DownloaderDelegate: class {
    func didUpdateDownloadStatus(for identifier: String, progress: Float, status: DownloadStatus, error: Error?)
}

extension DownloaderDelegate {
    func didUpdateDownloadStatus(for identifier: String, progress: Float, status: DownloadStatus, error: Error?) {
        // Optional Function
    }
}

#warning("DO NOT USER ANY STATIC VARIABLES AND FUNCTIONS")
open class Downloader: NSObject {

    weak var delegate: DownloaderDelegate?
    
    private var operations: [String: Download]
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    private let kOperations = "kDownloadOperations"
    
    //MARK: - Initilizer
    
    public init(with delegate: DownloaderDelegate? = nil) {
        let encodedData = UserDefaults.standard.object(forKey: kOperations) as? Data
        if let data = encodedData, let operations = try? JSONDecoder().decode([String: Download].self, from: data) {
            self.operations = operations
        } else {
            operations = [String: Download]()
        }
    }

    public func allDownloads(_ completion: @escaping ([DownloadModel]?) -> Void) {
        guard operations.count > 0 else {
            completion(nil)
            return
        }
        let downloads = operations.values.map { $0.downloadModel }
        DispatchQueue.main.async {
            completion(downloads)
        }
    }

    public func resumeDownload(for identifier: String, remotePath: String, _ completion: @escaping (_ data: DownloadModel?, _ error: Error?) -> Void) {
        guard let url = URL(string: remotePath) else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "DOWNLOADER", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL failed"]))
            }
            return
        }
        let download = Download(session: session, identifier: identifier, url: url)
        download.resume()
        saveDownload(download)
        DispatchQueue.main.async {
            completion(download.downloadModel, nil)
        }
    }

    public func pauseDownload(for identifier: String, _ completion: @escaping (_ data: DownloadModel?, _ error: Error?) -> Void) {
        guard let download = operations.values.first(where:{ $0.identifier == identifier}) else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "DOWNLOADER", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download not found"]))
            }
            return
        }
        download.pause { [weak self] in
            self?.saveDownload(download)
            DispatchQueue.main.async {
                completion(download.downloadModel, nil)
            }
        }
    }

    public func removeDownload(for identifier: String, _ completion: @escaping (_ error: Error?) -> Void) {
        guard let download = operations[identifier], download.remove()  else {
            DispatchQueue.main.async {
                completion(NSError(domain: "DOWNLOADER", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download remove failed"]))
            }
            return
        }
        removeDownload(download)
        DispatchQueue.main.async {
            completion(nil)
        }
    }

    public func downloadData(for identifier: String, _ completion: @escaping (_ data: DownloadModel?) -> Void) {
        guard let downlaod = operations[identifier], downlaod.statusModel.status == .DOWNLOADED else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        DispatchQueue.main.async {
            completion(downlaod.downloadModel)
        }
    }
    
    private func removeDownload(_ download: Download) {
        operations.removeValue(forKey: download.identifier)
        let encodedData = try? JSONEncoder().encode(operations)
        UserDefaults.standard.set(encodedData, forKey: kOperations)
    }
    
    private func saveDownload(_ download: Download) {
        operations[download.identifier] = download
        let encodedData = try? JSONEncoder().encode(operations)
        UserDefaults.standard.set(encodedData, forKey: kOperations)
    }
    
}

// MARK: - URLSessionDownloadDelegate

extension Downloader: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let operation = operations.values.first(where:{ $0.task?.taskIdentifier == downloadTask.taskIdentifier }) else {
            assert(false, "operation not found")
            return
        }
        operation.download(session, downloadTask: downloadTask, didFinishDownloadingTo: location) { download in
            let statusModel = operation.statusModel
            saveDownload(operation)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateDownloadStatus(for: statusModel.identifier, progress: statusModel.progress, status: statusModel.status, error: statusModel.error)
            }
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let operation = operations.values.first(where:{ $0.task?.taskIdentifier == downloadTask.taskIdentifier }) else {
            assert(false, "operation not found")
            return
        }
        operation.download(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        saveDownload(operation)
        let statusModel = operation.statusModel
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didUpdateDownloadStatus(for: statusModel.identifier, progress: statusModel.progress, status: statusModel.status, error: statusModel.error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let operation = operations.values.first(where:{ $0.task?.taskIdentifier == task.taskIdentifier }) else {
            return
        }
        operation.download(session, task: task, didCompleteWithError: error)
        saveDownload(operation)
        let statusModel = operation.statusModel
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didUpdateDownloadStatus(for: statusModel.identifier, progress: statusModel.progress, status: statusModel.status, error: statusModel.error)
        }
    }
    
}
