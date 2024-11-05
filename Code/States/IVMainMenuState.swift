/**
 Defines a specific game state (properties) and game machine (operations)
*/

import GameplayKit

class IVMainMenuState: GKState {
    
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
        print("did enter main menu state")
        
        guard let scene, let context else {
            return
        }
        
        // add game title
        let titleLabel = SKLabelNode(fontNamed: "Copperplate")
        titleLabel.name = "titleNode"
        titleLabel.text = "Tap to begin"
        titleLabel.fontSize = 56
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: (scene.size.width)/2.0,
                                      y: (scene.size.height)/1.2 )
        
        scene.addChild(titleLabel)
        
        // add enemy space ship(s)
        let enemyShip1 = IVShipNode()
        enemyShip1.setup(screenSize: scene.size, layoutInfo: context.layoutInfo)
        enemyShip1.name = "enemyNode1"
        enemyShip1.position = CGPoint(x: scene.size.width / 2.0,
                                y: scene.size.height / 1.5 )
        enemyShip1.zRotation = .pi
        scene.addChild(enemyShip1)
        
        let enemyShip2 = IVShipNode()
        enemyShip2.setup(screenSize: scene.size, layoutInfo: context.layoutInfo)
        enemyShip2.name = "enemyNode2"
        enemyShip2.position = CGPoint(x: scene.size.width / 4.0,
                                y: scene.size.height / 2.0)
        enemyShip2.zRotation = .pi
        scene.addChild(enemyShip2)
        
        let enemyShip3 = IVShipNode()
        enemyShip3.setup(screenSize: scene.size, layoutInfo: context.layoutInfo)
        enemyShip3.name = "enemyNode3"
        enemyShip3.position = CGPoint(x: scene.size.width / 1.3,
                                y: scene.size.height / 2.0)
        enemyShip3.zRotation = .pi
        scene.addChild(enemyShip3)
        
        prepareEnemyShiver()

    }
    
    func prepareEnemyShiver() {
        guard let scene else {
            return
        }
        let dx = CGFloat.random(in: -5...5)
        let dy = CGFloat.random(in: -5...5)
        // Create a custom shiver action that moves the node up and down slightly
        let shiverUp = SKAction.moveBy(x: dx, y: -dy, duration: 0.6)
        let shiverDown = SKAction.moveBy(x: -dx, y: dy, duration: 0.6)
        let shiverSequence = SKAction.sequence([shiverUp, shiverDown])
        
        // Repeat this sequence indefinitely to create the shiver effect
        for i in 1...3 {
            scene.childNode(withName: "enemyNode\(i)")?.run(SKAction.repeatForever(shiverSequence))
        }
    }
    
    override func willExit(to nextState: GKState) {
        guard let scene else {
            return
        }
        // fade away (and remove) title label
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        scene.childNode(withName: "titleNode")?.run(SKAction.sequence([fadeOutAction, removeAction]))
        for i in 1...3 {
            scene.childNode(withName: "enemyNode\(i)")?.run(SKAction.sequence([fadeOutAction, removeAction]))
        }
        
        // stop idle animation
        scene.childNode(withName: "playerNode")?.removeAction(forKey: "idleAnim")
        // reset player spaceship to center (pre-game start position)
        scene.childNode(withName: "playerNode")?.run(SKAction.moveTo(x: scene.size.width/2.0, duration: 1.5))
    }
    
    
    func handleTouch(_ touch: UITouch) {
        print("Touch triggered, Navigate to main game play state")

        context?.stateMachine?.enter(IVGamePlayState.self)
    }
    
}
