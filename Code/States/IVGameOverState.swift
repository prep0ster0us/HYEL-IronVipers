
/**
 Defines game over state, when the main game is terminated (multiple entry points - no remaining lives, no health, ran out of time)
*/

import GameplayKit
import SwiftUI

class IVGameOverState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    /// STEP-2: initialize these values for each state
    init(scene: IVGameScene, context: IVGameContext) {
        self.scene = scene
        self.context = context
        super.init()                // retain the properties from the parent/global state
    }
    
    /* method to control where the current state can navigate to (future) */
    /// ex: once the splash animation is done, need to navigate to playable game-start state
    /// we can choose to allow or disallow it from here.
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    /* method to control where the current state is coming from (past) */
    /// a state can have multiple entry points, this helps check which state calls the current state (i.e. the parent state)
    /// ex: game-over state can be a result of time running out OR no more lives left.
    override func didEnter(from previousState: GKState?) {
        print("did enter game over state")
        
        scene?.removeAllActions()
        removeNodes() {
            self.setupGameOver()
        }
        
    }
    
    override func willExit(to nextState: GKState) {
        guard let scene else { return }
        
        let nodesToRemove = scene.children.filter { $0.name == "background" }
        for node in nodesToRemove {
            node.removeFromParent()
        }
        // remove game over filter
        if let filter = scene.childNode(withName: "gameOverFilter") {
            let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
            let removeAction = SKAction.removeFromParent()
            let removeGroup = SKAction.group([fadeOutAction, removeAction])
            filter.run(removeGroup)
        }
    }
    
    func setupGameOver() {
        guard let scene else {
            return
        }
        // add background filter (for dark game over screen)
        let filter = SKSpriteNode(color: .black, size: scene.size)
        filter.name = "gameOverFilter"
        filter.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 2.0 )
        filter.alpha = 0.5
        filter.zPosition = -1
        scene.addChild(filter)
        
        // move player node
        let center = CGPoint(x: scene.size.width / 2.0,
                             y: scene.size.height / 6.0)  // **testing
        let moveAction = SKAction.move(to: center, duration: 2.0)
        scene.childNode(withName: "playerNode")?.run(moveAction)
        
        // add play again label
        let playAgainLabel = SKLabelNode(text: "Tap anywhere to play Again")
        playAgainLabel.name = "playAgainLabel"
        playAgainLabel.position = CGPoint(x: scene.size.width/2.0,
                                          y: scene.size.height/1.2 )
        playAgainLabel.zPosition = 2    // on top of scene
        playAgainLabel.fontSize = 32
        
        scene.addChild(playAgainLabel)
        
        // show final score
        if let scoreNode = scene.childNode(withName: "scoreNode") {
            let scorePos = CGPoint(x: scene.size.width/2.0,
                                 y: scene.size.height/3.0 )
            let scoreScaleAction = SKAction.scale(to: 1.5, duration: 1.5)
            let scoreMoveAction = SKAction.move(to: scorePos , duration: 2.0)
            
            scoreNode.run(SKAction.group([scoreScaleAction, scoreMoveAction]))
        }
    
    }
    func removeNodes(completion: @escaping () -> Void) {
        guard let scene else {
            return
        }
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        let removeGroup = SKAction.group([fadeOutAction, removeAction])
        
        // remove unnecessary nodes
        let nodesToRemove = scene.children.filter {
            $0.name != "background" && $0.name != "playerNode" && $0.name != "scoreNode"
        }
        for node in nodesToRemove {
            node.run(removeGroup)
        }
        // add slight delay for removal
        scene.run(SKAction.wait(forDuration: 0.1), completion: completion)
        
    }
    
    
    func handleTouch(_ touch: UITouch) {
        guard let context else {
            return
        }
        print("Touch on game over state")
        
        // reset interface
        resetInterface {
            context.stateMachine?.enter(IVGamePlayState.self)
        }
        
    }
    func resetInterface(completion: @escaping () -> Void) {
        guard let scene, let context else {
            completion()
            return
        }
        
        // remove try again label
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
        scene.childNode(withName: "playAgainLabel")?.run(removeSequence)

        // reset previous score (and health)
        context.gameInfo.score = 0
        context.gameInfo.health = 100
        
        // scale and place back the score label (for "new" session)
        let originalPosition = CGPoint(x: scene.size.width/6.0,
                                       y: scene.size.height/1.08 )
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        let moveAction = SKAction.move(to: originalPosition , duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let groupActions = [scaleAction, moveAction, fadeIn]

        if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode {
            let fadeOut = SKAction.fadeOut(withDuration: 1.0)
            let update = SKAction.run {
                scoreLabel.text = "Score: \(context.gameInfo.score)"
            }
            
            let moveBack = SKAction.group(groupActions)
            scoreLabel.run(SKAction.sequence([fadeOut, update, moveBack])) {
                completion()
            }
        }
        
    }
    
}
