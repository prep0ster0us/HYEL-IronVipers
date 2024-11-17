import GameplayKit
import SpriteKit

class IVDemoState: GKState {
    
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var handNode: SKSpriteNode?
    var background: SKSpriteNode?
    var isTapReady: Bool = false
    
    init(scene: IVGameScene, context: IVGameContext) {
        self.scene = scene
        self.context = context
        super.init()                // retain the properties from the parent/global state
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    override func didEnter(from previousState: GKState?) {
        print("did enter main game state")
        
        guard let scene = scene else { return }
        
        // add background
        let background = SKSpriteNode(color: .black, size: scene.size)
        background.alpha = 0.4
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        background.zPosition = -2
        background.name = "demoBG"
        scene.addChild(background)
        
        // Add tutorial instructions
        let demoLabel = SKLabelNode(text: "Drag to move your player")
        demoLabel.fontSize = 32
        demoLabel.fontColor = .white
        demoLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 1.3)
        demoLabel.name = "demoLabel"
        scene.addChild(demoLabel)
        
        // Add a hand sprite to show drag gesture
        let handTexture = SKTexture(imageNamed: "hand")  // Add a "hand" image to Assets
        let handNode = SKSpriteNode(texture: handTexture)
        handNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 5)
        handNode.setScale(0.6)
        handNode.name = "handNode"
        scene.addChild(handNode)
        self.handNode = handNode
        
        // Add hand drag animation
        let dragAction = createHandDragAnimation()
        handNode.run(SKAction.repeatForever(dragAction))
        
        // Add tutorial instructions
        let instructionLabel = SKLabelNode(text: "Avoid obstacles with DIFFERENT color")
        instructionLabel.fontSize = 32
        instructionLabel.fontColor = .yellow
        instructionLabel.alpha = 0  // Start invisible
        instructionLabel.setScale(0)  // Start at zero scale for pop-up effect
        instructionLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 1.8)
        instructionLabel.name = "instructionLabel1"
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.numberOfLines = 3
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.preferredMaxLayoutWidth = scene.size.width-150
        scene.addChild(instructionLabel)
        
        // Define actions: fade in, scale up (pop-up effect), wait, and fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 1.0)
        
        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait])
        
        // Run the pop-up sequence on the label
        instructionLabel.run(popupSequence) {
            self.nextLabel()
        }
        
        isTapReady = false
    }
    func nextLabel() {
        guard let scene else { return }
        // Add tutorial instructions
        let instructionLabel = SKLabelNode(text: "Collect obstacles with SAME color")
        instructionLabel.fontSize = 32
        instructionLabel.fontColor = .yellow
        instructionLabel.alpha = 0  // Start invisible
        instructionLabel.setScale(0)  // Start at zero scale for pop-up effect
        instructionLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2.4)
        instructionLabel.name = "instructionLabel2"
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.numberOfLines = 2
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.preferredMaxLayoutWidth = scene.size.width-150
        scene.addChild(instructionLabel)
        
        // Define actions: fade in, scale up (pop-up effect), wait, and fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 1.0)      // TODO: change back to 3.0 (shortened for testing)
//        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
//        let removeLabel = SKAction.removeFromParent()

        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait])
        
        // Run the pop-up sequence on the label
        instructionLabel.run(popupSequence) {
            self.showTapToPlayLabel()
        }
    }
    func showTapToPlayLabel() {
        guard let scene else { return }
        // Add tutorial instructions
        let tapLabel = SKLabelNode(text: "TAP TO PLAY")
        tapLabel.fontSize = 24
        tapLabel.fontName = "Century-Gothic-Bold"
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height/11)
        tapLabel.name = "tapToPlayLabel"

        tapLabel.run(SKAction.fadeIn(withDuration: 0.5))  {
            self.isTapReady = true
        }
        scene.addChild(tapLabel)
    }
    
    func createHandDragAnimation() -> SKAction {
        // Animate the hand moving in a drag motion
        let moveRight = SKAction.moveTo(x: 100, duration: 1.5)
        let moveLeft = SKAction.moveTo(x: (scene?.size.width)!-100, duration: 1.5)
        return SKAction.sequence([moveRight, moveLeft])
    }
    
    override func willExit(to nextState: GKState) {
        // Remove the hand and instruction label
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOut, remove])
        scene?.childNode(withName: "demoLabel")?.run(removeSequence)
        scene?.childNode(withName: "instructionLabel1")?.run(removeSequence)
        scene?.childNode(withName: "instructionLabel2")?.run(removeSequence)
        scene?.childNode(withName: "tapToPlayLabel")?.run(removeSequence)
        scene?.childNode(withName: "demoBG")?.run(removeSequence)
        handNode?.run(removeSequence)
        
    }
    
    func handleTouch(_ touch: UITouch) {
        guard let scene, let context else { return }
        guard isTapReady else { return }
        // Transition to the main game state when the user interacts
        print("touched on demo")
        scene.run(SKAction.wait(forDuration: 0.5)) {
            context.stateMachine?.enter(IVGamePlayState.self)
        }
    }
    
}
