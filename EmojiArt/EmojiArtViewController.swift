//
//  EmojiArtViewController.swift
//  mojiArt
//
//  Created by allan galdino on 13/09/21.
//

import UIKit

class EmojiArtViewController: UIViewController {

    // MARK: - Model

    var emojiArt: EmojiArt? {
        get { getEmojiArt() }
        set { setEmojiArt(withNewValue: newValue) }
    }

    // MARK: - Properties

    var emojiArtView = EmojiArtView()
    var document: EmojiArtDocument?

    var imageFetcher: ImageFetcher!
    var emojis = "😀🎁✈️🎱🍎🐶🐝🎼🚲♣️🧑🏽‍🎓✏️🌈🤡🎓👻☎️".map { String($0) }

    private var addingEmoji = false
    private var emojiArtBackgroundImageURL: URL?
    private var suppressBadURLWarnings: Bool = false

    private var documentObserver: NSObjectProtocol?
    private var emojiArtViewObserver: NSObjectProtocol?

    // MARK: - IBOutlets

    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }

    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!

    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true
        }
    }

    // MARK: - IBActions

    @IBAction func addEmoji() {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }

    @IBAction func close(_ sender: UIBarButtonItem) {
        if let observer = emojiArtViewObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        dismiss(animated: true) {
            self.document?.close { success in
                if let observer = self.documentObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
    
    // MARK: - Overriden methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        documentObserver = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: document,
            queue: .main,
            using: { notification in
                print("documentState changed to \(self.document!.documentState)")
            })
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
                self.emojiArtViewObserver = NotificationCenter.default.addObserver(
                    forName: .EmojiArtViewDidChange,
                    object: self.emojiArtView,
                    queue: .main,
                    using: { notification in
                        self.documentChanged()
                    })
            }
        }
    }

    // MARK: - Contents

    func documentChanged() {
        document?.emojiArt = emojiArt
        guard document?.emojiArt != nil else { return }
        document?.updateChangeCount(.done)
    }

    func getEmojiArt() -> EmojiArt? {
        guard let url = emojiArtBackgroundImage.url else { return nil }

        let emojis = emojiArtView.subviews
            .compactMap { $0 as? UILabel }
            .compactMap { EmojiArt.EmojiInfo(label: $0) }
        return EmojiArt(url: url, emojis: emojis)
    }

    func setEmojiArt(withNewValue newValue: EmojiArt?) {
        emojiArtBackgroundImage = (nil, nil)
        emojiArtView.subviews
            .compactMap { $0 as? UILabel }
            .forEach { $0.removeFromSuperview() }
        if let url = newValue?.url {
            imageFetcher = ImageFetcher(fetch: url) { (url, image) in
                DispatchQueue.main.async {
                    self.emojiArtBackgroundImage = (url, image)
                    newValue?.emojis.forEach {
                        let attributedText = $0.text.attributedString(withTextStyle: .body,
                                                                      ofSize: CGFloat($0.size))
                        self.emojiArtView.addLabel(with: attributedText,
                                                   centeredAt: CGPoint(x: $0.x, y: $0.y))
                    }
                }
            }
        }
    }
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

    private func presentBadURLWarning(for url: URL?) {
        guard !suppressBadURLWarnings else { return }

        let alert = UIAlertController(title: "Image Drop Failed",
                                      message: "Couldn't transfer the dropped image from its source.\nShow this warning in the future?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep Warning",
                                      style: .default))
        alert.addAction(UIAlertAction(title: "Stop Warning",
                                      style: .destructive) { action in
            self.suppressBadURLWarnings = true
        })


        present(alert, animated: true)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
        }

        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
//                self.imageFetcher.fetch(url)
                DispatchQueue.main.async {
                    if let imageData = try? Data(contentsOf: url.imageURL),
                       let image = UIImage(data: imageData) {
                        self.emojiArtBackgroundImage = (url, image)
                        self.documentChanged()
                    } else {
                        self.presentBadURLWarning(for: url)
                    }
                }
            }
        }

        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension EmojiArtViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }

    var emojiArtBackgroundImage: (url: URL?, image: UIImage?) {
        get {
            return (emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set {
            emojiArtBackgroundImageURL = newValue.url
            scrollView.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: .zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone,
               size.width > 0,
               size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width,
                                            dropZone.bounds.size.height / size.height)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension EmojiArtViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return emojis.count
        default: return 0
        }
    }

    private var font: UIFont {
        UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: UIFont
                            .preferredFont(forTextStyle: .body)
                            .withSize(48.0))
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            guard let cell = collectionView
                    .dequeueReusableCell(withReuseIdentifier: "EmojiCell",
                                         for: indexPath) as? EmojiCollectionViewCell else {
                return UICollectionViewCell()
            }

            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
            cell.label.attributedText = text
            return cell
        } else if addingEmoji {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell",
                                                          for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text {
                        self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell",
                                                          for: indexPath)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EmojiArtViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension EmojiArtViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension EmojiArtViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        itemsForAddingTo session: UIDragSession,
                        at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }

    private func dragItems(at indexPath: IndexPath) -> [UIDragItem]{
        if !addingEmoji,
           let attributedString = (
            emojiCollectionView
                .cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        }
        return []
    }
}

// MARK: - UICollectionViewDropDelegate

extension EmojiArtViewController: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let indexPath = destinationIndexPath,
              indexPath.section == 1 else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        let isSelf = (session
                        .localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy,
                                            intent: .insertAtDestinationIndexPath)

    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0,
                                                                                 section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    collectionView.performBatchUpdates {
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    }
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath,
                                                        reuseIdentifier: "DropPlaceholderCell"))

                item.dragItem
                    .itemProvider
                    .loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                        DispatchQueue.main.async {
                            if let attributedString = provider as? NSAttributedString {
                                placeholderContext.commitInsertion { insertionIndexPath in
                                    self.emojis.insert(attributedString.string,
                                                       at: insertionIndexPath.item)
                                }
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        }
                }
            }
        }
    }
}

extension EmojiArt.EmojiInfo {
    init?(label: UILabel) {
        guard let attributedText = label.attributedText,
              let font = attributedText.font else { return nil}
        x = Int(label.center.x)
        y = Int(label.center.y)
        text = attributedText.string
        size = Int(font.pointSize)
    }
}
