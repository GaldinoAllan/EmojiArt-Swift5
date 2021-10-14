//
//  EmojiArtView.swift
//  mojiArt
//
//  Created by allan galdino on 13/09/21.
//

import UIKit

class EmojiArtView: UIView {

    // MARK: - Properties

    var backgroundImage: UIImage? { didSet { setNeedsDisplay() } }
    private var labelObservations = [UIView: NSKeyValueObservation]()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overriden Methods

    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if labelObservations[subview] != nil {
            labelObservations[subview] = nil
        }
    }

    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }

    // MARK: - Mathods

    private func setup() {
        addInteraction(UIDropInteraction(delegate: self))
    }
}

extension EmojiArtView: UIDropInteractionDelegate {

    func dropInteraction(_ interaction: UIDropInteraction,
                         canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction,
                         sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSAttributedString.self) { providers in
            let dropPoint = session.location(in: self)
            for attributedString in providers as? [NSAttributedString] ?? [] {
                self.addLabel(with: attributedString, centeredAt: dropPoint)
                NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
            }
        }
    }

    func addLabel(with attributedString: NSAttributedString, centeredAt point: CGPoint) {
        let label = UILabel()
        label.backgroundColor = .clear
        label.attributedText = attributedString
        label.sizeToFit()
        label.center = point
        addEmojiArtGestureRecognizers(to: label)
        addSubview(label)
        labelObservations[label] = label.observe(\.center) { (label, change) in
            NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
        }
    }
}

extension Notification.Name {
    static let EmojiArtViewDidChange = Notification.Name("EmojiArtViewDidChange")
}
