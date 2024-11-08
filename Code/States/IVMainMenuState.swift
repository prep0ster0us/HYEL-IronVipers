/**
 Defines a specific game state (properties) and game machine (operations)
*/

import GameplayKit

class IVMainMenuState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var backgroundNode: SKSpriteNode!
    var dummyPlayers: [SKSpriteNode] = []
    
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
        
        setupTitleLabel()
        setupBackground()
        setupDummyPlayers()
        setupProjectiles()
        
        // TODO: work in progress
    }
    
    func setupTitleLabel() {
        guard let scene else {
            return
        }
        let title = SKLabelNode(text: "Tap to begin")
        title.position = CGPoint(x: scene.size.width/2.0,
                                 y: scene.size.height/1.3 )
        title.fontName = "AvenirNext-Bold"
        title.zPosition = 1
        title.fontColor = .white
        title.name="title"
        
        scene.addChild(title)
    }
    
    func setupBackground() {
        guard let scene, let context else {
            return
        }
        
        let filter = SKSpriteNode(color: .black, size: scene.size)
        filter.name = "filter"
        filter.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 2.0 )
        filter.alpha = 0.4
        filter.zPosition = -1
        scene.addChild(filter)
        
        backgroundNode = SKSpriteNode(color: .blue, size: scene.size)
        backgroundNode.position = CGPoint(x: scene.size.width / 2.0,
                                          y: scene.size.height / 2.0 )
        backgroundNode.alpha = 0.6
        backgroundNode.zPosition = -2
        scene.addChild(backgroundNode)
        
        
        var colorActions: [SKAction] = []
        let colors = context.gameInfo.bgColors
        
        for color in colors {
            let colorizeAction = SKAction.colorize(with: color, colorBlendFactor: 2.0, duration: 2.0)
            colorActions.append(colorizeAction)
        }
        let colorCycle = SKAction.sequence(colorActions)
        backgroundNode.run(SKAction.repeatForever(colorCycle))
    }
    func setupDummyPlayers() {
        guard let scene else {
            return
        }
        for _ in 0..<3 {
            let dummy = SKSpriteNode(imageNamed: "spaceship")
            dummy.position = CGPoint(x: CGFloat.random(in: 5...scene.size.width-5.0),
                                     y: scene.size.height / 6.0)
            dummy.setScale(1.8)
            scene.addChild(dummy)
            dummyPlayers.append(dummy)
        }
    }
    func randomizeDummyPlayerMovement() {
        for dummy in dummyPlayers {
            dummy.run(createRandomMovementAction(for: dummy))
        }
    }
    func createRandomMovementAction(for node: SKSpriteNode) -> SKAction {
        guard let scene else {
            return SKAction()
        }
        let randomX = CGFloat.random(in: -10...10)
        let randomY = CGFloat.random(in: -10...10)
        
        // randomize movement
        let dx = randomX + (node.position.x)
        let dy = randomY + (node.position.y)
        
        let offsetX = (dx < 100) ? -randomX : ((dx > (scene.size.width)-100.0) ? -randomX : randomX)
        let offsetY = (dy < 100) ? -randomY : ((dy > (scene.size.height)-100.0) ? -randomY : randomY)
        
        print("current: \(node.position.x) | random: \(randomX) | newPos: \(dx) | valid? : \(offsetX == randomX)")
        
        let moveAction = SKAction.moveBy(x: offsetX,
                                         y: offsetY,
                                         duration: 3.0 )
        let waitAction = SKAction.wait(forDuration: 0.5)
        return SKAction.sequence([moveAction, waitAction])
    }
    
    func setupProjectiles() {
        let launchProjectileAction = SKAction.run { [weak self] in
            self?.spawnProjectile()
        }
        let delay = SKAction.wait(forDuration: 1.0)
        let launchSequence = SKAction.sequence([launchProjectileAction, delay])
        
        SKAction.repeatForever(launchSequence)
    }
    
    func spawnProjectile() {
        guard let scene else {
            return
        }
        let projectile = SKSpriteNode(color: randomColor(), size: CGSize(width: 10, height: 10))
        
        // Randomly spawn from one of the four edges
        let edge = Int.random(in: 0...3)
        var startPosition: CGPoint
        var endPosition: CGPoint
        
        let size = scene.size
        switch edge {
            case 0: // Left to right
                startPosition = CGPoint(x: 0, y: CGFloat.random(in: 0...size.height))
                endPosition = CGPoint(x: size.width, y: CGFloat.random(in: 0...size.height))
            case 1: // Right to left
                startPosition = CGPoint(x: size.width, y: CGFloat.random(in: 0...size.height))
                endPosition = CGPoint(x: 0, y: CGFloat.random(in: 0...size.height))
            case 2: // Bottom to top
                startPosition = CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
                endPosition = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
            default: // Top to bottom
                startPosition = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
                endPosition = CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
        }
        
        projectile.position = startPosition
        projectile.zPosition = 0
        scene.addChild(projectile)
        
        // Move the projectile to the end position and remove it
        let moveAction = SKAction.move(to: endPosition, duration: 4.0)
        let removeAction = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([moveAction, removeAction]))
    }
    func randomColor() -> SKColor {
        let colors: [SKColor] = [.red, .green, .blue, .yellow, .purple]
        let opacity = CGFloat.random(in: 0...1)
        return colors.randomElement()!.withAlphaComponent(opacity)
    }
    
    
//    
//    func prepareEnemyShiver() {
//        guard let scene else {
//            return
//        }
//        let dx = CGFloat.random(in: -5...5)
//        let dy = CGFloat.random(in: -5...5)
//        // Create a custom shiver action that moves the node up and down slightly
//        let shiverUp = SKAction.moveBy(x: dx, y: -dy, duration: 0.6)
//        let shiverDown = SKAction.moveBy(x: -dx, y: dy, duration: 0.6)
//        let shiverSequence = SKAction.sequence([shiverUp, shiverDown])
//        
//        // Repeat this sequence indefinitely to create the shiver effect
//        for i in 1...3 {
//            scene.childNode(withName: "enemyNode\(i)")?.run(SKAction.repeatForever(shiverSequence))
//        }
//    }
//    
//    override func willExit(to nextState: GKState) {
//        guard let scene else {
//            return
//        }
//        // fade away (and remove) title label
//        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
//        let removeAction = SKAction.removeFromParent()
//        scene.childNode(withName: "titleNode")?.run(SKAction.sequence([fadeOutAction, removeAction]))
//        for i in 1...3 {
//            scene.childNode(withName: "enemyNode\(i)")?.run(SKAction.sequence([fadeOutAction, removeAction]))
//        }
//        
//        // stop idle animation
//        scene.childNode(withName: "playerNode")?.removeAction(forKey: "idleAnim")
//        // reset player spaceship to center (pre-game start position)
//        scene.childNode(withName: "playerNode")?.run(SKAction.moveTo(x: scene.size.width/2.0, duration: 1.5))
//    }
    
    
    func handleTouch(_ touch: UITouch) {
        print("Touch triggered, Navigate to main game play state")
        
        // remove idle state background
        backgroundNode.removeFromParent()
        for dummy in dummyPlayers {
            dummy.removeFromParent()
        }
        scene?.childNode(withName: "filter")?.removeFromParent()
        scene?.childNode(withName: "title")?.removeFromParent()

        context?.stateMachine?.enter(IVGamePlayState.self)
    }
    
}
