//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by CS193p Instructor on 5/8/23.
//  Copyright (c) 2023 Stanford University
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji
    
    @ObservedObject var document: EmojiArtDocument
    
    private let paletteEmojiSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            documentBody
            Button {
                deleteEmojis()
            } label: {
                Text("Delete Emojis")
            }.disabled(document.emojis.count == 0)
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                documentContents(in: geometry)
                    .scaleEffect(zoom * gestureZoom)
                    .offset(pan + gesturePan)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .dropDestination(for: Sturldata.self) { sturldatas, location in
                return drop(sturldatas, at: location, in: geometry)
            }
            .onTapGesture {
                unSelectAllEmojis()
            }
        }
    }
    
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        AsyncImage(url: document.background)
            .position(Emoji.Position.zero.in(geometry))
        ForEach(document.emojis) { emoji in
                Text(emoji.string)
                    .font(emoji.font)
                    .border(Color.red.opacity(isSelected(emoji) ? 1 : 0), width: 3)
                    .scaleEffect(isSelected(emoji) ? emoji.scaleEffect * zoomEmoji * gestureZoomEmoji : emoji.scaleEffect)
                    .offset(isSelected(emoji) ? emoji.offset + panEmoji + gesturePanEmoji : emoji.offset)
                    .gesture(isSelected(emoji) ? panGestureEmoji : nil)
                    .position(emoji.position.in(geometry))
                    .onTapGesture {
                        if isSelected(emoji) {
                            updateEmojiScale(emoji, scaleEffect: emoji.scaleEffect * zoomEmoji)
                            updateEmojiOffset(emoji, offset: emoji.offset + panEmoji)
                            unSelectEmoji(emoji)
                        } else {
                            updateEmojiScale(emoji, scaleEffect: emoji.scaleEffect / zoomEmoji)
                            updateEmojiOffset(emoji, offset: emoji.offset - panEmoji)
                            selectEmoji(emoji)
                        }
                    }
           
        }
    }
    
    private func updateEmojiScale(_ emoji: Emoji, scaleEffect: Double) {
        document.updateEmojiScale(emoji, scaleEffect: scaleEffect)
    }
    
    private func updateEmojiOffset(_ emoji: Emoji, offset: CGOffset) {
        document.updateEmojiOffset(emoji, offset: offset)
    }
    
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    
    
    @State private var zoomEmoji: CGFloat = 1
    @State private var panEmoji: CGOffset = .zero
    @State private var zoomEmojiEndingPinchScale: CGFloat = 1
    
    @GestureState private var gestureZoomEmoji: CGFloat = 1
    @GestureState private var gesturePanEmoji: CGOffset = .zero
    
    
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                if selectEmojiList.count == 0 {
                    gestureZoom = inMotionPinchScale
                }
                
            }
            .updating($gestureZoomEmoji) { inMotionPinchScale, gestureZoomEmoji, _ in
                if selectEmojiList.count > 0 {
                    gestureZoomEmoji = inMotionPinchScale
                }
            }
            .onEnded { endingPinchScale in
                if selectEmojiList.count == 0 {
                    zoom *= endingPinchScale
                } else if selectEmojiList.count > 0 {
                    zoomEmojiEndingPinchScale *= endingPinchScale
                    zoomEmoji *= endingPinchScale
                }
                
            }
         
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { inMotionDragGestureValue, gesturePan, _ in
                if selectEmojiList.count == 0 {
                    gesturePan = inMotionDragGestureValue.translation
                }
            }
            .onEnded { endingDragGestureValue in
                if selectEmojiList.count == 0 {
                    pan += endingDragGestureValue.translation
                }
                
            }
    }
    
    private var panGestureEmoji: some Gesture {
        DragGesture()
            .updating($gesturePanEmoji) { inMotionDragGestureValue, gesturePanEmoji, _ in
                if selectEmojiList.count > 0 {
                    gesturePanEmoji = inMotionDragGestureValue.translation
                }
            }
            .onEnded { endingDragGestureValue in
                if selectEmojiList.count > 0 {
                    panEmoji += endingDragGestureValue.translation
                }
            }
    }
    
    @State private var selectEmojiList = Set<Emoji.ID>()
    
    private func selectEmoji(_ emoji: Emoji) {
        selectEmojiList.insert(emoji.id)
    }
    private func isSelected(_ emoji: Emoji) -> Bool {
        selectEmojiList.contains(emoji.id)
    }
    
    private func unSelectEmoji(_ emoji: Emoji) {
        selectEmojiList.remove(emoji.id)
    }
    
    private func unSelectAllEmojis() {
        for emojiId in selectEmojiList {
            if let index = document.emojis.firstIndex(where: { $0.id == emojiId }) {
                let emoji = document.emojis[index]
                updateEmojiScale(emoji, scaleEffect: emoji.scaleEffect * zoomEmoji)
                updateEmojiOffset(emoji, offset: emoji.offset + panEmoji)
                unSelectEmoji(emoji)
            }
            
        }
        selectEmojiList.removeAll()
    }
    
    private func deleteEmojis() {
        document.removeEmojis()
        selectEmojiList.removeAll()
    }
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize / zoom
                )
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(
            x: Int((location.x - center.x - pan.width) / zoom),
            y: Int(-(location.y - center.y - pan.height) / zoom)
        )
    }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
