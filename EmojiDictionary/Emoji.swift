//
//  Emoji.swift
//  EmojiDictionary
//

import Foundation

struct Emoji {
    var symbol: String
    var name: String
    var description: String
    var usage: String
}

// MARK: - Sample Data
extension Emoji {
    static var sampleEmojis: [Emoji] {
        [
            Emoji(symbol: "😀", name: "Grinning Face", description: "A typical smiley face.", usage: "happiness"),
            Emoji(symbol: "😕", name: "Confused Face", description: "A puzzled face.", usage: "unsure"),
            Emoji(symbol: "😍", name: "Heart Eyes", description: "Loves something.", usage: "love"),
            Emoji(symbol: "🧑‍💻", name: "Developer", description: "Working on Mac.", usage: "software, coding"),
            Emoji(symbol: "🐢", name: "Turtle", description: "Slow but steady.", usage: "slow"),
            Emoji(symbol: "📚", name: "Books", description: "Stack of books.", usage: "study")
        ]
    }
}
