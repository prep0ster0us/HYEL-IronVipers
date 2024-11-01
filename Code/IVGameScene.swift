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
    
    init(context: IVGameContext, size: CGSize) {    // initializing (general)
        self.context = context                      // set game context
        super.init(size: size)                      // initialize game screen size
    }

    required init?(coder aDecoder: NSCoder) {       // custom initializer (TODO: need to implement for game-specific logic)
        fatalError("init(coder:) has not been implemented")
    }
    
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
        let background = IVBackgroundNode()
        background.setup(screenSize: size, layoutInfo: context.layoutInfo)
        
        addChild(background)
        
        // get center position on the screen (to position the ship model)
        // TODO: need not be centered at the start; discuss more about starting positions for initial elements/models
        let center = CGPoint(x: size.width / 2.0,
                             y: size.height / 2.0)
        
        // create node object (to be added to the screen)
        let ship = IVShipNode()
        ship.setup(screenSize: size, layoutInfo: context.layoutInfo)
        ship.position = center
        ship.zPosition = 2

        addChild(ship)              // add node to the screen
        self.ship = ship            // track reference
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
