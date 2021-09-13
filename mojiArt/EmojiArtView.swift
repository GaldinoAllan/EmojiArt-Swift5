//
//  EmojiArtView.swift
//  mojiArt
//
//  Created by allan galdino on 13/09/21.
//

import UIKit

class EmojiArtView: UIView {
    var backgroundImage: UIImage? { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }

}
