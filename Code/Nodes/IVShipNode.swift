/// #TEMPLATE FILE

/**
 Define the Spritekit Node which serves as the main game model
 (controlled by the player)
*/

// TODO: import and use space ship sprite (created by @Some Wraith)

import SpriteKit

class IVShipNode : SKNode {
//    var ship: SKShapeNode = SKShapeNode()
    var ship: SKSpriteNode = SKSpriteNode()
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
//        shipNode.fillColor = .systemGreen
        addChild(shipNode)
        ship = shipNode
    }
}
