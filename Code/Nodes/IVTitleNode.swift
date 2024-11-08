//
//  IVTitleNode.swift
//  IronVipers
//
//  Created by Ritwik Babu on 11/8/24.
//

import SpriteKit
import GameplayKit

class IVTitleNode: SKNode {
    let title: String
    var charNodes: [SKLabelNode]
    
    init(_ title: String, _ scene: IVGameScene) {
        self.title = title
        
        // Split the text into characters and create an SKLabelNode for each character
        let characterSpacing: CGFloat = 40
        let startX = (scene.size.width / 2) - (CGFloat(title.count) * characterSpacing) / 2
        
        for (index, char) in title.enumerated() {
            let characterNode = SKLabelNode(text: String(char))
            characterNode.fontName = "Courier-Bold" // Use a blocky font for pixel effect
            characterNode.fontSize = 40
            characterNode.position = CGPoint(x: startX + CGFloat(index) * characterSpacing, y: scene.size.height / 2)
            characterNode.name = "titleLabel"
            charNodes.append(characterNode)
            title.append(characterNode)
        }
    }
}
