import SpriteKit

class BackgroundManager {
    static let shared = BackgroundManager()  // Singleton instance

    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    private var background: SKSpriteNode?
    private var currentColor: SKColor = Phase.RED.color
    private var isAutomatic = true      // Flag for automatic/manual mode
    private var backgroundActionKey = "backgroundCycle"

    private init() {}
    
    func setup(_ scene: IVGameScene,_ context: IVGameContext) {
        self.scene = scene
        self.context = context
        self.currentColor = context.gameInfo.bgColor

        // Create the initial background
        let background = SKSpriteNode(color: currentColor, size: scene.size)
        background.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        background.name = "background"
        scene.addChild(background)
        self.background = background

        if isAutomatic {
            startAutomaticSwitching()
        }
    }

    func startAutomaticSwitching() {
        guard let scene, let context else { return }

        let waitAction = SKAction.wait(forDuration: context.gameInfo.bgChangeDuration)
        let changePhase = SKAction.run {
            self.switchBackground()
        }
        let changeSequence = SKAction.sequence([waitAction, changePhase])
        scene.run(SKAction.repeatForever(changeSequence), withKey: backgroundActionKey)
    }

    func stopAutomaticSwitching() {
        scene?.removeAction(forKey: backgroundActionKey)
    }

    func toggleMode(toAutomatic: Bool) {
        isAutomatic = toAutomatic
        if isAutomatic {
            startAutomaticSwitching()
        } else {
            stopAutomaticSwitching()
        }
    }

    func switchBackground() {
        guard let scene, let context, let background = background else { return }
        
        let nextPhase = Phase.random(excluding: context.gameInfo.currentPhase)
        let nextColor = nextPhase.color
        
        let newBackground = SKSpriteNode(color: nextColor, size: scene.size)
        // Start off-screen (to the left)
        newBackground.position = CGPoint(x: -scene.size.width / 2, y: scene.size.height / 2)
        newBackground.name = "background"
        newBackground.zPosition = -2
        newBackground.alpha = 0.4
        
        scene.addChild(newBackground)

        // Slide-in and slide-out animations
        let slideOut = SKAction.moveTo(x: scene.size.width * 1.5, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        background.run(SKAction.sequence([slideOut, removeAction]))
        
        let slideIn = SKAction.moveTo(x: scene.size.width / 2, duration: 1.0)
        newBackground.run(slideIn) { [weak self] in
            // update color and background reference
            self?.currentColor = nextColor
            self?.background = newBackground
            // track changes for background phase and color
            context.gameInfo.currentPhase = nextPhase
            context.gameInfo.bgColor = nextColor
        }
    }

    func manuallySwitchBackground() {
        guard !isAutomatic else { return }  // Prevent manual switching in automatic mode
        switchBackground()
    }
}
