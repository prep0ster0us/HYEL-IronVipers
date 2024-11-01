/// #TEMPLATE FILE

/**
 Main screen seen by the player
 Most of the core logic goes in here (or reference some core logic from a different game scene)
 This is the engine which powers the whole game
*/


import SpriteKit
import GameplayKit

class IVGameScene: SKScene {
    
    weak var context: IVGameContext?                // get game-specific context
    var ship: IVShipNode?                           // store reference for (main) player model
                                                    // TODO: add/create references for all necessary elements/models
    var background: IVBackgroundNode
    var scrollBackground: IVBackgroundNode
    
    init(context: IVGameContext, size: CGSize) {    // initializing (general)
        self.context = context                      // set game context
        self.background = IVBackgroundNode()
        self.scrollBackground = IVBackgroundNode()
        super.init(size: size)                      // initialize game screen size
    }

    required init?(coder aDecoder: NSCoder) {       // custom initializer (TODO: need to implement for game-specific logic)
        fatalError("init(coder:) has not been implemented")
    }
    
    /* HELPER VARIABLES */
    var direction = "left"
    
    /*
     Standard method, triggered by sprite's behavior
     Called when sprite added to a SKScene (added to window heirarchy internally)
     */
    override func didMove(to view: SKView) {
        guard let context else {                    // confirmation for the game-context
            return                                  // cannot proceed without game context; *terminate exception
        }

        prepareGameContext()                        // helper method to setup based on context (BEFORE anything on screen)
        prepareStartNodes()                         // helper method to start adding elements/models on the screen
    
        /* once everything setup; reference state machine and TRY to enter into a specific game state
         (in this case, initial state) */
        context.stateMachine?.enter(IVGameIdleState.self)
        
    }
    
    /* HELPER METHODS */
    func prepareGameContext() {
        guard let context else {                    // reconfirmation of game context (although already checked for)
            return
        }
        
        context.scene = self                                    // set up the scene (based on context)
        context.layoutInfo = IVLayoutInfo(screenSize: size)     // set up screen size
        context.configureStates()                               // configure each (starting) game state
    }
    
    func prepareStartNodes() {
        guard let context else {
            return
        }
        
        // add background
        // let background = IVBackgroundNode()
        background.setup(screenSize: size, layoutInfo: context.layoutInfo)
        
        addChild(background)
        
        // add a scrolling background
        scrollBackground.setup(screenSize: size, layoutInfo: context.layoutInfo)
        scrollBackground.background.position = CGPointMake(0, scrollBackground.background.size.height-1)
        
        addChild(scrollBackground)
        
        // get center position on the screen (to position the ship model)
        // TODO: need not be centered at the start; discuss more about starting positions for initial elements/models
        let center = CGPoint(x: size.width / 2.0,
                             y: size.height / 3.0)  // **testing
        
        // create node object (to be added to the screen)
        let ship = IVShipNode()
        ship.setup(screenSize: size, layoutInfo: context.layoutInfo)
        ship.position = center
        ship.zPosition = 2

        addChild(ship)              // add node to the screen
        self.ship = ship            // track reference
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Set synced scroll movement (background shifts down, scrollBackground moves down in-place)
        let backgroundNode = self.background.background
        backgroundNode.position = CGPoint(
            x: backgroundNode.position.x,
            y: backgroundNode.position.y - (context?.layoutInfo.scrollSpeed)!
        )
        let scrollBackgroundNode = self.scrollBackground.background
        scrollBackgroundNode.position = CGPoint(
            x: scrollBackgroundNode.position.x,
            y: scrollBackgroundNode.position.y - (context?.layoutInfo.scrollSpeed)!
        )
        
        // Reset to beginning after ran through the background image height (to loop infinitely)
        if backgroundNode.position.y < -backgroundNode.size.height {
            backgroundNode.position = CGPoint(
                x: backgroundNode.position.x,
                y: scrollBackgroundNode.position.y + scrollBackgroundNode.size.height
            )
        }
        if scrollBackgroundNode.position.y < -scrollBackgroundNode.size.height {
            scrollBackgroundNode.position = CGPoint(
                x: scrollBackgroundNode.position.x,
                y: backgroundNode.position.y + backgroundNode.size.height
            )
        }
        
        // Idle Game state - player model strolling 'anim'
        let strollDistance = (context?.layoutInfo.shipStrollDistance)!
        if (ship?.position.x)! < size.width/4 {
            direction = "right"
        } else if(ship?.position.x)! > (size.width)*(3/4) {
            direction = "left"
        }
        // add some shiver to y-axis
        let randomNum = CGFloat.random(in: 0...1)
        let shiver = (randomNum < 0.6) ? randomNum : -randomNum
        ship?.position = CGPoint(
            x: (ship?.position.x)! + getDistance(direction, strollDistance),
            y: (ship?.position.y)! + shiver
        )
    }
    func getDistance(_ direction: String, _ distance: CGFloat) -> CGFloat {
        return direction.elementsEqual("left") ? -distance : distance
    }
    
    /* METHODS TO HANDLE NODE REPOSITION ON TOUCH */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let state = context?.stateMachine?.currentState as? IVGameIdleState else {
            return
        }
        state.handleTouch(touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let state = context?.stateMachine?.currentState as? IVGameIdleState else {
            return
        }
        state.handleTouchMoved(touch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let state = context?.stateMachine?.currentState as? IVGameIdleState else {
            return
        }
        state.handleTouchEnded(touch)
    }
}
