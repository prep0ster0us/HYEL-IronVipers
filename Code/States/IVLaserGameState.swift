/**
 Defines the main game play state of the game; wave generation and other core game logic will be defined here
*/

import GameplayKit
import SwiftUI

class IVLaserGameState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var laserNodes: [LaserNode] = []
    var player: SKSpriteNode?
//    var background: SKSpriteNode?
    var stateNodes: [SKSpriteNode] = []
    
    var isHitByLaser: Bool = false
    
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
        print("did enter laser game state")
        
//        setupPlayer()
//        spawnLaserNodes()
//        setupBackground()
        showEntryLabel()

    }
    override func willExit(to nextState: GKState) {
        guard let scene else {
            return
        }
        for laserNodePair in laserNodes {
            laserNodePair.startNode.removeFromParent()
            laserNodePair.endNode.removeFromParent()
        }
        scene.removeAction(forKey: "spawnLaser")
        
        // update score (reward if averted laser)
        updateScore()
    }
    
    func showEntryLabel() {
        guard let scene else { return }
        // Create the SKLabelNode for the pop-up
        let label = SKLabelNode(text: "Avoid the lasers!")
        label.fontSize = 40
        label.fontName = "AmericanTypewriter-Bold"
        label.fontColor = .yellow
        label.position = CGPoint(x: scene.size.width / 2.0,
                                 y: scene.size.height / 2.0 )
        label.alpha = 0  // Start invisible
        label.setScale(0)  // Start at zero scale for pop-up effect
        scene.addChild(label)
        
        // Define actions: fade in, scale up (pop-up effect), wait, and fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let removeLabel = SKAction.removeFromParent()
        
        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait, fadeOut, removeLabel])
        
        // Run the pop-up sequence on the label
        label.run(popupSequence) {
            let spawnLaserAction = SKAction.run { [self] in
                for _ in 0..<3 {
                    spawnLaserNodes()
                }
            }
            let delay = SKAction.wait(forDuration: 5.0)
            let spawnSequence = SKAction.sequence([spawnLaserAction, delay])
            scene.run(spawnSequence, withKey: "spawnLaser")
        }
    }

    func spawnLaserNodes() {
        guard let scene else {
            return
        }
        
        // Define start and end positions based on `position`
        let startPos: CGPoint
        let endPos: CGPoint
        
        // Randomize between vertical and horizontal nodes
        let randomNum = CGFloat.random(in: 0...1)
        switch randomNum<0.5 {
            case true:
                startPos = CGPoint(x: 0, y: CGFloat.random(in: 100...scene.size.height - 100) )   // 100 for offset from screen edge
                endPos = CGPoint(x: scene.size.width, y: startPos.y)
            case false:
                startPos = CGPoint(x: CGFloat.random(in: 100...scene.size.width - 100), y: scene.size.height)
                endPos = CGPoint(x: startPos.x, y: 0)
        }
        
        // Create start and end nodes
        let startNode = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
        startNode.position = startPos
        startNode.alpha = 0
        scene.addChild(startNode)
        
        let endNode = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
        endNode.position = endPos
        endNode.alpha = 0
        scene.addChild(endNode)
        
        // Slide in animation
        let slideInAction = SKAction.fadeIn(withDuration: 2.0)
        startNode.run(slideInAction)
        endNode.run(slideInAction)
        
        createDottedLineAnimation(startNode, endNode)
    
    }
    func createDottedLineAnimation(_ startNode: SKSpriteNode, _ endNode: SKSpriteNode) {
        guard let scene else { return }
        let start = startNode.position
        let end = endNode.position
        // Calculate the distance and angle between the start and end points
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        // Set up dot properties
        let dotSize = CGSize(width: 5, height: 5)
        let dotSpacing: CGFloat = 25  // Distance between each dot
        let dotCount = Int(distance / dotSpacing)
        
        var dots: [SKShapeNode] = []
        
        // Create the dots
        for i in 0..<dotCount {
            let dot = SKShapeNode(circleOfRadius: dotSize.width / 2)
            dot.fillColor = .yellow
            dot.position = CGPoint(
                x: start.x + CGFloat(i) * dotSpacing * cos(angle),
                y: start.y + CGFloat(i) * dotSpacing * sin(angle)
            )
            dot.alpha = 0  // Start with the dot invisible
            
            scene.addChild(dot)
            dots.append(dot)
            
            // Animate the dot's fade-in, fade-out, and repeat it in a sequence
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 1.2)
            let delay = SKAction.wait(forDuration: 0.05 * Double(i))
            let sequence = SKAction.sequence([delay, fadeIn, fadeOut])
            dot.run(SKAction.repeatForever(sequence))
        }
        
        // add delay and switch to laser beam
        let delay = SKAction.wait(forDuration: 4.0)
        let transformToLaser = SKAction.run { [weak self] in
            self?.createLaserBeamAnimation(dots, startNode, endNode)
        }
        scene.run(SKAction.sequence([delay, transformToLaser]))
    }
    func createLaserBeamAnimation(_ dots: [SKShapeNode], _ startNode: SKSpriteNode, _ endNode: SKSpriteNode) {
        guard let scene else { return }
        // Remove all dots
        for dot in dots {
            dot.removeFromParent()
        }
        
        // calculate parameters
        let start = startNode.position
        let end = endNode.position
        // Calculate the distance and angle between the start and end points
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        // Create a thin laser beam shape node initially
        let laserBeam = SKShapeNode(rectOf: CGSize(width: distance, height: 4))
        laserBeam.position = CGPoint(x: (start.x + end.x) / 2.0,
                                     y: (start.y + end.y) / 2.0 )
        laserBeam.zRotation = angle
        laserBeam.strokeColor = .red
        laserBeam.fillColor = .yellow
        laserBeam.alpha = 0
        laserBeam.zPosition = -2
        scene.addChild(laserBeam)
        
        // setup physics body (for collision with player body)
        laserBeam.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 25, height: 25))
        laserBeam.physicsBody?.categoryBitMask = IVGameInfo.laser
        laserBeam.physicsBody?.contactTestBitMask = IVGameInfo.player
        laserBeam.physicsBody?.collisionBitMask = IVGameInfo.none
        laserBeam.physicsBody?.affectedByGravity = false
        laserBeam.physicsBody?.isDynamic = false
        
        // Animate the laser beam growing in thickness
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let expand = SKAction.resize(toHeight: 20, duration: 0.5) // Expands from 2 to 20 in height
        let group = SKAction.group([fadeIn, expand])
        laserBeam.run(group)
        
        let delay = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.5)
        let remove = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([delay, fadeOut, remove])
        startNode.run(removeSequence)
        endNode.run(removeSequence)
        laserBeam.run(removeSequence) { [weak self] in
            // Once the last laser beam has faded, display the label
            self?.showSuccessLabel()
        }
        
    }
    func showSuccessLabel() {
        guard let scene else { return }
        // Create the SKLabelNode for the pop-up
        let label = SKLabelNode(text: "Danger Averted!")
        label.fontSize = 40
        label.fontColor = .yellow
        label.position = CGPoint(x: scene.size.width / 2.0,
                                 y: scene.size.height / 2.0 )
        label.alpha = 0  // Start invisible
        label.setScale(0)  // Start at zero scale for pop-up effect
        scene.addChild(label)
        
        // Define actions: fade in, scale up (pop-up effect), wait, and fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let removeLabel = SKAction.removeFromParent()
        
        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait, fadeOut, removeLabel])
        
        // Run the pop-up sequence on the label
        label.run(popupSequence) {
            let delay = SKAction.wait(forDuration: 0.5)
            let show = SKAction.run {
                self.showNextGameLabel()
            }
            scene.run(SKAction.sequence([delay, show]))
        }
    }
    func showNextGameLabel() {
        guard let scene, let context else { return }
        // Create the SKLabelNode for the pop-up
        let label = SKLabelNode(text: "Survive the waves!")
        label.fontSize = 36
        label.fontName = "AmericanTypewriter-Bold"
        label.fontColor = .yellow
        label.position = CGPoint(x: scene.size.width / 2.0,
                                 y: scene.size.height / 2.0 )
        label.alpha = 0  // Start invisible
        label.setScale(0)  // Start at zero scale for pop-up effect
        scene.addChild(label)
        
        // Define actions: fade in, scale up (pop-up effect), wait, and fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let removeLabel = SKAction.removeFromParent()
        
        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait, fadeOut, removeLabel])
        
        // Run the pop-up sequence on the label
        label.run(popupSequence) {
            // Transition to the next game state after the label disappears
            context.stateMachine?.enter(IVColorWaveState.self)
        }
    }
    
    func updateScore() {
        guard let context else { return }
        if self.isHitByLaser {
            context.gameInfo.score += context.gameInfo.laserReward
            // update score label
            if let scoreLabel = scene?.childNode(withName: "scoreNode") as? SKLabelNode {
                scoreLabel.text = "Score: \(context.gameInfo.score)"
            }
        }
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
