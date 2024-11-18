/// #TEMPLATE FILE

/**
For storing game session specific info
- total score, level progression, is power-up active
- wave timer, enemy level, enemy spawns
*/


import Foundation
import SpriteKit

struct IVGameInfo {
    var score = 0
    var health = 100
    var testHealth = 0
    var gameEndScore = 0
    var transitionScore = 5
    var projectilePenalty = 5
    var laserPenalty = 10
    var laserReward = 5
    var wavePenalty = 1
    var waveReward = 5
    var waveCount = 7
    var waveStages = 3
    var pathProximity: CGFloat = 30.0
    var bombPenalty = 1
    
    let bgColors: [SKColor] = [.blue, .purple, .orange, .red, .green]
    // TODO: expand to include all properties for the game session
    
    //Difficulty
    static var difficulty: UInt32 = 0   //every X seconds, increase by one
    static var difficulRankUpDelay: CGFloat = 30.0  //5 seconds?
    
    // Physics Body Categories (for collision detection)
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0  // 1

    
    static let redProjectile: UInt32 = 0x1 << 1     // 2
    static let greenProjectile: UInt32 = 0x1 << 2   // 4
    static let blueProjectile: UInt32 = 0x1 << 3    // 8
    
    static let laser: UInt32 = 0x1 << 4             // 16
    
    static let playerProjectile: UInt32 = 0x1 << 5 // 2
    static let enemy: UInt32 = 0x1 << 6        // 4
    static let enemyProjectile: UInt32 = 0x1 << 7 // 8
    
    static let particleName = [
        Phase.RED   : "RedParticle",
        Phase.GREEN : "GreenParticle",
        Phase.BLUE  : "BlueParticle"
    ]
    static let projectileMask = [
        "RedParticle"  : redProjectile,
        "BlueParticle" : blueProjectile,
        "GreenParticle": greenProjectile
    ]
    
    let player = SKSpriteNode(imageNamed: "red-rocket-ship")
    let nodeTexture = [
        Phase.RED.color : "red-rocket-ship",
        Phase.GREEN.color : "green-rocket-ship",
        Phase.BLUE.color : "blue-rocket-ship"
    ]
    var currentPhase: Phase = Phase.RED         // random starting value
    var bgColor: SKColor = Phase.RED.color      // random starting value
    var bgChangeDuration = 6.0
    
    func getProjectileSpeed(for score: Int) -> CGFloat {
        switch IVGameInfo.difficulty {
        case 0...5:
            return 2.0
        case 6...10:
            return 2.5
        case 11...18:
            return 2.0
        case 18...23:
            return 1.3
        case 24...30:
            return 1.0
        default:
            return 0.7
        }
    }
    func getNumberOfProjectiles(for score: Int) -> Int {
        switch IVGameInfo.difficulty {
        case 0...3:
            return 1
        case 4...5:
            return 2
        case 6...10:
            return 3
        case 13...18:
            return 5
        case 18...20:
            return 6
        case 21...25:
            return 7
        default:
            return 9
        }
    }
    
    static func getCurStateInterval() -> TimeInterval {
        switch IVGameInfo.difficulty {
        case 0...10:
            return 90.0
        case 11...20:
            return 72.0
        case 20...25:
            return 54.0
        case 25...32:
            return 45.0
        default:
            return 15.0
        }
    }
}

struct LaserNode {
    var startNode : SKSpriteNode
    var endNode   : SKSpriteNode
    var dottedLine: SKShapeNode
    var laserBeam : SKShapeNode
}

enum Phase : CaseIterable {
    case GREEN
    case RED
    case BLUE
    var color: SKColor {
        switch self {
        case .GREEN:
            return .green
        case .RED:
            return .red
        case .BLUE:
            return .blue
        }
    }
    static func phase(for color: SKColor) -> Phase? {
        return self.allCases.first { $0.color == color }
    }
    static func random(excluding current: Phase) -> Phase {
        // Filter all cases to exclude the current color
        let otherColors = allCases.filter { $0 != current }
        return otherColors.randomElement()!
    }
    static func any() -> Phase {
        return Phase.allCases.randomElement()!
    }
}
