//
//  GameScene.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//


import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
        
    var source: SKShapeNode!
    var router: RouterNode!
    var destA: SKShapeNode!
    var destB: SKShapeNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = Theme.background
        
        // 1. Sync Logic
        gameController?.onRulesChanged = { [weak self] newRules in
            self?.router.rules = newRules
            print("Router Memory Updated: \(newRules.count) instructions.")
        }
        
        setupLevel()
        startSpawning()
    }
    
    
    func setupLevel() {
        removeAllChildren()
            
        let cx = size.width * 0.5
        let cy = size.height * 0.5
        
        source = createNode(at: CGPoint(x: size.width * 0.15, y: cy), name: "Source", isRouter: false)
                
        let rNode = RouterNode(circleOfRadius: 30)
        rNode.position = CGPoint(x: cx, y: cy)
        rNode.name = "Router"
        rNode.setupVisuals()
        addChild(rNode)
        router = rNode
                
        destA = DestinationNode(type: .video, radius: 25)
        destA.position = CGPoint(x: size.width * 0.85, y: cy + 150)
        destA.name = "Server A"
        addChild(destA)
                
        destB = DestinationNode(type: .email, radius: 25)
        destB.position = CGPoint(x: size.width * 0.85, y: cy - 150)
        destB.name = "Server B"
        addChild(destB)
        
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

    
    func processPacketAtRouter(_ packet: PacketNode) {
        
        var selectedAction: RouterAction? = nil
        
        for rule in router.rules {
            if rule.conditionColor == packet.type {
                selectedAction = rule.action
                break
            }
        }
        
        // 2. Default Fallback (If no rules match, go Random)
        if selectedAction == nil {
            selectedAction = Bool.random() ? .sendTop : .sendBottom
        }
        
        // 3. Execute Action
        switch selectedAction! {
        case .drop:
            // Burn Effect
            let scale = SKAction.scale(to: 0.1, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            packet.run(SKAction.sequence([scale, fade, remove]))
            
            // Check if dropping was good or bad
            if packet.type == .malware {
                gameController?.score += 5 // Good job!
            } else {
                gameController?.score -= 5 // Dropped good data!
            }
            
        case .sendTop:
            movePacket(packet, to: destA)
            
        case .sendBottom:
            movePacket(packet, to: destB)
        }
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            if node.name == "Router" {
                gameController?.activeRules = router.rules
                gameController?.showLogicMenu = true
            }
        }
    }
    
    func movePacket(_ packet: PacketNode, to node: SKNode) {
        let dx = node.position.x - packet.position.x
        let dy = node.position.y - packet.position.y
        let dist = sqrt(dx*dx + dy*dy)
        let duration = dist / packet.type.speed
        
        let move = SKAction.move(to: node.position, duration: duration)
        let finish = SKAction.run { [weak self] in
            self?.checkSuccess(packet: packet, target: node)
        }
        packet.run(SKAction.sequence([move, finish]))
    }
        
    func checkSuccess(packet: PacketNode, target: SKNode) {
        // Cast the target to our new DestinationNode class
        guard let server = target as? DestinationNode else { return }
        
        print("Checking: Packet(\(packet.type)) vs Server(\(server.acceptedType))")
        
        if packet.type == .malware {
            // Buat malware crashed the server
            gameController?.score -= 50
//            Shake effect
            let shake = SKAction.sequence([SKAction.moveBy(x: -5, y: 0, duration: 0.05), SKAction.moveBy(x: 10, y: 0, duration: 0.05), SKAction.moveBy(x: -5, y: 0, duration: 0.05)])
            server.run(shake)
        }
        else if packet.type == server.acceptedType {
            // SUCCESS: Types match exactly
            gameController?.score += 10
            // Feedback: Pulse effect
            server.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
        }
        else {
            // WRONG DATA TYPE (e.g. Email sent to Video Server)
            gameController?.score -= 10
        }
        
        // Remove packet
        packet.removeFromParent()
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
