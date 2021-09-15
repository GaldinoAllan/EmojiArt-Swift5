//
//  TextFieldCollectionViewCell.swift
//  mojiArt
//
//  Created by allan galdino on 15/09/21.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    var resignationHandler: (() -> Void)?

    // MARK: - IBOutlet

    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }
}

extension TextFieldCollectionViewCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }
}
