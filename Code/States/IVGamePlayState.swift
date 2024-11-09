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
        print("did enter main game state")
        
        setupBackground()
        setupScoreLabel()
        setupHealthBar()
        setupPlayer()
        
        spawnProjectile()
    }
    
    override func willExit(to nextState: GKState) {
        guard let scene else {
            return
        }
        // remove filter and background
        let fadeOutAction = SKAction.fadeOut(withDuration: 2.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
        
        scene.background?.run(removeSequence)
        
        // reset local score
        localScore = 0
    }
    
    func setupBackground() {
        guard let scene else {
            return
        }
        addBackgroundFilter()
        let randomPhase = Phase.allCases.randomElement()
        background = SKSpriteNode(color: randomPhase!.color, size: scene.size)
        background?.anchorPoint = CGPointZero
        background?.position = CGPointZero
        background?.zPosition = -2
        background?.alpha = 0.4
        
        scene.addChild(background!)
        scene.background = background
        
        switchBackground()
    }
    func addBackgroundFilter() {
        guard let scene else {
            return
        }
        if let _ = scene.childNode(withName: "filter") {
            return
        }
        let filter = SKSpriteNode(color: .black, size: scene.size)
        filter.name = "filter"
        filter.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 2.0 )
        filter.alpha = 0.4
        filter.zPosition = -1
        scene.addChild(filter)
    }
    func switchBackground() {
        let waitAction = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let changePhase = SKAction.run { [self] in
            let currentPhase = Phase.phase(for: background!.color)
            let nextPhase = Phase.random(excluding: currentPhase!)
            background!.color = nextPhase.color
        }
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let changeSequence = SKAction.sequence([waitAction, fadeOut, changePhase, fadeIn])
        background!.run(SKAction.repeatForever(changeSequence))
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
                                      y: scene.size.height/1.06 )
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = -1
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
        //        let scoreLabel = scene?.childNode(withName: "scoreNode") as! SKLabelNode
        //        scoreLabel.text = "Score: \(context.gameInfo.score)"
        if localScore > context.gameInfo.transitionScore {
            print("go into laser game")
            context.stateMachine?.enter(IVLaserGameState.self)
        }
        if context.gameInfo.score < context.gameInfo.gameEndScore {
            print("go into laser game")
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
        player.setScale(0.4)
        player.zPosition = 4          // place behind other nodes (down the z-axis)
        
        guard let currentPhase = Phase.phase(for: background!.color) else {
            return
        }
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
                                      y: scene.size.height / 1.06)
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
    
    func spawnProjectile() {
        guard let scene else {
            return
        }
        // create a projectile node
        let randomParticle = ["RedParticle", "GreenParticle", "BlueParticle"].randomElement()
        if let exp = SKEmitterNode(fileNamed: randomParticle!) {
            let startY = CGFloat.random(in: 25...(scene.size.height-25))
            let endY = CGFloat.random(in: 25...(scene.size.height-25))
            let start = CGPoint(x: 0,
                                   y: startY)
            let end = CGPoint(x: scene.size.width,
                                  y: endY)
            let entryPos = [start, end].randomElement()!
            let exitPos = entryPos == start ? end : start
            
            // calculate angle of projectile path
            let dx = (exitPos.x > entryPos.x)  ? (exitPos.x - entryPos.x) : (entryPos.x - exitPos.x)
            let dy = (exitPos.y > entryPos.y)  ? (exitPos.y - entryPos.y) : (entryPos.y - exitPos.y)
            let angle = atan2(dx, dy)       // TODO: need to fix
            
            exp.position = entryPos
            exp.zPosition = 5
//            exp.zRotation = angle
            exp.emissionAngle = .pi - angle
            exp.particleColor = randomParticle == "RedParticle" ? .red : (randomParticle == "GreenParticle" ? .green : .blue)
            
            // setup physics body (to check collision with enemy node)
            exp.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 25, height: 25))
            exp.physicsBody?.categoryBitMask = IVGameInfo.projectileMask[randomParticle!]!
            exp.physicsBody?.contactTestBitMask = IVGameInfo.player
            exp.physicsBody?.collisionBitMask = IVGameInfo.none
            exp.physicsBody?.affectedByGravity = false
            
            scene.addChild(exp)

            let moveAction = SKAction.move(to: exitPos, duration: 2.0)
            let removeAction = SKAction.removeFromParent()
            let shootSequence = SKAction.sequence([moveAction, removeAction])
            
            exp.run(shootSequence)
        }
    }
    
    func randomizeMovement() -> SKAction {
        // Random offsets for moving the enemy node(s)
        let randomX = CGFloat.random(in: -100...100)
        let randomY = CGFloat.random(in: -25...25)
        
        let enemy = scene?.childNode(withName: "enemyNode")
        let dx = randomX + (enemy?.position.x)!
        let dy = randomY + (enemy?.position.y)!
        
        let offsetX = (dx < 5) ? -randomX : ((dx > (scene?.size.width)!-5.0) ? -randomX : randomX)
        let offsetY = (dy < 5) ? -randomY : ((dy > (scene?.size.height)!/2.0) ? -randomY : randomY)
        
//        let offsetX = ((dX + (enemy?.position.x)!) < 5 || (dX + (enemy?.position.x)!) > (scene?.size.width)!) ? 0 : dX
//        let offsetY = ((dY + (enemy?.position.y)!) < 5 || (dY + (enemy?.position.y)!) > (scene?.size.height)!/2.0) ? 0 : dY

        let moveAction = SKAction.moveBy(x: offsetX, y: offsetY, duration: 2.0)
        let waitAction = SKAction.wait(forDuration: 0.2)        // slight pause for smoother animation
        return SKAction.sequence([moveAction, waitAction])
    }
    
    /* METHODS to handle touch events */
    func handleTouch(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
    
}
