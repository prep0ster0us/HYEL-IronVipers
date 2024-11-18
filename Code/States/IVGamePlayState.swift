/**
 Defines the main game play state of the game; wave generation and other core game logic will be defined here
*/

import GameplayKit
import SwiftUI

class IVGamePlayState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var currentColor: SKColor!
    var playerProjectile : SKSpriteNode?
    var enemyProjectile : SKSpriteNode?
    
    var background: SKSpriteNode?
    var localScore = 0         // to transition to other states periodically
    
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
        guard let scene, let context else { return }
        print("did enter main game state")
        
        if previousState is IVDemoState || previousState is IVGameOverState {
            IVGameInfo.difficulty = 0
        }
        
        if scene.childNode(withName: "background") == nil {
            BackgroundManager.shared.setup(scene, context)
        }
        setupScoreLabel()
        setupHealthBar()
        setupPlayer()
        
        BorderManager.shared.setup(scene, context)
        ProjectileManager.shared.setup(scene, context)
    }
    
    override func willExit(to nextState: GKState) {        
        // reset local score
        localScore = 0
    }
    
    func setupScoreLabel() {
        guard let scene, let context else {
            return
        }
        if let _ = scene.childNode(withName: "scoreNode") {
            return
        }
        
        let scoreLabel = SKLabelNode(text: "Score: \(context.gameInfo.score)")
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: scene.size.width/6.0,
                                      y: scene.size.height/1.08 )
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 1
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.name = "scoreNode"
        scoreLabel.alpha = 0.0
        
        let fadeInAction = SKAction.fadeIn(withDuration: 1.0)
        scoreLabel.run(fadeInAction)
        scene.addChild(scoreLabel)
    }
    func updateScore() {
        guard let context else {
            return
        }
        if localScore > context.gameInfo.transitionScore {
            print("go into some game stage")
            context.stateMachine?.enter(context.stateList.randomElement()!)
//            context.stateMachine?.enter(IVLaserGameState.self)
        }
        if context.gameInfo.score < context.gameInfo.gameEndScore {
            print("game over")
            context.stateMachine?.enter(IVGameOverState.self)
        }
    }
    
    func setupPlayer() {
        guard let scene, let context else {
            return
        }
        if let _ = scene.childNode(withName: "playerNode") {
            return
        }
        
        // create node object (to be added to the screen)
        let player = context.gameInfo.player
        player.name = "playerNode"
        player.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 6.0)
        player.setScale(0.6)
        player.zPosition = 3          // place behind other nodes (down the z-axis)
        
        let currentPhase = context.gameInfo.currentPhase
        // setup physics body (to check contact with enemy projectiles)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = IVGameInfo.player
        player.physicsBody?.contactTestBitMask = IVGameInfo.projectileMask[IVGameInfo.particleName[currentPhase]!]!
        player.physicsBody?.collisionBitMask = IVGameInfo.none
        player.physicsBody?.affectedByGravity = false
        
        scene.addChild(player)              // add node to the screen
        scene.player = player
    }
    
    func setupHealthBar() {
        guard let scene, let context else {
            return
        }
        if let _ = scene.childNode(withName: "healthNode") {
            return
        }
        // TODO: create health bar; (for now, just HP value as text)
        let healthLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        healthLabel.text = "HP: \(context.gameInfo.health)"
        healthLabel.name = "healthNode"
        healthLabel.fontColor = .white
        healthLabel.fontSize = 24
        healthLabel.position = CGPoint(x: scene.size.width / 1.2,
                                      y: scene.size.height / 1.08)
        healthLabel.zPosition = 1
        healthLabel.alpha = 0.0
        
        let fadeInAction = SKAction.fadeIn(withDuration: 1.0)
        
        scene.addChild(healthLabel)
        healthLabel.run(fadeInAction)
    }
    func updateHealth() {
        guard let scene, let context else {
            return
        }
        let healthLabel = scene.childNode(withName: "healthNode") as! SKLabelNode
        healthLabel.text = "HP: \(context.gameInfo.health)"
        
        if context.gameInfo.health < context.gameInfo.testHealth {
            context.stateMachine?.enter(IVGameOverState.self)
        }
    }
    
    /* METHODS to handle touch events */
    func handleTouch(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        let location = touch.location(in: scene)
        scene.player?.position = CGPoint(x: location.x-20, y: location.y+20)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        let location = touch.location(in: scene)
        scene.player?.position = CGPoint(x: location.x-20, y: location.y+20)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
    
}
