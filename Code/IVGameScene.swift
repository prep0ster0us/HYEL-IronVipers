/// #TEMPLATE FILE

/**
 Main screen seen by the player
 Most of the core logic goes in here (or reference some core logic from a different game scene)
 This is the engine which powers the whole game
*/


import SpriteKit
import GameplayKit
import SwiftUI

class IVGameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var context: IVGameContext?                // get game-specific context
                                                    // TODO: add/create references for all necessary elements/models
    
    var gameState: IVGamePlayState?
    var player: SKSpriteNode?                           // store reference for (main) player model
    var background: SKSpriteNode?
    var currentColor: SKColor!
    
    // time variables
    private var lastUpdateTime: TimeInterval = 0
    private var deltaTime: TimeInterval = 0
    private var actionInterval: TimeInterval = 1.0
    private var timeSinceLastAction: TimeInterval = 0
    
    private var lastStateChangeTime: TimeInterval = 0
    private var stateChangeDeltaTime: TimeInterval = 0
    private let stateChangeInterval: TimeInterval = 15  // Change state every 5 seconds
    private var timeSinceStateChangeAction: TimeInterval = 0
    
    init(context: IVGameContext, size: CGSize) {    // initializing (general)
        self.context = context                      // set game context
        super.init(size: size)                      // initialize game screen size
    }

    required init?(coder aDecoder: NSCoder) {       // custom initializer (TODO: need to implement for game-specific logic)
        fatalError("init(coder:) has not been implemented")
    }
    
    /* HELPER VARIABLES */
    var direction = "left"
    
    /*
     Standard method, triggered by sprite's behavior
     Called when sprite added to a SKScene (added to window heirarchy internally)
     */
    override func didMove(to view: SKView) {
        guard let context else {                    // confirmation for the game-context
            return                                  // cannot proceed without game context; *terminate exception
        }

        prepareGameContext()                        // helper method to setup based on context (BEFORE anything on screen)
        
        physicsWorld.contactDelegate = self         // initialize delegate for node physics
//        gameState = IVGamePlayState(scene: self, context: context)
    
        /* once everything setup; reference state machine and TRY to enter into a specific game state
         (for now, main menu state) */
        context.stateMachine?.enter(IVMainMenuState.self)
        
    }
    
    /* HELPER METHODS */
    func prepareGameContext() {
        guard let context else {                    // reconfirmation of game context (although already checked for)
            return
        }
        
        context.scene = self                                    // set up the scene (based on context)
        context.layoutInfo = IVLayoutInfo(screenSize: size)     // set up screen size
        context.configureStates()                               // configure each (starting) game state
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let context else {
            return
        }
        
        // cycle through different obstacle course states
//        cycleStates(currentTime)

        if let currentState = context.stateMachine?.currentState as? IVMainMenuState {
            currentState.randomizeDummyPlayerMovement()
        } else if let _ = context.stateMachine?.currentState as? IVGameOverState {
            return
            
        } else if let _ = context.stateMachine?.currentState as? IVDemoState {
            
        } else {
            
            // scrolling border
            BorderManager.shared.startScrolling()
            
            // Calculate delta time
            if lastUpdateTime == 0 {
                lastUpdateTime = currentTime
            }
            
            deltaTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
            
            // Update time since last action
            timeSinceLastAction += deltaTime
            
            // Check if it's time to perform the action
            if timeSinceLastAction >= actionInterval {
//                spawnProjectile()
                ProjectileManager.shared.spawnProjectiles()
                timeSinceLastAction = 0 // Reset the timer
            }
            
            // shoot projectiles (from player)
            if let currentState = context.stateMachine?.currentState as? IVGamePlayState {
                currentState.updateScore()
            }
            
            if let currentState = context.stateMachine?.currentState as? IVFollowPathState {
                currentState.detectPlayerPosition()
            }
            if let currentState = context.stateMachine?.currentState as? IVColorWaveState {
                currentState.spawnColorWave()
                currentState.detectPlayerContact()
            }
            if let currentState = context.stateMachine?.currentState as? IVCircleBombState {
                currentState.detectPlayerContact()
            }
        }
    
    }
    
    func spawnProjectile() {
        guard let scene else { return }
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
            exp.zPosition = 3
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
    func getDistance(_ direction: String, _ distance: CGFloat) -> CGFloat {
        return direction.elementsEqual("left") ? -distance : distance
    }
    
    func cycleToNextState() {
        guard let context else { return }
        // Get the current state and cycle to the next one
        if context.stateMachine?.currentState is IVGamePlayState {
            context.stateMachine?.enter(IVLaserGameState.self)
        } else if context.stateMachine?.currentState is IVLaserGameState {
            context.stateMachine?.enter(IVFollowPathState.self)
        } else if context.stateMachine?.currentState is IVFollowPathState {
            context.stateMachine?.enter(IVGamePlayState.self) // Loop back to the first state
        }
    }
    
    func preparePlayerAnim() {
        let playerAction = SKAction.customAction(withDuration: 1) { [weak self] node, _ in
            guard let self = self else { return }
            
            // Idle Game state - player model strolling 'anim'
            let strollDistance = (context?.layoutInfo.shipStrollDistance)!
            if (player?.position.x)! < size.width/4 {
                direction = "right"
            } else if(player?.position.x)! > (size.width)*(3/4) {
                direction = "left"
            }
            // add some shiver to y-axis
            let randomY = CGFloat.random(in: -1...1)
            let centerY = size.height / 2.0
            let deviation = 5.0
            let offsetY = (((player?.position.y)!+randomY) < (centerY+deviation)) ? randomY : 0
            node.position = CGPoint(
                x: (node.position.x) + getDistance(direction, strollDistance),
                y: (node.position.y) + offsetY
            )
        }
        player?.run(SKAction.repeatForever(playerAction), withKey: "idleAnim")
    }
    
    func scaleLabel(for label: SKLabelNode) {
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        label.run(scaleSequence)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("in contact")
        guard let context else {
            return
        }
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        let currentPhase = context.gameInfo.currentPhase
        let currentParticle = IVGameInfo.particleName[currentPhase]
        let currentProjectileMask = IVGameInfo.projectileMask[currentParticle!]
        
        if (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask == currentProjectileMask) ||
            (contactA.categoryBitMask == currentProjectileMask && contactB.categoryBitMask == IVGameInfo.player) {
            
            // Handle hit same colored projectile
            print("hit same color projectile")
            
            updateScore(reward: 1)
            // update local stage score
            if let currentState = context.stateMachine?.currentState as? IVGamePlayState {
                currentState.localScore += 1
            }
            
            if let projectile = (contactA.categoryBitMask == IVGameInfo.player) ? contactB.node : contactA.node {
                // Remove projectile nodes
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.1)
                let removeAction = SKAction.removeFromParent()
                let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
                projectile.run(removeSequence)
                
//                let scale = SKAction.sequence([SKAction.scale(to: 0.5, duration: 0.1), SKAction.scale(to: 0.4, duration: 0.1)])
                let scale = SKAction.sequence([SKAction.scale(to: 1.6, duration: 0.1), SKAction.scale(to: 1.5, duration: 0.1)])
                player?.run(scale)
            }
        }
        
        else if (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask == IVGameInfo.laser) ||
                    (contactA.categoryBitMask == IVGameInfo.laser && contactB.categoryBitMask == IVGameInfo.player) {
            // Handle player hit by laser
            print("hit laser beam")
            
            // Create a shiver effect using small movement actions
            let moveRight = SKAction.moveBy(x: 8, y: 0, duration: 0.05)
            let moveLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
            let shiverSequence = SKAction.sequence([moveRight, moveLeft, moveLeft, moveRight])
            let shiverRepeat = SKAction.repeat(shiverSequence, count: 5)
            
            // Run the shiver action on the player node
            player?.run(shiverRepeat)
            
            // mark as hit
            if let currentState = context.stateMachine?.currentState as? IVLaserGameState {
                currentState.isHitByLaser = true
            }
            
            updateHealth(penalty: context.gameInfo.laserPenalty)
        }
        
        else if (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask != currentProjectileMask) ||
            (contactA.categoryBitMask != currentProjectileMask && contactB.categoryBitMask == IVGameInfo.player) {
            
            // hit different color projectile
            updateHealth(penalty: context.gameInfo.projectilePenalty)
            
            // Handle enemy hit by player projectile
            print("hit different color projectile")
            
            if let projectile = (contactA.categoryBitMask == IVGameInfo.player) ? contactB.node : contactA.node {
                // Remove projectile nodes
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.2)
                let removeAction = SKAction.removeFromParent()
                let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
                projectile.run(removeSequence)
                
                let flash = SKAction.sequence([SKAction.fadeOut(withDuration: 0.05), SKAction.fadeIn(withDuration: 0.05)])
                player?.run(SKAction.repeat(flash, count: 2))
            }
        }
    }
    func updateHealth(penalty: Int) {
        guard let context else { return }
        context.gameInfo.health -= penalty
        if let healthLabel = childNode(withName: "healthNode") as? SKLabelNode {
            healthLabel.text = "HP: \(context.gameInfo.health)"
            scaleLabel(for: healthLabel)
        }
        if context.gameInfo.health <= context.gameInfo.testHealth {
            context.stateMachine?.enter(IVGameOverState.self)
        }
    }
    func updateScore(reward: Int) {
        guard let context else { return }
        context.gameInfo.score += reward
        if let scoreLabel = childNode(withName: "scoreNode") as? SKLabelNode {
            scoreLabel.text = "Score: \(context.gameInfo.score)"
            scaleLabel(for: scoreLabel)
        }
    }
    
    
    func cycleStates(_ currentTime: TimeInterval) {
        // Calculate delta time
        if lastStateChangeTime == 0 {
            lastStateChangeTime = currentTime
        }

        stateChangeDeltaTime = currentTime - lastStateChangeTime
        lastStateChangeTime = currentTime

        // Update time since last action
        timeSinceStateChangeAction += stateChangeDeltaTime

        // Check if it's time to perform the action
        if timeSinceStateChangeAction >= stateChangeInterval {
            cycleToNextState()
            timeSinceStateChangeAction = 0 // Reset the timer
        }
    }
    
    /* METHODS TO HANDLE NODE REPOSITION ON TOUCH */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        // TOUCH EVENTS FOR EACH STATE
        if let mainMenuState = context?.stateMachine?.currentState as? IVMainMenuState  {
            mainMenuState.handleTouch(touch)
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGamePlayState  {
            gamePlayState.handleTouch(touch)
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVLaserGameState  {
            gamePlayState.handleTouch(touch)
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGameOverState  {
            gamePlayState.handleTouch(touch)
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVFollowPathState  {
            gamePlayState.handleTouch(touch)
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVColorWaveState  {
            gamePlayState.handleTouch(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVCircleBombState  {
            gamePlayState.handleTouch(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVDemoState  {
            gamePlayState.handleTouch(touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGamePlayState  {
            gamePlayState.handleTouchMoved(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVLaserGameState  {
            gamePlayState.handleTouchMoved(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVFollowPathState  {
            gamePlayState.handleTouchMoved(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVColorWaveState  {
            gamePlayState.handleTouchMoved(touch)
        }
        if let gamePlayState = context?.stateMachine?.currentState as? IVCircleBombState  {
            gamePlayState.handleTouchMoved(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGamePlayState  {
            gamePlayState.handleTouch(touch)
        }
    }
}
