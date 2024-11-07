/// #TEMPLATE FILE

/**
For storing game session specific info
- total score, level progression, is power-up active
- wave timer, enemy level, enemy spawns
*/


import Foundation

struct IVGameInfo {
    var score = 0
    var health = 100
    var testHealth = 95
    // TODO: expand to include all properties for the game session
    
    // Physics Body Categories (for collision detection)
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0  // 1
    static let playerProjectile: UInt32 = 0x1 << 1 // 2
    static let enemy: UInt32 = 0x1 << 2        // 4
    static let enemyProjectile: UInt32 = 0x1 << 3 // 8
}
