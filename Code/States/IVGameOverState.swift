
/**
 Defines game over state, when the main game is terminated (multiple entry points - no remaining lives, no health, ran out of time)
*/

import GameplayKit

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
        
        removeGamePlayNodes()
//        displayScore()
    }
    func removeGamePlayNodes() {
        guard let scene else {
            return
        }
        let fadeOutAction = SKAction.fadeOut(withDuration: 2.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])

        scene.childNode(withName: "enemyNode")?.run(removeSequence)
        scene.childNode(withName: "playerProjectile")?.run(removeSequence)
        scene.childNode(withName: "enemyProjectile")?.run(removeSequence)
        scene.childNode(withName: "healthNode")?.run(removeSequence)
        scene.childNode(withName: "scoreNode")?.run(removeSequence)
        
        
        let center = CGPoint(x: scene.size.width / 2.0,
                             y: scene.size.height / 6.0)  // **testing
        let moveAction = SKAction.move(to: center, duration: 2.0)
        scene.childNode(withName: "playerNode")?.run(moveAction)
        
        let playAgainLabel = SKLabelNode(text: "Tap anywhere to play Again")
        playAgainLabel.name = "playAgainLabel"
        playAgainLabel.position = CGPoint(x: scene.size.width/2.0,
                                          y: scene.size.height/1.2 )
        playAgainLabel.zPosition = 4    // on top of scene
        playAgainLabel.fontSize = 32
        
        scene.addChild(playAgainLabel)
    }
    
    func displayScore() {
        guard let scene else {
            return
        }
        let center = CGPoint(x: scene.size.width/2.0,
                             y: scene.size.height/3.0 )
        let scaleAction = SKAction.scale(by: 2.0, duration: 3.0)
        let moveAction = SKAction.move(to: center , duration: 2.0)
        var groupActions = Array<SKAction>()
        groupActions.append(scaleAction)
        groupActions.append(moveAction)
        
        scene.childNode(withName: "scoreNode")!.run(SKAction.group(groupActions))
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene, let context else {
            return
        }
        print("Touch on game over state")
        print("play again!")
        
        // remove nodes
        let fadeOutAction = SKAction.fadeOut(withDuration: 2.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
        scene.childNode(withName: "playAgainLabel")?.run(removeSequence)
        scene.childNode(withName: "scoreLabel")?.run(removeSequence)
        
        resetScore()
        
        context.stateMachine?.enter(IVGamePlayState.self)
        
    }
    
    func resetScore() {
        guard let scene, let context else {
            return
        }
        // scale and place back the score label (for "new" session)
        let originalPosition = CGPoint(x: scene.size.width / 6.0,
                             y: scene.size.height / 1.08)
        let scaleAction = SKAction.scale(by: 2.0, duration: 3.0)
        let moveAction = SKAction.move(to: originalPosition , duration: 2.0)
        var groupActions = Array<SKAction>()
        groupActions.append(scaleAction)
        groupActions.append(moveAction)
        
        // reset previous score (and health)
        context.gameInfo.score = 0
        context.gameInfo.health = 100
        
        // update label text
//        let scoreLabel = scene.childNode(withName: "scoreNode") as! SKLabelNode
//        scoreLabel.run(SKAction.sequence([SKAction.group(groupActions), SKAction.removeFromParent()]))
        
    }
    
}
