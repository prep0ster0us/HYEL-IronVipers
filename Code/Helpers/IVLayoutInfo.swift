/// #TEMPLATE FILE

/**
 For storing info about layout
 - size and position info about elements/models at the start
 - size of screen, size of elements/models
 initialize starting values here; then once the scene is set up they can be referenceda and updated
 meant to separate game-specific info from (position + size)-specific info
*/

import SpriteKit

struct IVLayoutInfo {
    let screenSize: CGSize
    let shipSize: CGSize = .init(
        width: (UIImage(named: "spaceship")?.size.width ?? 100) / 2.0,
        height: (UIImage(named: "spaceship")?.size.height ?? 100) / 2.0
    )
    let scrollSpeed: CGFloat? = 3
    let shipStrollDistance: CGFloat? = 1
    // TODO: expand to include all properties for models/nodes in the game
}
