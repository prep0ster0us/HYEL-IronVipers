
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
        
        addBackgroundFilter()
        removeGamePlayNodes()
        displayScore()
    }
    func addBackgroundFilter() {
        guard let scene else {
            return
        }
        let filter = SKSpriteNode(color: .black, size: scene.size)
        filter.name = "gameOverFilter"
        filter.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 2.0 )
        filter.alpha = 0.5
        filter.zPosition = -1
        scene.addChild(filter)
    }
    func removeGamePlayNodes() {
        guard let scene else {
            return
        }
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])

        scene.childNode(withName: "enemyNode")?.run(removeSequence)
        scene.childNode(withName: "playerProjectile")?.run(removeSequence)
        scene.childNode(withName: "enemyProjectile")?.run(removeSequence)
        scene.childNode(withName: "healthNode")?.run(removeSequence)
//        scene.childNode(withName: "scoreNode")?.run(removeSequence)
        
        
        let center = CGPoint(x: scene.size.width / 2.0,
                             y: scene.size.height / 6.0)  // **testing
        let moveAction = SKAction.move(to: center, duration: 2.0)
        scene.childNode(withName: "playerNode")?.run(moveAction)
        
        let playAgainLabel = SKLabelNode(text: "Tap anywhere to play Again")
        playAgainLabel.name = "playAgainLabel"
        playAgainLabel.position = CGPoint(x: scene.size.width/2.0,
                                          y: scene.size.height/1.2 )
        playAgainLabel.zPosition = 2    // on top of scene
        playAgainLabel.fontSize = 32
        
        scene.addChild(playAgainLabel)
    }
    
    func displayScore() {
        guard let scene else {
            return
        }
        let center = CGPoint(x: scene.size.width/2.0,
                             y: scene.size.height/3.0 )
        let scaleAction = SKAction.scale(to: 1.5, duration: 1.5)
        let moveAction = SKAction.move(to: center , duration: 2.0)
        var groupActions = Array<SKAction>()
        groupActions.append(scaleAction)
        groupActions.append(moveAction)
        
        scene.childNode(withName: "scoreNode")!.run(SKAction.group(groupActions))
//        scene.childNode(withName: "healthNode")!.run(SKAction.group(groupActions))
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene, let context else {
            return
        }
        print("Touch on game over state")
        
        // remove nodes
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
        scene.childNode(withName: "playAgainLabel")?.run(removeSequence)
        scene.childNode(withName: "scoreLabel")?.run(removeSequence)
        scene.childNode(withName: "gameOverFilter")?.run(removeSequence)
        
        resetGameInfo()
        
        let delay = SKAction.wait(forDuration: 1.5)
        scene.run(delay) {
            context.stateMachine?.enter(IVGamePlayState.self)
        }
        
    }
    
    func resetGameInfo() {
        guard let scene, let context else {
            return
        }
        
        // reset previous score (and health)
        context.gameInfo.score = 0
        context.gameInfo.health = 100
        
        // scale and place back the score label (for "new" session)
        let originalPosition = CGPoint(x: scene.size.width/5.8,
                                       y: scene.size.height/1.06 )
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        let moveAction = SKAction.move(to: originalPosition , duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        var groupActions = Array<SKAction>()
        groupActions.append(scaleAction)
        groupActions.append(moveAction)
        groupActions.append(fadeIn)

        
        if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode {
            let fadeOut = SKAction.fadeOut(withDuration: 1.0)
            let update = SKAction.run {
                scoreLabel.text = "Score: \(context.gameInfo.score)"
            }
            
            let moveBack = SKAction.group(groupActions)
            scoreLabel.run(SKAction.sequence([fadeOut, update, moveBack]))
        }
    }
    
}
