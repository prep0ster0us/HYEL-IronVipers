/// #TEMPLATE FILE

/**
 Defines a specific game state (properties) and game machine (operations)
*/

import GameplayKit

class IVGameIdleState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
    /// STEP-2: initialize these values for each state
    init(scene: IVGameScene, context: IVGameContext) {
        self.scene = scene
        self.context = context
        super.init()                // retain the properties from the parent/global state
    }
    
    /* method to control where the current state can navigate to (future) */
    /// ex: once the splash animation is done, need to navigate to playable game-start state
    /// we can choose to allow or disallow it from here.
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    /* method to control where the current state is coming from (past) */
    /// a state can have multiple entry points, this helps check which state calls the current state (i.e. the parent state)
    /// ex: game-over state can be a result of time running out OR no more lives left.
    override func didEnter(from previousState: GKState?) {
        print("did enter idle state")
    }
    
    func handleTouch(_ touch: UITouch) {
//        guard let scene, let context else {
//            return
//        }
        print("touched \(touch)")
        // get touch position
//        let touchLocation = touch.location(in: scene)
    }
    
    // similar in function to 'handleTouch' (accounts for when player taps+holds on the model/node
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene, let context else {
            return
        }
        let touchLocation = touch.location(in: scene)
        let newBoxPos = CGPoint(x: touchLocation.x - context.layoutInfo.shipSize.width / 2.0,
                                y: touchLocation.y - context.layoutInfo.shipSize.height / 2.0)
        scene.player?.position = newBoxPos
    }
    
    // log msg to flag end of tap / tap+hold movement
    func handleTouchEnded(_ touch: UITouch) {
        print("touched ended \(touch)")
    }
}

