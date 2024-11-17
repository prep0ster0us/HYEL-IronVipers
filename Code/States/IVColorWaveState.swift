
import GameplayKit
import SwiftUI

class IVColorWaveState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var waveStageCount = 0  // track number of "stages" of waves
    var waveActive: Bool = false
    var generateWave: Bool = false
    
    var damageTimers: [SKSpriteNode: Timer] = [:]  // Track timers for each wave
    
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
        print("did enter color wave game state")
        
        // switch background to manual switching
        let delay = SKAction.wait(forDuration: 1.0)
        let toggle = SKAction.run{ BackgroundManager.shared.toggleMode(toAutomatic: false) }
        scene?.run(SKAction.sequence([delay, toggle]))
        
        ProjectileManager.shared.toggleSpawn(isActive: false)
        // show stage warning label
        showEntryLabel()
    }
    
    override func willExit(to nextState: GKState) {
        waveStageCount = 0

        // reset wave generation flag
        generateWave = false
        
        // switch background back to automatic switching
        BackgroundManager.shared.toggleMode(toAutomatic: true)
    }
    
    func spawnColorWave() {
        guard let scene, let context else { return }
        guard waveActive == false else {
            return
        }
        guard generateWave == true else {
            return
        }
        waveActive = true
        // Array to keep track of Y-positions to avoid overlap
        var wavePos: [CGFloat] = []
        let waveCount = context.gameInfo.waveCount
        
        for i in 0..<waveCount {
            // create random positions (without overlap)
            var randomY: CGFloat
            repeat {
                randomY = CGFloat.random(in: 100...scene.size.height-100)
            } while wavePos.contains { abs($0 - randomY) < 50 }  // Avoid overlap by 50 pixels
            wavePos.append(randomY)
            
            // random wave color = different from current background phase
//            let waveColor = Phase.any().color
            let waveColor = Phase.random(excluding: context.gameInfo.currentPhase).color
            
            // randonmize spawn (left or right)
            let randomNum = CGFloat.random(in: 0...1)
            let startX: CGFloat
            let endX: CGFloat
            if randomNum < 0.5 {
                startX = -50
                endX = scene.size.width+50      // 50 for deviation offscreen
            } else {
                startX = scene.size.width+50
                endX = -50
            }
            
            // Create wave node
            let wave = SKSpriteNode(color: waveColor, size: CGSize(width: 100, height: 30))
            wave.position = CGPoint(x: startX, y: randomY)  // Start off-screen
            wave.alpha = 0.6
            wave.name = "colorWave"
            scene.addChild(wave)
            
            let moveAction = SKAction.moveTo(x: endX, duration: 3.0)
            let removeAction = SKAction.removeFromParent()
            let switchDelay = SKAction.wait(forDuration: 1.0)
            let switchAction = SKAction.run { BackgroundManager.shared.manuallySwitchBackground() }
            let checkAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                waveActive = false

                waveStageCount += 1
                checkIfEndStage()
            }
            if i == waveCount-1 {
                wave.run(SKAction.sequence([moveAction, removeAction, switchAction, switchDelay, checkAction, SKAction.wait(forDuration: 1.0)]))
            } else {
                wave.run(SKAction.sequence([moveAction, removeAction, checkAction, SKAction.wait(forDuration: 1.0)]))
            }
        
            waveActive = true
        }
    }
    func isFinalStage() -> Bool {
        guard let context else { return false }
        return waveStageCount == (context.gameInfo.waveStages)*(context.gameInfo.waveCount)
    }
    
    func checkIfEndStage() {
        if isFinalStage() {
            print("all wave stages cleared")
            ProjectileManager.shared.toggleSpawn(isActive: false)
            displayStageCleared()
            updateScore()
        }
    }
    func updateScore() {
        guard let scene, let context else {
            return
        }
        if let scoreLabel = scene.childNode(withName: "scoreNode") as? SKLabelNode  {
            // update score
            context.gameInfo.score += context.gameInfo.waveReward
            scoreLabel.text = "Score: \(context.gameInfo.score)"
        }
    }
    func showEntryLabel() {
        guard let scene else { return }
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
            ProjectileManager.shared.toggleSpawn(isActive: true)
            self.generateWave = true
        }
    }
    
    func displayStageCleared() {
        guard let scene, let context else { return }
        generateWave = false
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
        let wait = SKAction.wait(forDuration: 2.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let removeLabel = SKAction.removeFromParent()
        
        // Combine actions in sequence
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait, fadeOut, removeLabel])
        
        // Run the pop-up sequence on the label
        label.run(popupSequence) {
            ProjectileManager.shared.toggleSpawn(isActive: true)
            // go back to main game state
            context.stateMachine?.enter(IVGamePlayState.self)
        }
    }

    func detectPlayerContact() {
        guard let scene, let context else { return }
        scene.enumerateChildNodes(withName: "colorWave") { node, _ in
            if let wave = node as? SKSpriteNode {
                let waveFrame = wave.frame.insetBy(dx: -10, dy: -10)  // Slightly larger frame for contact detection
                if scene.player!.intersects(SKShapeNode(rect: waveFrame)) {
                    // player contact with wave
                    if wave.color == context.gameInfo.bgColor {
                        print("same color wave")
                    } else {
                        self.startDamage(for: wave)
                    }
                } else {
                    // no contact with wave
                    self.stopDamage(for: wave)
                }
            }
        }
    }
    func startDamage(for wave: SKSpriteNode) {
        if damageTimers[wave] != nil { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.playerHitByWave(for: wave)
        }
        damageTimers[wave] = timer
    }
    func stopDamage(for wave: SKSpriteNode) {
        if let timer = damageTimers[wave] {
            timer.invalidate()
            damageTimers.removeValue(forKey: wave)
        }
    }
    func playerHitByWave(for wave: SKSpriteNode) {
        guard let scene, let context else { return }
        // Decrease HP only if the player isn't already in the wave
        updateHealth(penalty: context.gameInfo.wavePenalty)
        
        // flash player model (when hit)
        let flash = SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.fadeIn(withDuration: 0.1)])
        scene.player!.run(SKAction.repeat(flash, count: 3))

        if context.gameInfo.health < context.gameInfo.testHealth {
            print("no HP left")
            stopDamage(for: wave)
            context.stateMachine?.enter(IVGameOverState.self)
        }
    }
    func updateHealth(penalty: Int) {
        guard let scene, let context else {
            return
        }
        context.gameInfo.health -= penalty
        if let healthLabel = scene.childNode(withName: "healthNode") as? SKLabelNode {
            healthLabel.text = "HP: \(context.gameInfo.health)"
        }
        // TODO: update HP based on wave color - exempt background-colored waves
//        else {
//            // update health
//            context.gameInfo.health -= context.gameInfo.wavePenalty
//            if let healthLabel = scene.childNode(withName: "healthNode") as? SKLabelNode {
//                healthLabel.text = "HP: \(context.gameInfo.health)"
//                scaleLabel(for: healthLabel)
//            }
//        }
    }

    
    /* METHODS to handle touch events */
    func handleTouch(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        let location = touch.location(in: scene)
        scene.player?.position = CGPoint(x: location.x-20, y: location.y+20)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        let location = touch.location(in: scene)
        scene.player?.position = CGPoint(x: location.x-20, y: location.y+20)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
}
