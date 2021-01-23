//
//  DownloadTableViewCell.swift
//  FileDownloaderTest
//
//  Created by Rakitha Perera on 22.01.21.
//  Copyright © 2021 Sanggeon Park. All rights reserved.
//

import UIKit

class DownloadTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    func configureCell(viewModel : DownloadViewModel) {
        lblTitle.text = viewModel.identifier
        let status = viewModel.downloadStatus
        switch status {
        case .DOWNLOADING:
            #warning("UPDATE DOWNLOADING PROGRESS")
            lblStatus.text = String(format: "%.2f%%", viewModel.progress)
            progressView.isHidden = false
            progressView.progress = viewModel.progress / 100
        default:
            progressView.isHidden = true
            lblStatus.text = viewModel.downloadStatus.rawValue
        }
    }

}
