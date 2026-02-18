//
//  GameEntities.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit

enum PacketType {
    case video, email, malware
    
    var color: SKColor {
        switch self {
        case .video: return Theme.packetVideo
        case .email: return Theme.packetEmail
        case .malware: return Theme.packetMalware
        }
    }
    
    var speed: CGFloat {
        // Higher number = Faster (Pixels per second)
        switch self {
        case .video: return 250.0
        case .email: return 150.0
        case .malware: return 200.0
        }
    }
}

class PacketNode: SKShapeNode {
    let type: PacketType
    
    init(type: PacketType) {
        self.type = type
        super.init()
            
        let size: CGFloat = 12
        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
        self.path = CGPath(rect: rect, transform: nil)
        
        self.fillColor = type.color
        self.strokeColor = .white
        self.lineWidth = 1.5
                
        let glow = SKShapeNode(rect: rect)
        glow.fillColor = type.color
        glow.strokeColor = .clear
        glow.alpha = 0.4
        glow.setScale(1.5)
        addChild(glow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
