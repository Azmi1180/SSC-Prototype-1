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

// MARK: - 2. THE ROUTER (Matte Black + Antennas)
class RouterNode: SKShapeNode {
    var rules: [LogicRule] = []
    
    // Child references for animation
    private var led1: SKShapeNode!
    private var led2: SKShapeNode!
    private var led3: SKShapeNode!
    
    override init() {
        super.init()
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupVisuals() {
        // --- 1. Antennas ---
        let antennaPath = CGMutablePath()
        antennaPath.move(to: CGPoint(x: -20, y: 10))
        antennaPath.addLine(to: CGPoint(x: -30, y: 50)) // Kiri
        antennaPath.move(to: CGPoint(x: 20, y: 10))
        antennaPath.addLine(to: CGPoint(x: 30, y: 50)) // Kanan
        
        let antennas = SKShapeNode(path: antennaPath)
        antennas.strokeColor = .gray
        antennas.lineWidth = 3
        antennas.lineCap = .round
        antennas.zPosition = -1
        addChild(antennas)
        
        // --- 2. Main Body (Rounded Rect) ---
        let bodySize = CGSize(width: 80, height: 40)
        let bodyRect = CGRect(x: -bodySize.width/2, y: -bodySize.height/2, width: bodySize.width, height: bodySize.height)
        
        self.path = CGPath(roundedRect: bodyRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        self.fillColor = GameTheme.darkMatte
        self.strokeColor = .gray
        self.lineWidth = 2
        
        // --- 3. LEDs (Cyan Standby) ---
        func createLED(x: CGFloat) -> SKShapeNode {
            let led = SKShapeNode(circleOfRadius: 3)
            led.position = CGPoint(x: x, y: 0)
            led.fillColor = GameTheme.neonCyan
            led.strokeColor = .clear
            // Add Glow
            let glow = SKShapeNode(circleOfRadius: 5)
            glow.fillColor = GameTheme.neonCyan
            glow.alpha = 0.3
            glow.strokeColor = .clear
            led.addChild(glow)
            return led
        }
        
        led1 = createLED(x: -15)
        led2 = createLED(x: 0)
        led3 = createLED(x: 15)
        
        addChild(led1)
        addChild(led2)
        addChild(led3)
        
        // Breathing Animation for Standby
        let dim = SKAction.fadeAlpha(to: 0.5, duration: 1.5)
        let bright = SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        let breathe = SKAction.repeatForever(SKAction.sequence([dim, bright]))
        
        led1.run(breathe)
        led2.run(breathe)
        led3.run(breathe)
    }
    
    // Animation when processing a packet
    func animateProcessing(success: Bool) {
        let color = success ? GameTheme.neonGreen : GameTheme.neonPink
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.led1.fillColor = color
                self?.led2.fillColor = color
                self?.led3.fillColor = color
            },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.led1.fillColor = GameTheme.neonCyan
                self?.led2.fillColor = GameTheme.neonCyan
                self?.led3.fillColor = GameTheme.neonCyan
            }
        ])
        self.run(flash)
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

