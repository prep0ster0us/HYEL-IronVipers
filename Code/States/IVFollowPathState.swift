
import GameplayKit
import SwiftUI

class IVFollowPathState: GKState {
    
    // NOTE: ANY state created MUST have reference to the scene + context
    /// STEP-1: define weak var's for both scene and context
    weak var scene: IVGameScene?
    weak var context: IVGameContext?
    
//    var player: SKSpriteNode?
    var background: SKSpriteNode?
    
    var pathMarkers: [SKSpriteNode] = []
    var currentMarkerIndex = 0
    
    
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
        print("did enter laser game state")
        
//        setupBackground()
        generatePathMarkers()
    }
    
    override func willExit(to nextState: GKState) {
        
    }
    
    func detectPlayerPosition() {
        guard let scene, let context else { return }
        if let playerPosition = scene.player?.position, currentMarkerIndex < pathMarkers.count {
            let targetMarker = pathMarkers[currentMarkerIndex]
            let distance = hypot(playerPosition.x - targetMarker.position.x,
                                 playerPosition.y - targetMarker.position.y )
            
            // Define proximity threshold (distance at which marker is considered reached)
            let proximityThreshold: CGFloat = context.gameInfo.pathProximity
            
            if distance < proximityThreshold {
                moveToNextMarker()
            }
        }
    }
    
    func generatePathMarkers() {
        guard let scene else { return }
        removeAllMarkers()  // Clear any existing markers
        
        // Define the number of markers and spacing
        let markerCount = 5
        let markerSpacing: CGFloat = 100.0
        
        // Generate markers in a random path within screen bounds
        var currentPosition = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        for _ in 0..<markerCount {
            let marker = SKSpriteNode(color: .green, size: CGSize(width: 30, height: 30))
            marker.position = currentPosition
            scene.addChild(marker)
            pathMarkers.append(marker)
            
            // Move the next marker position by a random offset (stay within screen bounds)
            let offsetX = CGFloat.random(in: -markerSpacing...markerSpacing)
            let offsetY = CGFloat.random(in: -markerSpacing...markerSpacing)
            currentPosition.x = max(min(currentPosition.x + offsetX, scene.size.width - marker.size.width / 2), marker.size.width / 2)
            currentPosition.y = max(min(currentPosition.y + offsetY, scene.size.height - marker.size.height / 2), marker.size.height / 2)
        }
        
        currentMarkerIndex = 0  // Reset to the first marker
        highlightCurrentMarker()
    }
    func removeAllMarkers() {
        for marker in pathMarkers {
            marker.removeFromParent()
        }
        pathMarkers.removeAll()
    }
    func highlightCurrentMarker() {
        // Highlight the current target marker to give player a visual cue
        if currentMarkerIndex < pathMarkers.count {
            let currentMarker = pathMarkers[currentMarkerIndex]
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let pulseAction = SKAction.sequence([scaleUp, scaleDown])
            currentMarker.run(SKAction.repeatForever(pulseAction), withKey: "pulse")
        }
    }
    func moveToNextMarker() {
        guard let context else { return }
        if currentMarkerIndex < pathMarkers.count {
            pathMarkers[currentMarkerIndex].removeAction(forKey: "pulse")  // Stop pulse on current marker
            currentMarkerIndex += 1
            if currentMarkerIndex < pathMarkers.count {
                highlightCurrentMarker()  // Highlight the next marker
            } else {
                // All markers reached; transition to the next state
                context.stateMachine?.enter(IVGamePlayState.self)
            }
        }
    }
    
    /* METHODS to handle touch events */
    func handleTouch(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene else {
            return
        }
        // move player to touch location
        scene.player?.position = touch.location(in: scene)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        print("touch ended")
    }
}
