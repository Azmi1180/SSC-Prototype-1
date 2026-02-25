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
    var router: RouterNode! // Menggunakan class baru
    var destA: DestinationNode! // Menggunakan class baru
    var destB: DestinationNode! // Menggunakan class baru
    
    override func didMove(to view: SKView) {
        // Ganti background ke warna Cyberpunk Dark
        backgroundColor = GameTheme.darkerBase
        
        // 1. Sync Logic dari Controller ke Router
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
        
        // Setup Source (Hanya lingkaran simple sebagai spawn point)
        source = SKShapeNode(circleOfRadius: 8)
        source.position = CGPoint(x: size.width * 0.1, y: cy)
        source.fillColor = .white
        source.alpha = 0.2
        addChild(source)
                
        // Setup Router (Baru)
        let rNode = RouterNode(radius: 10) // Init tanpa parameter radius, visual sudah di dalam class
        rNode.position = CGPoint(x: cx, y: cy)
        rNode.name = "Router"
        addChild(rNode)
        router = rNode
                
        // Setup Server A (Video - Atas)
        destA = DestinationNode(type: .video)
        destA.position = CGPoint(x: size.width * 0.9, y: cy + 120)
        destA.name = "Server A"
        addChild(destA)
                
        // Setup Server B (Email - Bawah)
        destB = DestinationNode(type: .email)
        destB.position = CGPoint(x: size.width * 0.9, y: cy - 120)
        destB.name = "Server B"
        addChild(destB)
        
        // Gambar Kabel/Jalur (Track)
        drawTrack(from: source.position, to: router.position)
        drawTrack(from: router.position, to: destA.position)
        drawTrack(from: router.position, to: destB.position)
    }
    
    // --- Spawning Logic ---
    func startSpawning() {
        let wait = SKAction.wait(forDuration: 1.5)
        let spawn = SKAction.run { [weak self] in self?.spawnPacket() }
        run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
    }
    
    func spawnPacket() {
        let type: PacketType = [.video, .email, .malware].randomElement()!
        
        // Pake class PacketNode baru yang bentuknya Diamond
        let packet = PacketNode(type: type)
        packet.position = source.position
        addChild(packet)
        
        // Move to Router
        let distance = hypot(router.position.x - source.position.x, router.position.y - source.position.y)
        let duration = distance / type.speed
        
        let move = SKAction.move(to: router.position, duration: duration)
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
        
        // Default: Random jika tidak ada rules
        if selectedAction == nil {
            selectedAction = Bool.random() ? .sendTop : .sendBottom
        }
        
        // Trigger Animasi LED Router
        router.animateProcessing(success: true)
        
        // Execute Action
        switch selectedAction! {
        case .drop:
            let shrink = SKAction.scale(to: 0.0, duration: 0.2)
            let remove = SKAction.removeFromParent()
            packet.run(SKAction.sequence([shrink, remove]))
            
            if packet.type == .malware {
                gameController?.score += 5
            } else {
                gameController?.score -= 5
            }
            
        case .sendTop:
            movePacket(packet, to: destA)
            
        case .sendBottom:
            movePacket(packet, to: destB)
        }
    }
    
    // Logic Touch untuk membuka menu
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Cek node apa yang disentuh
        let nodes = nodes(at: location)
        
        // Karena RouterNode terdiri dari banyak child (LED, body, antenna),
        // kita cek parent-nya atau name-nya secara recursive sederhana
        for node in nodes {
            if node.name == "Router" || node.parent?.name == "Router" {
                // UI Feedback
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                router.run(SKAction.sequence([scaleUp, scaleDown]))
                
                // Open Menu
                gameController?.activeRules = router.rules
                gameController?.showLogicMenu = true
                return
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
        guard let server = target as? DestinationNode else { return }
        
        if packet.type == .malware {
            gameController?.score -= 50
            server.animateError() // Animasi Merah/Shake
        }
        else if packet.type == server.acceptedType {
            gameController?.score += 10
            server.animateReceive() // Animasi Pulse/Terima
        }
        else {
            gameController?.score -= 10
            server.animateError()
        }
        
        packet.removeFromParent()
    }
    
    func drawTrack(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor.white.withAlphaComponent(0.1) // Jalur tipis transparan
        line.lineWidth = 2
        line.zPosition = -10
        addChild(line)
    }
}
