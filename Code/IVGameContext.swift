/// #TEMPLATE FILE

/**
 project specific game-context (child class of 'GameContext')
 ** NOTE that this object is created BEFORE game is even added to the screen
 - any non-core game logic specific will be defined here (and then used later on)
 - configure game state, game cycle (waves) and game session
 - any initializing values/states to be defined here (score info, multiplayer info, existing info from db(?) )
*/

import Combine
import GameplayKit

class IVGameContext: GameContext {
    var gameScene: IVGameScene? {
        scene as? IVGameScene
    }
    let gameMode: GameModeType
    var gameInfo: IVGameInfo
    var layoutInfo: IVLayoutInfo = .init(screenSize: .zero)
    var stateList: [AnyClass] = []
    
    private(set) var stateMachine: GKStateMachine?
    
    init(dependencies: Dependencies, gameMode: GameModeType) {
        self.gameInfo = IVGameInfo()
        self.gameMode = gameMode
        super.init(dependencies: dependencies)
    }
    
    func configureStates() {
        guard let gameScene else {                  // confirmation the scene exists (otherwise do nothing)
            return
        }
        print("did configure states")
        stateMachine = GKStateMachine(states: [     // contains all possible states in the game
            IVMainMenuState(scene: gameScene, context: self),
            IVDemoState(scene: gameScene, context: self),
            IVGameIdleState(scene: gameScene, context: self),
            IVGamePlayState(scene: gameScene, context: self),
            IVGameOverState(scene: gameScene, context: self),
            IVLaserGameState(scene: gameScene, context: self),
            IVFollowPathState(scene: gameScene, context: self),
            IVColorWaveState(scene: gameScene, context: self),
            IVCircleBombState(scene: gameScene, context: self)
        ])
        // the state machine object will include difference scenarios happening in the game
        // ex: when the game starts, if we want an animation to play before actually letting the user move around;
        // need to specify that state (so that no other code is running in that time frame)
        // isolate some code execution till it's finished (only then can the other states access the nodes/screen)
        stateList = [
            IVLaserGameState.self,
            IVColorWaveState.self,
            IVCircleBombState.self
        ]
    }
    
}
