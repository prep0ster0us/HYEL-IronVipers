import SpriteKit
import GameplayKit


class IVLaserEntity : GKEntity {
    var phaseColor: Phase
    var spriteNode: SKShapeNode
    
    private var _delay: CGFloat = 0.0
    private var _delayMax: CGFloat
    private var _fired = false
    
    private let _OffAction = SKAction.customAction(withDuration: 0.1, actionBlock: { node, elapsedTime in
        (node as! SKSpriteNode).physicsBody?.contactTestBitMask = IVGameInfo.none
    } )
    
    init(scene: SKScene, delay: CGFloat) {
        _delayMax = delay
        _fired = false
        let spriteSize = CGSize(width: scene.size.width * 1.5, height: 10)
        phaseColor = Phase.allCases.randomElement()!
        print("Shape")
        spriteNode = SKShapeNode(rectOf: spriteSize)
        print("Color")
        spriteNode.fillColor = UIColor(cgColor: phaseColor.color.cgColor)
        spriteNode.alpha = 0.5
        
        //apply collision
        print("Collision")
        self.spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteSize)
        self.spriteNode.physicsBody?.categoryBitMask = IVGameInfo.projectileMask[ IVGameInfo.particleName[self.phaseColor]! ]!
        self.spriteNode.physicsBody?.contactTestBitMask = IVGameInfo.none   //begin with no contact test
        self.spriteNode.physicsBody?.collisionBitMask = IVGameInfo.none
        self.spriteNode.physicsBody?.affectedByGravity = false
        
        print("intialized")
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if _fired {
            return
        }
        
        //delay timer before shot
        _delay += seconds
        if (_delay < _delayMax) {
            spriteNode.yScale = _delay / _delayMax
            return
        }
            
        //set test for player contact
        self.spriteNode.physicsBody?.contactTestBitMask = IVGameInfo.player
        let actions = [SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.removeFromParent()]
        self.spriteNode.run( SKAction.sequence(actions) )
        _fired = true
    }
    
}
