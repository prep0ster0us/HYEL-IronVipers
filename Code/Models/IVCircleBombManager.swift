import SpriteKit

class CircleBombManager {
    static let shared = CircleBombManager()  // Singleton instance

    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    private var currentBgColor: SKColor = Phase.RED.color
    private var bombs: [SKShapeNode] = []  // Track active bombs
    private var maxWaves: Int = 0
    private var currentWave: Int = 0

    private init() {}

    func setup(_ scene: IVGameScene, _ context: IVGameContext, maxWaves: Int) {
        self.scene = scene
        self.context = context
        self.currentBgColor = context.gameInfo.bgColor
        
        self.maxWaves = maxWaves
        self.currentWave = 0
    }

    func startWaves(bombsPerWave: Int, onWaveComplete: @escaping () -> Void) {
        guard let scene = scene else { return }

        currentWave += 1
        if currentWave > maxWaves {
            onWaveComplete()
            return
        }

        generateBombs(count: bombsPerWave)

        // wait for the bombs to finish, then start the next wave
        let waveDuration: TimeInterval = 5.0
        scene.run(SKAction.sequence([
            SKAction.wait(forDuration: waveDuration),
            SKAction.run { BackgroundManager.shared.manuallySwitchBackground() },    // change background for next "wave"
            SKAction.run { [weak self] in
                self?.clearBombs()
                self?.startWaves(bombsPerWave: bombsPerWave, onWaveComplete: onWaveComplete)
            }
        ]))
    }

    func generateBombs(count: Int) {
        guard let scene, let context else { return }
        
        bombs.removeAll()

        for _ in 0..<count {
            let randomPhase = Phase.random(excluding: context.gameInfo.currentPhase)
            let bombColor = randomPhase.color
            
            let bomb = createBomb(color: bombColor, maxRadius: 75)
            scene.addChild(bomb)
            bombs.append(bomb)
        }
    }

    func createBomb(color: SKColor, maxRadius: CGFloat) -> SKShapeNode {
        guard let scene else { return SKShapeNode() }

        // Random position (ensuring no overlap)
        var position: CGPoint
        repeat {
            position = CGPoint(
                x: CGFloat.random(in: maxRadius...(scene.size.width - maxRadius)),
                y: CGFloat.random(in: maxRadius...(scene.size.height - maxRadius))
            )
        } while bombs.contains { bomb in
            let dx = bomb.position.x - position.x
            let dy = bomb.position.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            return distance < (maxRadius + (bomb.frame.width / 2))  // compare for full scaled bomb size
        }
//        { $0.frame.intersects(CGRect(x: position.x - maxRadius,
//                                                            y: position.y - maxRadius,
//                                                            width: maxRadius*2,
//                                                            height: maxRadius*2)) }

        // Create the bomb shape
        let bomb = SKShapeNode(circleOfRadius: 1)  // Start as a dot
        bomb.position = position
        bomb.fillColor = color
//        bomb.strokeColor = .black  // Add border
        bomb.lineWidth = 0
        bomb.alpha = 0.6
        bomb.name = "colorBomb"

        // Add growth and shrink animations
        let grow = SKAction.repeat(SKAction.scale(by: 2.5, duration: 0.5), count: 5)
        let delay = SKAction.wait(forDuration: 1.5)
        let shrink = SKAction.scale(to: 0.1, duration: 0.5)
        let remove = SKAction.removeFromParent()

        bomb.run(SKAction.sequence([grow, delay, shrink, remove]))
        return bomb
    }

    func clearBombs() {
        for bomb in bombs {
            bomb.removeFromParent()
        }
        bombs.removeAll()
    }
}
