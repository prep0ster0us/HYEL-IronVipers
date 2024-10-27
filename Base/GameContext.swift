//
//  GameContext.swift
//  Test
//
//  Created by Hyung Lee on 10/20/24.
//

import Combine
import GameplayKit
import SwiftUI

// abstract promise
// if anyone conforms to this, it needs to fulfill these 4 basic capability (2 fields + 2 methods)
protocol GameContextDelegate: AnyObject {
    var gameMode: GameModeType { get }
    var gameType: GameType { get }

    func exitGame()
    func transitionToScore(_ score: Int)
}

// we'll be creating a child context off this
// tracks reference to the scene
class GameContext {
    var shouldResetPlayback: Bool = false

    @Published var opacity: Double = 0.0
    @Published var isShowingSettings = false

    var subs = Set<AnyCancellable>()
    
    var scene: SKScene?

    private(set) var dependencies: Dependencies
    
    var gameType: GameType? {
        delegate?.gameType
    }

    weak var delegate: GameContextDelegate?     // reference to delegate, which implements GameContextDelegate

    init(dependencies deps: Dependencies) {
        dependencies = deps
    }
    
    func exit() {
    }
}

extension GameContext: ObservableObject {}
