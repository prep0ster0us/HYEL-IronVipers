
import GameplayKit
import SwiftUI

class IVColorWaveState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var background: SKSpriteNode?
    
    var waveStageCount = 0  // track number of "stages" of waves
    var waveActive: Bool = false
    var generateWave: Bool = false
    
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
        guard let scene, let context else { return }
        print("did enter color wave game state")
        
        setupBackground()
    }
    
    override func willExit(to nextState: GKState) {
        guard let scene else { return }
        waveStageCount = 0
        
        // remove filter and background
        let fadeOutAction = SKAction.fadeOut(withDuration: 2.0)
        let removeAction = SKAction.removeFromParent()
        let removeSequence = SKAction.sequence([fadeOutAction, removeAction])
        
        background?.run(removeSequence)
        
        // reset wave generation flag
        generateWave = true
    }
    
    func setupBackground() {
        guard let scene else {
            return
        }
        addBackgroundFilter()
        let randomPhase = Phase.allCases.randomElement()
        background = SKSpriteNode(color: randomPhase!.color, size: scene.size)
        background?.anchorPoint = CGPointZero
        background?.position = CGPointZero
        background?.zPosition = -2
        background?.alpha = 0.4
        
        scene.addChild(background!)
        scene.background = background
        
        switchBackground()
    }
    func addBackgroundFilter() {
        guard let scene else {
            return
        }
        if let _ = scene.childNode(withName: "filter") {
            return
        }
        let filter = SKSpriteNode(color: .black, size: scene.size)
        filter.name = "filter"
        filter.position = CGPoint(x: scene.size.width / 2.0,
                                  y: scene.size.height / 2.0 )
        filter.alpha = 0.3
        filter.zPosition = -1
        scene.addChild(filter)
    }
    func switchBackground() {
        let waitAction = SKAction.wait(forDuration: 4.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let changePhase = SKAction.run { [self] in
            let currentPhase = Phase.phase(for: background!.color)
            let nextPhase = Phase.random(excluding: currentPhase!)
            background!.color = nextPhase.color
        }
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let changeSequence = SKAction.sequence([waitAction, fadeOut, changePhase, fadeIn])
        background!.run(SKAction.repeatForever(changeSequence))
    }
    
    func addColorWave() {
        guard let scene else { return }
        let spawnWave = SKAction.run { [weak self] in
            self?.createWave()
        }
        
        let waveInterval = SKAction.wait(forDuration: 3.0)
        let waveSequence = SKAction.sequence([spawnWave, waveInterval])
        scene.run(SKAction.repeatForever(waveSequence), withKey: "spawnWaves")
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
        
        for _ in 0..<waveCount {
            // create random positions (without overlap)
            var randomY: CGFloat
            repeat {
                randomY = CGFloat.random(in: 100...scene.size.height-100)
            } while wavePos.contains { abs($0 - randomY) < 50 }  // Avoid overlap by 50 pixels
            wavePos.append(randomY)
            
            // random wave color = different from current background phase
            let wavePhase = Phase.allCases.filter { $0 != Phase.phase(for: background!.color) }.randomElement()!
            let waveColor = wavePhase.color
            
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
            let checkAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                waveActive = false

                waveStageCount += 1
                checkIfEndStage()
            }
            wave.run(SKAction.sequence([moveAction, removeAction, checkAction]))
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
    func updateHealth() {
        guard let context else {
            return
        }
        if context.gameInfo.health <= context.gameInfo.testHealth {
            print("no HP left")
            context.stateMachine?.enter(IVGameOverState.self)
        }
//        else {
//            // update health
//            context.gameInfo.health -= context.gameInfo.wavePenalty
//            if let healthLabel = scene.childNode(withName: "healthNode") as? SKLabelNode {
//                healthLabel.text = "HP: \(context.gameInfo.health)"
//                scaleLabel(for: healthLabel)
//            }
//        }
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
            // Transition to the next game state after the label disappears
            context.stateMachine?.enter(IVGamePlayState.self)
        }
    }

    func createWave() {
        guard let scene else { return }
        
        // wave color = different from current background phase
        let wavePhase = Phase.allCases.filter { $0 != Phase.phase(for: background!.color) }.randomElement()!
        let waveColor = wavePhase.color
        
        // wave position
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
        let waveY = CGFloat.random(in: 100...scene.size.height - 100)  // Random Y-position
        
        // create wave node
        let wave = SKSpriteNode(color: waveColor,
                                size: CGSize(width: 100, height: 30) )
        wave.position = CGPoint(x: startX, y: waveY)
        wave.alpha = 0.6  // Slight transparency for effect
        wave.name = "colorWave"
        
        scene.addChild(wave)
        
        let moveAction = SKAction.moveTo(x: endX, duration: 4.0)
        let removeAction = SKAction.removeFromParent()              // remove
        wave.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func detectPlayerContact() {
        guard let scene else { return }
        scene.enumerateChildNodes(withName: "colorWave") { node, _ in
            if let wave = node as? SKSpriteNode {
                let waveFrame = wave.frame.insetBy(dx: -10, dy: -10)  // Slightly larger frame for contact detection
                if waveFrame.contains(scene.player!.position) {
                    self.playerHitByWave()
                }
            }
        }
    }
    func playerHitByWave() {
        guard let scene, let context else { return }
        // Decrease HP only if the player isn't already in the wave
        context.gameInfo.health -= context.gameInfo.wavePenalty
        if let healthLabel = scene.childNode(withName: "healthNode") as? SKLabelNode {
            healthLabel.text = "HP: \(context.gameInfo.health)"
        }
        
        // Optional: Add a flash effect on the player when hit
        let flash = SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.fadeIn(withDuration: 0.1)])
        scene.player!.run(SKAction.repeat(flash, count: 3))

        if context.gameInfo.health < context.gameInfo.testHealth {
            context.stateMachine?.enter(IVGameOverState.self)
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
