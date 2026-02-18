//
//  GameScene.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//


import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
    
    // The Nodes
    var source: SKShapeNode!
    var router: RouterNode!
    var destA: SKShapeNode! // Top
    var destB: SKShapeNode! // Bottom
    
    override func didMove(to view: SKView) {
        backgroundColor = Theme.background
        
        // Listen for Logic Updates from SwiftUI
        gameController?.onLogicChanged = { [weak self] newLogic in
            self?.router.logic = newLogic
            print("Router Logic Updated to: \(newLogic)")
        }
        
        setupLevel()
        startSpawning()
    }
    
    func setupLevel() {
        removeAllChildren() // Clean slate
        
        // Coordinates (Percentages)
        let cx = size.width * 0.5
        let cy = size.height * 0.5
        
        // 1. Source (Left)
        source = createNode(at: CGPoint(x: size.width * 0.15, y: cy), name: "Source", isRouter: false)
        
        // 2. Router (Center)
        let rNode = RouterNode(circleOfRadius: 30)
        rNode.position = CGPoint(x: cx, y: cy)
        rNode.name = "Router"
        rNode.setupVisuals()
        addChild(rNode)
        router = rNode // Store reference
        
        // 3. Destinations (Right Split)
        // Dest A (Top Right - RED)
        destA = createNode(at: CGPoint(x: size.width * 0.85, y: cy + 150), name: "Server A", isRouter: false)
        destA.fillColor = Theme.packetVideo // Color code it Red
        
        // Dest B (Bottom Right - BLUE)
        destB = createNode(at: CGPoint(x: size.width * 0.85, y: cy - 150), name: "Server B", isRouter: false)
        destB.fillColor = Theme.packetEmail // Color code it Blue
        
        // 4. Draw Tracks
        drawTrack(from: source.position, to: router.position)
        drawTrack(from: router.position, to: destA.position)
        drawTrack(from: router.position, to: destB.position)
    }
    
    // --- Spawning & Movement Phase 1 ---
    func startSpawning() {
        let wait = SKAction.wait(forDuration: 1.2)
        let spawn = SKAction.run { [weak self] in self?.spawnPacket() }
        run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
    }
    
    func spawnPacket() {
        // Random Type
        let type: PacketType = [.video, .email, .malware].randomElement()!
        let packet = PacketNode(type: type)
        packet.position = source.position
        addChild(packet)
        
        // Move to Router
        let distance = hypot(router.position.x - source.position.x, router.position.y - source.position.y)
        let duration = distance / type.speed
        
        let move = SKAction.move(to: router.position, duration: duration)
        
        // When it arrives at Router, trigger the Logic Decision
        let decide = SKAction.run { [weak self] in
            self?.processPacketAtRouter(packet)
        }
        
        packet.run(SKAction.sequence([move, decide]))
    }
    
    // --- The Core Logic Engine ---
    func processPacketAtRouter(_ packet: PacketNode) {
        
        // 1. Determine Target based on Router Logic
        var targetNode: SKShapeNode
        
        switch router.logic {
        case .random:
            targetNode = Bool.random() ? destA : destB
            
        case .sortColor:
            // Red (Video) -> Up (DestA), Blue (Email) -> Down (DestB)
            // Malware goes Random
            if packet.type == .video { targetNode = destA }
            else if packet.type == .email { targetNode = destB }
            else { targetNode = Bool.random() ? destA : destB }
            
        case .privacy:
            // If Malware, DESTROY IT
            if packet.type == .malware {
                packet.run(SKAction.sequence([
                    SKAction.scale(to: 0, duration: 0.1),
                    SKAction.removeFromParent()
                ]))
                return // Stop processing
            }
            targetNode = Bool.random() ? destA : destB
        }
        
        // 2. Move to Target
        let distance = hypot(targetNode.position.x - router.position.x, targetNode.position.y - router.position.y)
        let duration = distance / packet.type.speed
        
        let move = SKAction.move(to: targetNode.position, duration: duration)
        let finish = SKAction.run {
            // Check if it went to the "Correct" server color
            // (Simple visual check: if packet color matches node color, score points)
            if packet.type.color == targetNode.fillColor {
                self.gameController?.score += 10
            } else if packet.type == .malware {
                self.gameController?.score -= 50 // Crash!
            }
            packet.removeFromParent()
        }
        
        packet.run(SKAction.sequence([move, finish]))
    }
    
    // --- Interactions ---
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            if node.name == "Router" {
                // Open the SwiftUI Menu
                gameController?.showLogicMenu = true
                gameController?.selectedRouterLogic = router.logic
            }
        }
    }
    
    // --- Helpers ---
    func createNode(at p: CGPoint, name: String, isRouter: Bool) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 20)
        node.position = p
        node.name = name
        node.fillColor = Theme.nodeCore
        node.strokeColor = .white
        node.lineWidth = 2
        addChild(node)
        return node
    }
    
    func drawTrack(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = Theme.track
        line.lineWidth = 4
        line.zPosition = -1
        addChild(line)
    }
}
