//
//  EmojiArtViewController.swift
//  mojiArt
//
//  Created by allan galdino on 13/09/21.
//

import UIKit

class EmojiArtViewController: UIViewController {

    // MARK: - Properties

    var imageFetcher: ImageFetcher!

    // MARK: - IBOutlets

    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    @IBOutlet weak var emojiArtView: EmojiArtView!

}

// MARK: - UIDropInteractionDelegate

extension EmojiArtViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction,
                         canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) &&
            session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtView.backgroundImage = image
            }
        }

        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
                self.imageFetcher.fetch(url)
            }
        }

        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
        }
    }
}
