import GameplayKit
import SwiftUI

class IVCircleBombState: GKState {
    
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    var damageTimers: [SKShapeNode: Timer] = [:]  // Track timers for each bomb
    
    init(scene: IVGameScene, context: IVGameContext) {
        self.scene = scene
        self.context = context
        super.init()                // retain the properties from the parent/global state
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    override func didEnter(from previousState: GKState?) {
        guard let scene, let context else { return }
        print("did enter laser game state")
        
        // switch background to manual switching
        BackgroundManager.shared.toggleMode(toAutomatic: false)
        
        // Set up CircleBombManager and start waves
        CircleBombManager.shared.setup(scene, context, maxWaves: 2)
        CircleBombManager.shared.startWaves(bombsPerWave: 3) { [weak self] in
            self?.showStageCleared()
        }
        
    }
    override func willExit(to nextState: GKState) {
        // switch back to automatic background switching
        BackgroundManager.shared.toggleMode(toAutomatic: true)
    }
    
    /* HELPER METHODS */

    func showStageCleared() {
        guard let scene, let context else { return }

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
        
        let popupSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown, wait, fadeOut, removeLabel])
        
        label.run(popupSequence) {
            // navigate back to "normal" game play
            context.stateMachine?.enter(IVGamePlayState.self)
        }
    }
    
    func detectPlayerContact() {
        guard let scene, let context else { return }
        scene.enumerateChildNodes(withName: "colorBomb") { node, _ in
            if let bomb = node as? SKShapeNode,
               let player = scene.player {
                if bomb.fillColor == context.gameInfo.bgColor {
                    return
                }
                let distance = hypot(player.position.x - bomb.position.x, player.position.y - bomb.position.y)
                let bombRadius = bomb.frame.width / 2  // Bomb radius from its size
                
                if distance <= bombRadius {
                    print("player inside bomb")
                    // Player is inside the circle bomb
                    self.startDamage(for: bomb)
                } else {
                    // Player is outside the circle bomb
                    self.stopDamage(for: bomb)
                }
            }
        }
    }
    func startDamage(for bomb: SKShapeNode) {
        if damageTimers[bomb] != nil { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.playerHitByBomb(for: bomb)
        }
        damageTimers[bomb] = timer
    }
    func stopDamage(for bomb: SKShapeNode) {
        if let timer = damageTimers[bomb] {
            timer.invalidate()
            damageTimers.removeValue(forKey: bomb)
        }
    }
    func playerHitByBomb(for bomb: SKShapeNode) {
        guard let scene, let context else { return }
        // Decrease HP only if the player isn't already in the wave
        updateHealth(penalty: context.gameInfo.bombPenalty)
        
        let flash = SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.fadeIn(withDuration: 0.1)])
        let flashRepeat = SKAction.repeat(flash, count: 3)
        
        let moveRight = SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        let moveLeft = SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        let shiverSequence = SKAction.sequence([moveRight, moveLeft])
        let shiverRepeat = SKAction.repeat(shiverSequence, count: 5)
        
        scene.player!.run(SKAction.group([flashRepeat, shiverRepeat]))

        if context.gameInfo.health < context.gameInfo.testHealth {
            print("no HP left")
            stopDamage(for: bomb)
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
