//
//  ViewController.swift
//  FileDownloaderTest
//
//  Created by Sanggeon Park on 13.06.19.
//  Copyright © 2019 Sanggeon Park. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    let viewModels = [DownloadViewModel(with: "Video 1", remotePath: "http://bit.ly/2WHqcG2"),
                      DownloadViewModel(with: "Video 2", remotePath: "http://bit.ly/2WHqcG2")]
    var downloader = Downloader()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        downloader.delegate = self
        syncDownloads(viewModels: viewModels)
    }
    
    //MARK: - Private
    
    private func syncDownloads(viewModels: [DownloadViewModel]) {
        downloader.allDownloads { [weak self] downloads in
            guard let downloads = downloads, !downloads.isEmpty else {
                return
            }
            for viewModel in viewModels {
                guard let download = downloads.filter({ $0.identifier == viewModel.identifier }).first else {
                    continue
                }
                viewModel.progress = download.progress
                viewModel.downloadStatus = download.status
            }
            self?.tableView.reloadData()
        }
    }
    
    private func showAlert(title: String = NSLocalizedString("Error", comment: ""), message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    private func playDownload(_ download: DownloadModel) {
        guard let path = download.localFilePath else {
            showAlert(message: NSLocalizedString("Downloaded file not found", comment: ""))
            return
        }
        let playerViewController = AVPlayerViewController()
        present(playerViewController, animated: true, completion: nil)
        
        let url = URL(fileURLWithPath: path)
        let player = AVPlayer(url: url)
        playerViewController.player = player
        player.play()
    }
}

//MARK: - DownloaderDelegate

extension ViewController: DownloaderDelegate {
    
    func didUpdateDownloadStatus(for identifier: String, progress: Float, status: DownloadStatus, error: Error?) {
        if let error = error {
            showAlert(message: error.localizedDescription)
        }
        guard let row = viewModels.firstIndex(where: { $0.identifier == identifier }) else {
            return
        }
        let viewModel = viewModels[row]
        viewModel.progress = progress
        viewModel.downloadStatus = status
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
}

//MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =  tableView.dequeueReusableCell(withIdentifier: "DownloadTableViewCell", for: indexPath) as? DownloadTableViewCell else {
            fatalError("Cell not exists in storyboard")
        }
        let model = viewModels[indexPath.row]
        cell.configureCell(viewModel: model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModels[indexPath.row]
        switch model.downloadStatus {
        case .NONE, .PAUSED, .WAITING:
            #warning("RESUME DOWNLOAD")
            downloader.resumeDownload(for: model.identifier, remotePath: model.remoteFilePath) { [weak self] (data, error) in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                }
                guard let downloadModel = data, downloadModel.status == .DOWNLOADING else {
                    return
                }
                model.downloadStatus = downloadModel.status
                model.progress = downloadModel.progress
                tableView.reloadData()
            }
            break
        case .DOWNLOADING:
            #warning("PAUSE DOWNLOAD")
            downloader.pauseDownload(for: model.identifier) { [weak self] (data, error) in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                }
                guard let downloadModel = data, downloadModel.status == .PAUSED else {
                    return
                }
                model.downloadStatus = downloadModel.status
                model.progress = downloadModel.progress
                tableView.reloadData()
            }
            break
        case .DOWNLOADED:
            #warning("PLAY DOWNLOADED VIDEO")
            downloader.downloadData(for: model.identifier) { [weak self] data in
                guard let download = data else {
                    self?.showAlert(message: NSLocalizedString("Download not found", comment: ""))
                    return
                }
                self?.playDownload(download)
            }
            break
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let model = viewModels[indexPath.row]
        if editingStyle == .delete, model.downloadStatus != .NONE {
            #warning("REMOVE ONLY DOWNLOAD & REFRESH ROW")
            downloader.removeDownload(for: model.identifier) { [weak self] error in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                }
                model.downloadStatus = .NONE
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
}

