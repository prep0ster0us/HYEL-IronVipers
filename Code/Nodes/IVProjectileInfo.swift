import Foundation

struct IVProjectileInfo {
    var imageName: String = "enemy-projectile"
    var speed: CGFloat = 200
    var damage: Int32 = 1
    var collisionType: CollisionType = CollisionType.playerProj
}
