//
//  EmojiArt.swift
//  Emoji Art
//
//  Created by CS193p Instructor on 5/8/23.
//  Copyright (c) 2023 Stanford University
//

import Foundation

struct EmojiArt {
    var background: URL?
    private(set) var emojis = [Emoji]()
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            string: emoji,
            position: position,
            size: size,
            id: uniqueEmojiId
        ))
    }
    
    mutating func removeEmojis() {
        for emoji in emojis {
            if let index = index(of: emoji.id) {
                emojis.remove(at: index)
            }
        }
    }
    
    mutating func updateEmojiScale(_ emoji: Emoji, scaleEffect: Double) {
        if let index = emojis.firstIndex(where: { $0.id == emoji.id }) {
            emojis[index].scaleEffect = scaleEffect
        }
    }
    
    mutating func updateEmojiOffset(_ emoji: Emoji, offset: CGOffset) {
        if let index = emojis.firstIndex(where: { $0.id == emoji.id }) {
            emojis[index].offset = offset
        }
    }
    
    
    subscript(_ emojiId: Emoji.ID) -> Emoji? {
        if let index = index(of: emojiId) {
            return emojis[index]
        } else {
            return nil
        }
    }

    subscript(_ emoji: Emoji) -> Emoji {
        get {
            if let index = index(of: emoji.id) {
                return emojis[index]
            } else {
                return emoji // should probably throw error
            }
        }
        set {
            if let index = index(of: emoji.id) {
                emojis[index] = newValue
            }
        }
    }
    
    private func index(of emojiId: Emoji.ID) -> Int? {
        emojis.firstIndex(where: { $0.id == emojiId })
    }

    struct Emoji: Identifiable {
        let string: String
        var position: Position
        var size: Int
        var id: Int
        var scaleEffect: CGFloat = 1
        var offset: CGOffset = .zero
        
        struct Position {
            var x: Int
            var y: Int
            
            static let zero = Self(x: 0, y: 0)
        }
    }
}
