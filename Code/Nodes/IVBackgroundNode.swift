/// #TEMPLATE FILE

/**
 Define the Spritekit Node for game background
*/

import SpriteKit

class IVBackgroundNode : SKNode {

    var background: SKSpriteNode = SKSpriteNode()
    func setup(screenSize: CGSize, layoutInfo: IVLayoutInfo) {
        let backgroundNode = SKSpriteNode(imageNamed: "space-bg")
        
        backgroundNode.size = screenSize
        backgroundNode.anchorPoint = CGPointZero
        backgroundNode.position = CGPointZero
        backgroundNode.zPosition = -1
        
        addChild(backgroundNode)
        background = backgroundNode
    }
}
