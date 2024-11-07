/**
 Defines the main game play state of the game; wave generation and other core game logic will be defined here
*/

import GameplayKit

class IVGamePlayState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var activeProjectile : SKSpriteNode?
    
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
    }
    
    func shootProjectile() {
        guard let scene else {
            return
        }
        guard activeProjectile == nil else {
            return
        }
        
        let projectile = SKSpriteNode(imageNamed: "bullet-projectile")
        projectile.name = "projectileNode"
        print(projectile.size)
        projectile.size = CGSize(width: 17, height: 32)
        projectile.position = scene.ship!.position
        projectile.zPosition = -1
        
        let shootUpAction = SKAction.moveBy(x: 0, y: 15, duration: 0.01)
        projectile.run(SKAction.repeatForever(shootUpAction))
        
        scene.addChild(projectile)
        activeProjectile = projectile
    }
    
    //alternate version to shoot IVProjectileNode
    func shootProjectileV2(info: IVProjectileInfo, origin: CGPoint, direction: CGVector) {
        guard let scene else {
            return
        }
        
        scene.addChild(IVProjectileNode(info: info, origin: origin, direction: direction))
    }
    
    func checkProjectileOffScreen() {
        guard let scene else {
            return
        }
        if let projectile = activeProjectile, projectile.position.y > scene.size.height {
            print("removed")
            projectile.removeFromParent() // Remove from the scene
            activeProjectile = nil        // Reset the projectile reference
        }
    }
    
    
    func handleTouch(_ touch: UITouch) {
        guard let scene else {
            return
        }
        print("touched main game state")
        // move player to touch location
        scene.ship?.position = touch.location(in: scene)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        print("touch moved")
        // move player to touch location
        scene.ship?.position = touch.location(in: scene)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
    
}
