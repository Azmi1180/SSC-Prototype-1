//
//  GameEntities.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit
import SwiftUI

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
    var uiColor: Color {
        return self.color.toSwiftUI
    }
        
    var name: String {
        switch self {
        case .video: return "VIDEO (RED)"
        case .email: return "EMAIL (BLUE)"
        case .malware: return "MALWARE"
//        case .vip: return "VIP"
        }
    }
}

class PacketNode: SKShapeNode {
    let type: PacketType
    var hasVisitedRouter: Bool = false
    
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



import SpriteKit
import SwiftUI
enum RouterAction: String, CaseIterable {
    case sendTop = "SEND TOP (A)"
    case sendBottom = "SEND BOTTOM (B)"
    case drop = "DROP / FIREWALL"
}

struct LogicRule: Identifiable, Hashable {
    let id = UUID()
    var conditionColor: PacketType
    var action: RouterAction
}

class RouterNode: SKShapeNode {
    var rules: [LogicRule] = []
    
    func setupVisuals() {
        self.fillColor = Theme.nodeCore
        self.strokeColor = .white
        self.lineWidth = 4
        
        let label = SKLabelNode(text: "⚙️")
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        addChild(label)
    }
}


class DestinationNode: SKShapeNode {
    var acceptedType: PacketType
    
    init(type: PacketType, radius: CGFloat) {
        self.acceptedType = type
        super.init()
        
        let rect = CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2)
        self.path = CGPath(rect: rect, transform: nil)
        self.fillColor = type.color
        self.strokeColor = .white
        self.lineWidth = 2
        
        // Add Label
        let label = SKLabelNode(text: type == .video ? "VIDEO" : "EMAIL")
        label.fontSize = 10
        label.fontName = "Menlo-Bold"
        label.position = CGPoint(x: 0, y: radius + 10)
        addChild(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
