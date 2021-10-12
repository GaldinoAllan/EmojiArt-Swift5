//
//  EmojiArt.swift
//  mojiArt
//
//  Created by allan galdino on 12/10/21.
//

import Foundation

struct EmojiArt: Codable {
    var url: URL
    var emojis = [EmojiInfo]()
    var json: Data? { try? JSONEncoder().encode(self) }

    struct EmojiInfo: Codable {
        let x: Int
        let y: Int
        let text: String
        let size: Int
    }

    init(url: URL, emojis: [EmojiInfo]) {
        self.url = url
        self.emojis = emojis
    }

    init?(json: Data) {
        guard let newValue = try? JSONDecoder()
                .decode(EmojiArt.self, from: json) else { return nil }
        self = newValue
    }
}
