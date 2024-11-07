import SpriteKit
import GameplayKit

enum CollisionType: UInt32 {
    case player = 1
    case enemy = 2
    case playerProj = 4
    case enemyProj = 8
    case borderContact = 16
}


class IVProjectileNode : SKSpriteNode, SKPhysicsContactDelegate
{
    var velocity: CGVector = CGVector()
    var damage: Int32 = 0
    var collisionType: CollisionType = CollisionType.playerProj
    
    init(info: IVProjectileInfo, origin: CGPoint, direction: CGVector) {
        self.collisionType = info.collisionType
        self.damage = info.damage
        
        let len = hypot(direction.dx, direction.dy)
        self.velocity = CGVector(
            dx: (direction.dx/len) * info.speed,
            dy: (direction.dy/len) * info.speed
        )
        
        //super.init(texture: texture, color: color, size: size)
        super.init(texture: SKTexture(imageNamed: info.imageName), color: .white, size: CGSize(width: 15, height: 15))
        self.position = origin
        
        //sprite attributes
        self.size = CGSize(width: 17, height: 32)
        self.zPosition = -1
        
        applyPhysics()
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) not implemented")
    }
    
    //OnCollide
    func didBegin(_ contact: SKPhysicsContact) {
        print("Contact Triggered!")
    }
    
    
    //adds physicsBody configure based on collisionType
    func applyPhysics() {
        self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.texture!.size())
        self.physicsBody?.affectedByGravity = false
        
        //Collision
        self.physicsBody?.categoryBitMask = collisionType.rawValue
        self.physicsBody?.collisionBitMask = (collisionType == CollisionType.enemyProj ? CollisionType.player.rawValue : CollisionType.enemy.rawValue) | CollisionType.borderContact.rawValue
        self.physicsBody?.contactTestBitMask = self.physicsBody?.collisionBitMask ?? CollisionType.borderContact.rawValue
        
        //velocity
        self.physicsBody?.velocity = self.velocity
    }
}
