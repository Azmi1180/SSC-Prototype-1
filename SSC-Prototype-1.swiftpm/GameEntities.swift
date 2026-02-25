//
//  GameEntities.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit
import SwiftUI

// MARK: - THEME COLORS
struct GameTheme {
    static let neonCyan = SKColor(red: 0.0, green: 1.0, blue: 0.8, alpha: 1.0)
    static let neonPink = SKColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    static let neonGreen = SKColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 1.0)
    static let darkMatte = SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
    static let darkerBase = SKColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
}

enum PacketType {
    case video, email, malware
    
    var color: SKColor {
        switch self {
        case .video: return GameTheme.neonPink
        case .email: return GameTheme.neonCyan
        case .malware: return GameTheme.neonGreen
        }
    }
    
    var speed: CGFloat {
        switch self {
        case .video: return 200.0
        case .email: return 150.0
        case .malware: return 220.0
        }
    }
    
    var name: String {
        switch self {
        case .video: return "VIDEO"
        case .email: return "EMAIL"
        case .malware: return "MALWARE"
        }
    }
    
    // Helper untuk Logic Menu SwiftUI
    var uiColor: SwiftUI.Color {
        return SwiftUI.Color(color)
    }
}

// MARK: - 1. THE PACKET (Diamond Shape)
class PacketNode: SKShapeNode {
    let type: PacketType
    
    init(type: PacketType) {
        self.type = type
        super.init()
        
        // 1. Diamond Shape (Rotated Square)
        let size: CGFloat = 14
        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
        self.path = CGPath(rect: rect, transform: nil)
        
        self.fillColor = type.color
        self.strokeColor = .white
        self.lineWidth = 1.5
        self.zRotation = .pi / 4 // Rotate 45 degrees
        
        // 2. Outer Glow (Pulse Effect)
        let glow = SKShapeNode(rect: rect)
        glow.fillColor = .clear
        glow.strokeColor = type.color
        glow.lineWidth = 2
        glow.alpha = 0.6
        addChild(glow)
        
        // Animation: Pulse
        let scaleUp = SKAction.scale(to: 1.4, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        glow.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        
        // 3. Core (White center)
        let core = SKShapeNode(circleOfRadius: 2)
        core.fillColor = .white
        core.strokeColor = .clear
        addChild(core)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class RouterNode: SKShapeNode {
    var rules: [LogicRule] = []
    
    init(radius: CGFloat) {
        super.init()
        
        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2), transform: nil)
        self.path = path
        self.fillColor = .clear
        self.strokeColor = .clear // ganti .red kalau mau debug posisi
        self.lineWidth = 0
                
        self.name = "Router"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func animateProcessing(success: Bool) {
        let originalScale = self.xScale == 0 ? 1.0 : self.xScale
        let scaleUp = SKAction.scale(to: originalScale * 1.15, duration: 0.08)
        let scaleDown = SKAction.scale(to: originalScale, duration: 0.12)
                
        let oldStroke = self.strokeColor
        let oldLineWidth = self.lineWidth
        let flashColor: SKColor = success ? GameTheme.neonGreen : .red
        let setFlash = SKAction.run { [weak self] in
            self?.strokeColor = flashColor
            self?.lineWidth = 2.0
        }
        let clearFlash = SKAction.run { [weak self] in
            self?.strokeColor = oldStroke
            self?.lineWidth = oldLineWidth
        }
        
        let group = SKAction.group([scaleUp, setFlash])
        let sequence = SKAction.sequence([group, scaleDown, clearFlash])
        self.run(sequence)
    }
}

// MARK: - 3. SERVER DESTINATION (Vertical Tower)
class DestinationNode: SKShapeNode {
    var acceptedType: PacketType
    private var statusLight: SKShapeNode!
    
    init(type: PacketType) {
        self.acceptedType = type
        super.init()
        
        // --- 1. Tower Body ---
        let w: CGFloat = 40
        let h: CGFloat = 60
        let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
        
        self.path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        self.fillColor = GameTheme.darkerBase
        self.strokeColor = .gray
        self.lineWidth = 1
        
        // --- 2. Vents (Horizontal Lines) ---
        for i in 0..<3 {
            let vent = SKShapeNode(rect: CGRect(x: -12, y: -20 + (CGFloat(i) * 10), width: 24, height: 2))
            vent.fillColor = .black
            vent.strokeColor = .clear
            addChild(vent)
        }
        
        // --- 3. Status Bar (Vertical Neon) ---
        statusLight = SKShapeNode(rect: CGRect(x: -16, y: -24, width: 3, height: 48), cornerRadius: 1.5)
        statusLight.fillColor = type.color
        statusLight.strokeColor = .clear
        addChild(statusLight)
        
        // --- 4. Label ---
        let label = SKLabelNode(text: type.name)
        label.fontSize = 10
        label.fontName = "Menlo-Bold"
        label.fontColor = type.color
        label.position = CGPoint(x: 0, y: h/2 + 8)
        addChild(label)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func animateReceive() {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        run(pulse)
        
        // Flash light
        let bright = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        let dim = SKAction.fadeAlpha(to: 0.5, duration: 0.05)
        statusLight.run(SKAction.repeat(SKAction.sequence([dim, bright]), count: 3))
    }
    
    func animateError() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -3, y: 0, duration: 0.05),
            SKAction.moveBy(x: 6, y: 0, duration: 0.05),
            SKAction.moveBy(x: -3, y: 0, duration: 0.05)
        ])
        run(shake)
        
        statusLight.fillColor = .red
        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.statusLight.fillColor = self?.acceptedType.color ?? .white
        }
    }
}

// MARK: - SHARED MODELS
enum RouterAction: String, CaseIterable {
    case sendTop = "SEND TOP"
    case sendBottom = "SEND BTM"
    case drop = "DROP"
}

struct LogicRule: Identifiable, Hashable {
    let id = UUID()
    var conditionColor: PacketType
    var action: RouterAction
}

