import SpriteKit

class IVEnemyShipNode : SKNode {
    var hp: Int32 = 10
    var projectile: IVProjectileInfo = IVProjectileInfo()
    var enemySprite: SKSpriteNode = SKSpriteNode()
    
    func setup(screenSize: CGSize, layoutInfo: IVLayoutInfo) {
        enemySprite = SKSpriteNode(imageNamed: "enemy-ship2")
        enemySprite.size = CGSize(
            width : layoutInfo.shipSize.width,
            height: layoutInfo.shipSize.height
        )
        
        applyPhysics()
        
        self.name = "enemy-ship"
        self.zPosition = 2
        
        addChild(enemySprite)
    }
    
    
    func applyPhysics() {
        enemySprite.physicsBody = SKPhysicsBody(texture: enemySprite.texture!, size: enemySprite.texture!.size())
        enemySprite.physicsBody?.isDynamic = false
        
        //Collisions
        enemySprite.physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
        enemySprite.physicsBody?.collisionBitMask = CollisionType.playerProj.rawValue
        enemySprite.physicsBody?.contactTestBitMask = CollisionType.playerProj.rawValue
    }
}
