import SpriteKit

class ProjectileManager {
    static let shared = ProjectileManager()  // Singleton instance

    weak var scene: IVGameScene?
    weak var context: IVGameContext?

    private let projectileColors: [String] = ["RedParticle", "GreenParticle", "BlueParticle"]
    private var spawnFlag: Bool = true

    private init() {}

    func setup(_ scene: IVGameScene,_ context: IVGameContext) {
        self.scene = scene
        self.context = context
    }
    
    func toggleSpawn(isActive: Bool) {
        spawnFlag = isActive
    }

    func spawnProjectiles(_ elapsedTime: TimeInterval) {
        guard let scene else { return }
        guard spawnFlag == true else { return }

        // adjust speed and count based on elapsed game time
        let baseSpeed: TimeInterval = 2.0
        let minSpeed: TimeInterval = 0.6
        let currentSpeed = max(baseSpeed - (elapsedTime / 65.0), minSpeed) // Gradually decrease speed
        // reduce by 0.2 every 13seconds ***
        
        let baseCount = 1
        let maxCount = 5
        let currentCount = min(baseCount + Int(elapsedTime / 65.0), maxCount) // Gradually increase count
        // reduce by 0.2 every 13seconds ***
        
        for _ in 0..<currentCount {
            let projectile = createProjectile()
            scene.addChild(projectile)

            // Move the projectile
            let moveAction = SKAction.move(to: projectile.userData?["exitPoint"] as! CGPoint, duration: currentSpeed)
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
        
        // TODO: got the shooting angle working; just need to figure out the size of projectile head
//        // get angle of movement
//        let dx = exitPoint.x - spawnPoint.x
//        let dy = exitPoint.y - spawnPoint.y
//        let angle = atan2(dy, dx)
//        // Configure particle behavior
//        emitter.particleBirthRate = 50  // Adjust for denser trails
//        emitter.particleLifetime = 1.0  // Short lifetime for concise trails
//        emitter.particleSpeed = 100     // Speed of the particles
//        emitter.particleSpeedRange = 20 // Add some variation
//        emitter.emissionAngle = angle + .pi  // Emit backward (relative to emitter's rotation)
//        emitter.emissionAngleRange = .pi / 8  // Slight spread for a natural look
//        
//        // Add other visual adjustments
//        emitter.particleAlpha = 0.8
//        emitter.particleAlphaRange = 0.2
//        emitter.particleScale = 0.5
//        emitter.particleScaleRange = 0.4

        return emitter
    }

    func randomSpawnPoint() -> CGPoint {
        guard let scene = scene else { return .zero }
        // Randomly pick one of the four edges of the screen
        let edge = Int.random(in: 0..<4)
        
        switch edge {
        case 0: // Left edge
            let y = CGFloat.random(in: 50...(scene.size.height - 50))
            return CGPoint(x: -75, y: y)
        case 1: // Right edge
            let y = CGFloat.random(in: 50...(scene.size.height - 50))
            return CGPoint(x: scene.size.width + 75, y: y)
        case 2: // Top edge
            let x = CGFloat.random(in: 50...(scene.size.width - 50))
            return CGPoint(x: x, y: scene.size.height + 75)
        case 3: // Bottom edge
            let x = CGFloat.random(in: 50...(scene.size.width - 50))
            return CGPoint(x: x, y: -75)
        default:
            return .zero
        }
    }

    func randomExitPoint(from spawnPoint: CGPoint) -> CGPoint {
        guard let scene = scene else { return .zero }

        // Ensure the exit point is on a different edge than the spawn point
        if spawnPoint.x < 0 { // Spawned from left edge
            // exit on right
            let y = CGFloat.random(in: 25...(scene.size.height - 25))
            return CGPoint(x: scene.size.width + 50, y: y)
        } else if spawnPoint.x > scene.size.width { // Spawned from right edge
            // exit on left
            let y = CGFloat.random(in: 25...(scene.size.height - 25))
            return CGPoint(x: -50, y: y)
        } else if spawnPoint.y > scene.size.height {
            // exit from bottom
            let x = CGFloat.random(in: 25...(scene.size.width - 25))
            return CGPoint(x: x, y: -50)
        } else { // Spawned from bottom edge
            // exit from top
            let x = CGFloat.random(in: 25...(scene.size.width - 25))
            return CGPoint(x: x, y: scene.size.height + 50)
        }
    }

}
