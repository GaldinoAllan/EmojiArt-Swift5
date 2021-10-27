//
//  DocumentInfoViewController.swift
//  EmojiArt
//
//  Created by allan galdino on 27/10/21.
//

import UIKit

class DocumentInfoViewController: UIViewController {

    // MARK: - Properties

    var document: EmojiArtDocument? {
        didSet { updateUI() }
    }

    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - IBOutlets

    @IBOutlet weak var topLevelView: UIStackView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var thumbnailAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var returnToDocumentButton: UIButton!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if presentationController is UIPopoverPresentationController {
            guard let fittedSize = topLevelView?
                    .sizeThatFits(UIView.layoutFittingCompressedSize) else { return }

            preferredContentSize = CGSize(width: fittedSize.width, height: fittedSize.height)
        }
    }

    // MARK: - IBActions

    @IBAction func done() {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: - Contents

    private func updateUI() {
        guard sizeLabel != nil,
              createdLabel != nil,
              let url = document?.fileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
                  return
              }

        sizeLabel.text = "\(attributes[.size] ?? 0) bytes"

        if let created = attributes[.creationDate] as? Date {
            createdLabel.text = shortDateFormatter.string(from: created)
        }

        guard thumbnailImageView != nil,
              thumbnailAspectRatio != nil,
              let thumbnail = document?.thumbnail else { return }

        thumbnailImageView.image = thumbnail
        thumbnailImageView.removeConstraint(thumbnailAspectRatio)
        thumbnailAspectRatio = NSLayoutConstraint(item: thumbnailImageView!,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: thumbnailImageView,
                                                  attribute: .height,
                                                  multiplier: thumbnail.size.width / thumbnail.size.height,
                                                  constant: 0)
        thumbnailImageView.addConstraint(thumbnailAspectRatio)

        if presentationController is UIPopoverPresentationController {
            thumbnailImageView.isHidden = true
            returnToDocumentButton.isHidden = true
            view.backgroundColor = .clear
        }
    }
}
