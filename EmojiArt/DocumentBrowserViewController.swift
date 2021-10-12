//
//  DocumentBrowserViewController.swift
//  EmojiArt
//
//  Created by allan galdino on 12/10/21.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {

    // MARK: - Properties

    var template: URL?

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsPickingMultipleItems = false
        allowsDocumentCreation = false
        if UIDevice.current.userInterfaceIdiom == .pad {
            template = try? FileManager.default
                .url(for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true)
                .appendingPathComponent("Untitled.json")
        }

        if let template = template {
            allowsDocumentCreation = FileManager.default.createFile(atPath: template.path,
                                                                    contents: Data())
        }
    }
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didRequestDocumentCreationWithHandler importHandler: @escaping (
                            URL?,
                            UIDocumentBrowserViewController.ImportMode) -> Void) {
                                importHandler(template, .copy)
                            }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didImportDocumentAt sourceURL: URL,
                         toDestinationURL destinationURL: URL) {
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         failedToImportDocumentAt documentURL: URL, error: Error?) {}
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentVC = storyBoard.instantiateViewController(withIdentifier: "DocumentMVC")

        if let emojiArtViewController = documentVC.contents as? EmojiArtViewController {
            emojiArtViewController.document = EmojiArtDocument(fileURL: documentURL)
        }
        present(documentVC, animated: true)
    }
}

