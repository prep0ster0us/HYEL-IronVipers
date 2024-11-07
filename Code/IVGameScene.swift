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
    var player: IVShipNode?                           // store reference for (main) player model
                                                    // TODO: add/create references for all necessary elements/models
    var background: IVBackgroundNode
    var scrollBackground: IVBackgroundNode
    
    var gameState: IVGamePlayState?
    
    init(context: IVGameContext, size: CGSize) {    // initializing (general)
        self.context = context                      // set game context
        self.background = IVBackgroundNode()
        self.scrollBackground = IVBackgroundNode()
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
        prepareBackground()
        prepareStartNodes()                         // helper method to start adding elements/models on the screen
        
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
    
    func prepareBackground() {
        guard let context else {
            return
        }
        // add background
        background.setup(screenSize: size, layoutInfo: context.layoutInfo)
        
        addChild(background)
        
        // add a scrolling background
        scrollBackground.setup(screenSize: size, layoutInfo: context.layoutInfo)
        scrollBackground.background.position = CGPointMake(0, scrollBackground.background.size.height-1)
        
        addChild(scrollBackground)
    }
    
    func prepareStartNodes() {
        guard let context else {
            return
        }
        
        // get center position on the screen (to position the ship model)
        // TODO: need not be centered at the start; discuss more about starting positions for initial elements/models
        let center = CGPoint(x: size.width / 2.0,
                             y: size.height / 6.0)  // **testing
        
        // create node object (to be added to the screen)
        let player = IVShipNode()
        player.setup(screenSize: size, layoutInfo: context.layoutInfo)
        player.name = "playerNode"
        player.position = center
        player.zPosition = 2          // place behind other nodes (down the z-axis)
        
        // setup physics body (to check contact with enemy projectiles)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.ship.size)
        player.physicsBody?.categoryBitMask = IVGameInfo.player
        player.physicsBody?.contactTestBitMask = IVGameInfo.enemyProjectile
        player.physicsBody?.collisionBitMask = IVGameInfo.none
        player.physicsBody?.affectedByGravity = false           // handle repositioning manually

        addChild(player)              // add node to the screen
        self.player = player            // track reference
        preparePlayerAnim()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Set synced scroll movement (background shifts down, scrollBackground moves down in-place)
        let backgroundNode = self.background.background
        backgroundNode.position = CGPoint(
            x: backgroundNode.position.x,
            y: backgroundNode.position.y - (context?.layoutInfo.scrollSpeed)!
        )
        let scrollBackgroundNode = self.scrollBackground.background
        scrollBackgroundNode.position = CGPoint(
            x: scrollBackgroundNode.position.x,
            y: scrollBackgroundNode.position.y - (context?.layoutInfo.scrollSpeed)!
        )
        
        // Reset to beginning after ran through the background image height (to loop infinitely)
        if backgroundNode.position.y < -backgroundNode.size.height {
            backgroundNode.position = CGPoint(
                x: backgroundNode.position.x,
                y: scrollBackgroundNode.position.y + scrollBackgroundNode.size.height
            )
        }
        if scrollBackgroundNode.position.y < -scrollBackgroundNode.size.height {
            scrollBackgroundNode.position = CGPoint(
                x: scrollBackgroundNode.position.x,
                y: backgroundNode.position.y + backgroundNode.size.height
            )
        }
        
        // shoot projectiles (from player)
        if(context?.stateMachine?.currentState is IVGamePlayState) {
            gameState?.shootPlayerProjectiles()
            gameState?.resetPlayerProjectiles()
            
            if childNode(withName: "enemyNode") != nil {
                gameState?.shootEnemyProjectiles()
                gameState?.resetEnemyProjectiles()
            } else {
                gameState?.spawnEnemy()
            }
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let context else {
            return
        }
        let contactA = contact.bodyA
        let contactB = contact.bodyB

        // Player projectile hits enemy
        if (contactA.categoryBitMask == IVGameInfo.playerProjectile && contactB.categoryBitMask == IVGameInfo.enemy) ||
           (contactA.categoryBitMask == IVGameInfo.enemy && contactB.categoryBitMask == IVGameInfo.playerProjectile)
        {
            print("Enemy hit by player projectile")
            
            // remove enemy (with fade animation)
            let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            let collisionSequence = SKAction.sequence([fadeOutAction, removeAction])
            
            childNode(withName: "enemyNode")?.run(collisionSequence)        // reset enemy node
            childNode(withName: "enemyLaser")?.run(collisionSequence)       // reset enemy projectile
            
            gameState?.enemyProjectile = nil    // reset reference to enemy projectile
            
            // update game score
            context.gameInfo.score += 1
            // update score label
            gameState?.updateScore()
        }

        // Enemy projectile hits player
        if (contactA.categoryBitMask == IVGameInfo.enemyProjectile && contactB.categoryBitMask == IVGameInfo.player) ||
           (contactA.categoryBitMask == IVGameInfo.player && contactB.categoryBitMask == IVGameInfo.enemyProjectile)
        {
            print("Player hit by enemy projectile")
            // update game score
            context.gameInfo.health -= 1
            // update score label
            gameState?.updateHealth()
            
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
