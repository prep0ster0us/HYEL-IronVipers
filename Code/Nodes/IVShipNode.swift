/// #TEMPLATE FILE

/**
 Define the Spritekit Node which serves as the main game model
 (controlled by the player)
*/

// TODO: import and use space ship sprite (created by @Some Wraith)

import SpriteKit

class IVShipNode : SKNode {
//    var ship: SKShapeNode = SKShapeNode()
    var projectile: IVProjectileInfo = IVProjectileInfo()
    var ship: SKSpriteNode = SKSpriteNode()
    
    var shotDelay: Double = 0.3
    var lastShotTime: TimeInterval = 0.0
    
    func setup(screenSize: CGSize, layoutInfo: IVLayoutInfo) {
//        let shipNode = SKShapeNode(
//            rect: .init(origin: .zero, size: layoutInfo.shipSize),
//            cornerRadius: 8.0
//        )
        let shipNode = SKSpriteNode(imageNamed: "enemy-ship")
        shipNode.size = CGSize(
            width : layoutInfo.shipSize.width,
            height: layoutInfo.shipSize.height
        )
        
        //add physics
        shipNode.physicsBody = SKPhysicsBody(texture: shipNode.texture!, size: shipNode.texture!.size())
        shipNode.physicsBody?.isDynamic = false
        
        //projectile setup
        projectile.speed = 500
        
//        shipNode.fillColor = .systemGreen
        addChild(shipNode)
        ship = shipNode
    }
}
