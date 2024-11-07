/**
 Defines the main game play state of the game; wave generation and other core game logic will be defined here
*/

import GameplayKit

class IVGamePlayState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var playerProjectile : SKSpriteNode?
    var enemyProjectile : SKSpriteNode?
    
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
        
        showHealthBar()
        showScore()
        
        spawnEnemy()
    }
    
    func showHealthBar() {
        guard let scene, let context else {
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
        
        let fadeInAction = SKAction.fadeIn(withDuration: 2.0)
        
        scene.addChild(healthLabel)
        healthLabel.run(fadeInAction)
    }
    func updateHealth() {
        guard let scene, let context else {
            return
        }
        let healthLabel = scene.childNode(withName: "healthNode") as! SKLabelNode
        healthLabel.text = "HP: \(context.gameInfo.health)"
        
        if context.gameInfo.health < 98 {
            context.stateMachine?.enter(IVGameOverState.self)
        }
    }
    
    
    func showScore() {
        guard let scene, let context else {
            return
        }
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: \(context.gameInfo.score)"
        scoreLabel.name = "scoreNode"
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: scene.size.width / 6.0,
                                      y: scene.size.height / 1.08)
        scoreLabel.zPosition = 1
        scoreLabel.alpha = 0.0
        
        let fadeInAction = SKAction.fadeIn(withDuration: 2.0)
        
        scene.addChild(scoreLabel)
        scoreLabel.run(fadeInAction)
    }
    func updateScore() {
        guard let context else {
            return
        }
        let scoreLabel = scene?.childNode(withName: "scoreNode") as! SKLabelNode
        scoreLabel.text = "Score: \(context.gameInfo.score)"
    }
    
    
    
    func spawnEnemy() {
        guard let scene, let context else {
            return
        }
        let enemy = IVShipNode()
        enemy.setup(screenSize: scene.size, layoutInfo: context.layoutInfo)
        enemy.name = "enemyNode"
        enemy.position = CGPoint(x: CGFloat.random(in: 5...scene.size.width-5.0),
                                 y: scene.size.height / 1.4)
        enemy.zRotation = .pi
        
        // setup physics body (to check collision with player's projectiles)
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.ship.size)
        enemy.physicsBody?.categoryBitMask = IVGameInfo.enemy
        enemy.physicsBody?.contactTestBitMask = IVGameInfo.playerProjectile
        enemy.physicsBody?.collisionBitMask = IVGameInfo.none
        enemy.physicsBody?.affectedByGravity = false
    
        let fadeInAction = SKAction.fadeIn(withDuration: 2.0)
        enemy.run(fadeInAction)
        
        scene.addChild(enemy)
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

    
    func shootPlayerProjectiles() {
        guard let scene else {
            return
        }
        guard playerProjectile == nil else {
            return
        }
        
        let projectile = SKSpriteNode(imageNamed: "bullet-projectile")
        projectile.name = "playerProjectileNode"
        projectile.size = CGSize(width: 17, height: 32)
        projectile.position = scene.player!.position
        projectile.zPosition = -1
        
        // setup physics body (to check collision with enemy node)
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.categoryBitMask = IVGameInfo.playerProjectile
        projectile.physicsBody?.contactTestBitMask = IVGameInfo.enemy
        projectile.physicsBody?.collisionBitMask = IVGameInfo.none
        projectile.physicsBody?.affectedByGravity = false
        
        let shootUpAction = SKAction.moveBy(x: 0, y: 15, duration: 0.01)
        projectile.run(SKAction.repeatForever(shootUpAction))
        
        scene.addChild(projectile)
        playerProjectile = projectile
    }
    
    func resetPlayerProjectiles() {
        guard let scene else {
            return
        }
        if let projectile = playerProjectile, projectile.position.y > scene.size.height {
            projectile.removeFromParent() // Remove from the scene
            playerProjectile = nil        // Reset the projectile reference
        }
    }

    
    func shootEnemyProjectiles() {
        guard let scene else {
            return
        }
        guard enemyProjectile == nil else {
            return
        }
        let enemy = scene.childNode(withName: "enemyNode")
        
        let projectile = SKSpriteNode(imageNamed: "bullet-projectile")
        projectile.name = "enemyProjectileNode"
        projectile.size = CGSize(width: 17, height: 32)
        projectile.position = CGPoint(x: enemy!.position.x,
                                      y: enemy!.position.y + 5.0 )
        
        // setup physics body (to check collision with player node)
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.categoryBitMask = IVGameInfo.enemyProjectile
        projectile.physicsBody?.contactTestBitMask = IVGameInfo.player
        projectile.physicsBody?.collisionBitMask = IVGameInfo.none
        projectile.physicsBody?.affectedByGravity = false
        
        let shootUpAction = SKAction.moveBy(x: 0, y: -50, duration: 0.05)
        projectile.run(SKAction.repeatForever(shootUpAction))
        
        scene.addChild(projectile)
        enemyProjectile = projectile
        
        scene.childNode(withName: "enemyNode")!.run(randomizeMovement())
    }
    
    func resetEnemyProjectiles() {
        if let projectile = enemyProjectile, projectile.position.y < 0 {
            projectile.removeFromParent() // Remove from the scene
            enemyProjectile = nil        // Reset the projectile reference
        }
    }
    
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
//        print("touch ended")
    }
    
}
