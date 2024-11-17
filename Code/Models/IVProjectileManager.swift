import SpriteKit

class ProjectileManager {
    static let shared = ProjectileManager()  // Singleton instance

    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    private var maxProjectiles: Int = 1
    private var projectileSpeed: TimeInterval = 2.0
    private let projectileColors: [String] = ["RedParticle", "GreenParticle", "BlueParticle"]

    private init() {}

    func setup(_ scene: IVGameScene,_ context: IVGameContext, initialMaxProjectiles: Int = 1, initialSpeed: TimeInterval = 2.0) {
        self.scene = scene
        self.context = context
        self.maxProjectiles = initialMaxProjectiles
        self.projectileSpeed = initialSpeed
    }

    func spawnProjectiles() {
        guard let scene else { return }

        for _ in 0..<maxProjectiles {
            let projectile = createProjectile()
            scene.addChild(projectile)

            // Move the projectile
            let moveAction = SKAction.move(to: projectile.userData?["exitPoint"] as! CGPoint, duration: projectileSpeed)
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([moveAction, removeAction])
            projectile.run(sequence)
        }
    }

    func createProjectile() -> SKEmitterNode {
        let colorName = projectileColors.randomElement()!
        let emitter = SKEmitterNode(fileNamed: colorName)!

        // Randomize spawn and exit points
        let spawnPoint = randomSpawnPoint()
        let exitPoint = randomExitPoint(from: spawnPoint)

        emitter.position = spawnPoint
        emitter.zPosition = 3
        emitter.particleColor = colorName == "RedParticle" ? .red : (colorName == "GreenParticle" ? .green : .blue)

        // Save exitPoint in userData for the movement action
        emitter.userData = ["exitPoint": exitPoint]

        // Configure physics
        emitter.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 25,
                                                                height: 25) )
        emitter.physicsBody?.categoryBitMask = IVGameInfo.projectileMask[colorName]!
        emitter.physicsBody?.contactTestBitMask = IVGameInfo.player
        emitter.physicsBody?.collisionBitMask = IVGameInfo.none
        emitter.physicsBody?.affectedByGravity = false

        return emitter
    }

    func randomSpawnPoint() -> CGPoint {
        guard let scene = scene else { return .zero }
        let direction = CGFloat.random(in: 0...1)

        if direction < 0.5 {
            // left --> right
            let y = CGFloat.random(in: 50...(scene.size.height - 50))
            return CGPoint(x: -75, y: y)
        } else {
            // top --> bottom
            let x = CGFloat.random(in: 50...(scene.size.width - 50))
            return CGPoint(x: x, y: scene.size.height + 75)
        }
    }

    func randomExitPoint(from spawnPoint: CGPoint) -> CGPoint {
        guard let scene = scene else { return .zero }

        if spawnPoint.x < 0 {
            // exit from right edge of the screen
            let y = CGFloat.random(in: 25...(scene.size.height - 25))
            return CGPoint(x: scene.size.width + 50, y: y)
        } else {
            // exit from bottom of the screen
            let x = CGFloat.random(in: 25...(scene.size.width - 25))
            return CGPoint(x: x, y: -50)
        }
    }

    func increaseDifficulty(projectileCount: Int, speed: TimeInterval) {
        maxProjectiles = projectileCount
        projectileSpeed = speed
    }
}
