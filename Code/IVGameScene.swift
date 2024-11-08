/// #TEMPLATE FILE

/**
 Main screen seen by the player
 Most of the core logic goes in here (or reference some core logic from a different game scene)
 This is the engine which powers the whole game
*/


import SpriteKit
import GameplayKit

class IVGameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var context: IVGameContext?                // get game-specific context
                                                    // TODO: add/create references for all necessary elements/models
    
    var gameState: IVGamePlayState?
    var player: SKSpriteNode?                           // store reference for (main) player model
    var background: SKSpriteNode?
    
    // time variables
    private var lastUpdateTime: TimeInterval = 0
    private var deltaTime: TimeInterval = 0
    private var actionInterval: TimeInterval = 1.0
    private var timeSinceLastAction: TimeInterval = 0
    
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
        gameState = IVGamePlayState(scene: self, context: context)
    
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
        
        // shoot projectiles (from player)
        if let currentState = context.stateMachine?.currentState as? IVGamePlayState {
            print("came here")
            
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
                gameState?.spawnProjectile()
                timeSinceLastAction = 0 // Reset the timer
            }
            
        }
        if let currentState = context.stateMachine?.currentState as? IVMainMenuState {
            currentState.randomizeDummyPlayerMovement()
        }
    
    }
    func getDistance(_ direction: String, _ distance: CGFloat) -> CGFloat {
        return direction.elementsEqual("left") ? -distance : distance
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
    
    func scaleScoreLabel() {
        guard let scene else {
            return
        }
        if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode {
            let scaleUp = SKAction.scale(to: 1.4, duration: 0.5)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
            scoreLabel.run(scaleSequence)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("in contact")
        guard let scene, let context else {
            return
        }
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        guard let currentPhase = Phase.phase(for: background!.color) else {
            print(background as Any)
            print(gameState?.background as Any)
            return
        }
        
        let currentParticle = IVGameInfo.particleName[currentPhase]
        let currentProjectileMask = IVGameInfo.projectileMask[currentParticle!]
        //        let matchingProjectileMask = IVGameInfo.projectileMask[IVGameInfo.particleName[currentPhase!]!]
        
        //        let playerBody = contactA.categoryBitMask == IVGameInfo.player ? contactA : contactB
        //        let projectileBody = contactA.categoryBitMask == currentProjectileMask! ? contactA : contactB
        
        
        if (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask == currentProjectileMask) ||
            (contactA.categoryBitMask == currentProjectileMask && contactB.categoryBitMask == IVGameInfo.player) {
            
            // same colored
//            guard let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode else {
//                return
//            }
            context.gameInfo.score += 1
            if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode {
                scoreLabel.text = "Score: \(context.gameInfo.score)"
            }
            scaleScoreLabel()
            
            // Handle enemy hit by player projectile
            print("hit same color projectile")
            
            if let projectile = (contactA.categoryBitMask == IVGameInfo.player) ? contactB.node : contactA.node {
                // Remove projectile nodes
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
                let removeAction = SKAction.removeFromParent()
                let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
                projectile.run(removeSequence)
            }
        }
        
        if (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask != currentProjectileMask) ||
            (contactA.categoryBitMask != currentProjectileMask && contactB.categoryBitMask == IVGameInfo.player) {
            
            // hit different color projectile
//            guard let scoreLabel = childNode(withName: "scoreNode") as? SKLabelNode else {
//                return
//            }
            context.gameInfo.score -= 1
            if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode {
                scoreLabel.text = "Score: \(context.gameInfo.score)"
            }
            
            // Handle enemy hit by player projectile
            print("hit different color projectile")
            
            if let projectile = (contactA.categoryBitMask == IVGameInfo.player) ? contactB.node : contactA.node {
                // Remove projectile nodes
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
                let removeAction = SKAction.removeFromParent()
                let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
                projectile.run(removeSequence)
            }
        }
    }
    
//    func didBegin(_ contact: SKPhysicsContact) {
//        guard let context else {
//            return
//        }
//        let contactA = contact.bodyA
//        let contactB = contact.bodyB
//
//        // Player projectile hits enemy
//        if (contactA.categoryBitMask == IVGameInfo.playerProjectile && contactB.categoryBitMask == IVGameInfo.enemy) ||
//           (contactA.categoryBitMask == IVGameInfo.enemy && contactB.categoryBitMask == IVGameInfo.playerProjectile)
//        {
//            print("Enemy hit by player projectile")
//            
//            // remove enemy (with fade animation)
//            let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
//            let removeAction = SKAction.removeFromParent()
//            let collisionSequence = SKAction.sequence([fadeOutAction, removeAction])
//            
//            childNode(withName: "enemyNode")?.run(collisionSequence)        // reset enemy node
//            childNode(withName: "enemyLaser")?.run(collisionSequence)       // reset enemy projectile
//            
//            gameState?.enemyProjectile = nil    // reset reference to enemy projectile
//            
//            // update game score
//            context.gameInfo.score += 1
//            // update score label
//            gameState?.updateScore()
//        }
//
//        // Enemy projectile hits player
//        if (contactA.categoryBitMask == IVGameInfo.enemyProjectile && contactB.categoryBitMask == IVGameInfo.player) ||
//           (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask == IVGameInfo.enemyProjectile)
//        {
//            print("Player hit by enemy projectile")
//            // update game score
//            context.gameInfo.health -= 1
//            // update score label
//            gameState?.updateHealth()
//            
//        }
//    }
    
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
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGameOverState  {
            gamePlayState.handleTouch(touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        if let gamePlayState = context?.stateMachine?.currentState as? IVGamePlayState  {
            gamePlayState.handleTouch(touch)
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
