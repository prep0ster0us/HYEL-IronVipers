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
        
        spawnEnemy()
    }
    
    func spawnEnemy() {
        guard let scene, let context else {
            return
        }
        let enemy = IVShipNode()
        enemy.setup(screenSize: scene.size, layoutInfo: context.layoutInfo)
        enemy.name = "enemyNode"
        enemy.position = CGPoint(x: CGFloat.random(in: 5...scene.size.width-5.0),
                                 y: scene.size.height / 1.2)
        enemy.zRotation = .pi
    
        let fadeInAction = SKAction.fadeIn(withDuration: 2.0)
        enemy.run(fadeInAction)
        
        scene.addChild(enemy)
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
        print(projectile.size)
        projectile.size = CGSize(width: 17, height: 32)
        projectile.position = scene.player!.position
        projectile.zPosition = -1
        
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
        
        let shootUpAction = SKAction.moveBy(x: 0, y: -10, duration: 0.01)
        projectile.run(SKAction.repeatForever(shootUpAction))
        
        scene.addChild(projectile)
        enemyProjectile = projectile
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
        print("touched main game state")
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        print("touch moved")
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
    
}
