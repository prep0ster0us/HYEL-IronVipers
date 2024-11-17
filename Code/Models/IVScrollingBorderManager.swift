import SpriteKit

class BorderManager {
    
    static let shared = BorderManager()  // Singleton instance
    
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    private var leftTop: SKSpriteNode!
    private var leftBottom: SKSpriteNode!
    
    private var rightTop: SKSpriteNode!
    private var rightBottom: SKSpriteNode!
    
    private let leftBorderTexture: SKTexture = SKTexture(imageNamed: "border-left")
    private let rightBorderTexture: SKTexture = SKTexture(imageNamed: "border-right")
    private let scrollSpeed: TimeInterval = 5.0
    private let zPos: CGFloat = 4

    private init() {}

    /// Set up the borders in the given scene
    func setup(_ scene: IVGameScene,_ context: IVGameContext) {
        self.scene = scene
        self.context = context
        leftBorderTexture.filteringMode = .nearest
        rightBorderTexture.filteringMode = .nearest
        
        let screenHeight = scene.size.height
        let borderWidth = 20.0
        let borderSize = CGSize(width: borderWidth, height: screenHeight)
        
        // Create the left borders
        leftTop = SKSpriteNode(texture: leftBorderTexture)
        leftTop.size = CGSize(width: borderWidth, height: screenHeight)
        leftTop.anchorPoint = CGPointZero
        leftTop.position = CGPointZero
        leftTop.zPosition = zPos
        leftTop.name = "leftBorder"
        scene.addChild(leftTop)
        
        leftBottom = SKSpriteNode(texture: leftBorderTexture)
        leftBottom.size = borderSize
        leftBottom.anchorPoint = CGPointZero
        leftBottom.position = CGPointMake(0, leftBottom.size.height-1)
        leftBottom.zPosition = zPos
        leftBottom.name = "leftBorder"
        scene.addChild(leftBottom)

        // Create the right borders
        rightTop = SKSpriteNode(texture: rightBorderTexture)
        rightTop.size = borderSize
        rightTop.anchorPoint = CGPointZero
        rightTop.position = CGPointMake(scene.size.width-borderWidth, 0)
        rightTop.zPosition = zPos
        rightTop.name = "rightBorder"
        scene.addChild(rightTop)
        
        rightBottom = SKSpriteNode(texture: rightBorderTexture)
        rightBottom.size = borderSize
        rightBottom.anchorPoint = CGPointZero
        rightBottom.position = CGPointMake(scene.size.width-borderWidth, rightBottom.size.height-1)
        rightBottom.zPosition = zPos
        rightBottom.name = "rightBorder"
        scene.addChild(rightBottom)

    }

    /// Start the scrolling animation
    func startScrolling() {
        scroll(top: leftTop, bottom: leftBottom)
        scroll(top: rightTop, bottom: rightBottom)
    }
    
    func scroll(top: SKSpriteNode, bottom: SKSpriteNode) {
        top.position = CGPoint(
            x: top.position.x,
            y: top.position.y - scrollSpeed
        )
        bottom.position = CGPoint(
            x: bottom.position.x,
            y: bottom.position.y - scrollSpeed
        )
        
        // Reset to beginning after ran through the border image height (to loop infinitely)
        if top.position.y < -top.size.height {
            print("went away")
            top.position = CGPoint(
                x: top.position.x,
                y: bottom.position.y + bottom.size.height
            )
        }
        if bottom.position.y < -bottom.size.height {
            bottom.position = CGPoint(
                x: bottom.position.x,
                y: top.position.y + top.size.height
            )
        }
    }
}
