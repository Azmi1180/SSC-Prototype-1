//
//  GameScene.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
    
    // Karena dinamis, kita simpan dalam bentuk array/dictionary
    var sources: [SKShapeNode] = []
    var routers: [UUID: RouterNode] = [:] // Pakai dictionary agar mudah dicari berdasarkan ID
    var servers: [DestinationNode] = []
    
    override func didMove(to view: SKView) {
        backgroundColor = GameTheme.darkerBase
        
        // 1. Sync Logic dari Controller ke Router Spesifik
        gameController?.onRulesChanged = { [weak self] routerID, newRules in
            self?.routers[routerID]?.rules = newRules
            print("Router [\(routerID.uuidString.prefix(4))] Memory Updated: \(newRules.count) instructions.")
        }
        
        // 2. Load Level Dinamis dari Controller
        if let levelData = gameController?.currentLevel {
            loadLevel(levelData: levelData)
        }
        
        startSpawning()
    }
    
    // MARK: - LEVEL LOADER
    func loadLevel(levelData: LevelData) {
        removeAllChildren()
        sources.removeAll()
        routers.removeAll()
        servers.removeAll()
        
        // 1. Setup Sources (Clients)
        for client in levelData.clients {
            let sourceNode = SKShapeNode(circleOfRadius: 8)
            sourceNode.position = skPosition(for: client.position)
            sourceNode.fillColor = .white
            sourceNode.alpha = 0.2
            addChild(sourceNode)
            sources.append(sourceNode)
        }
        
        // 2. Setup Routers (Invisible Nodes)
        for routerData in levelData.routers {
            let rNode = RouterNode(radius: 40) // Area hitbox
            rNode.position = skPosition(for: routerData.position)
            rNode.rules = routerData.rules
            rNode.name = "Router_\(routerData.id)"
            
            // Simpan ID agar bisa di-sync dengan SwiftUI
            rNode.userData = ["id": routerData.id]
            
            addChild(rNode)
            routers[routerData.id] = rNode
        }
        
        // 3. Setup Servers (Destinations)
        for serverData in levelData.servers {
            let sNode = DestinationNode(type: serverData.acceptedType)
            sNode.position = skPosition(for: serverData.position)
            addChild(sNode)
            servers.append(sNode)
        }
        // 4. Draw Tracks (Menggambar jalur secara dinamis)
        // Hubungkan semua source ke router terdekat (Untuk prototype, hubungkan ke router pertama)
        if let firstRouter = routers.values.first {
            for source in sources {
                drawTrack(from: source.position, to: firstRouter.position)
            }
            // Hubungkan router ke semua server
            for server in servers {
                drawTrack(from: firstRouter.position, to: server.position)
            }
        }
    }
    
    // MARK: - HELPER COORDINATES
    // SwiftUI pakai Top-Left (0,0), SpriteKit pakai Bottom-Left (0,0). Kita harus balik sumbu Y-nya.
    func skPosition(for normalized: CGPoint) -> CGPoint {
        return CGPoint(x: normalized.x * size.width,
                       y: (1.0 - normalized.y) * size.height)
    }
    
    // MARK: - SPAWNING LOGIC
    func startSpawning() {
        let wait = SKAction.wait(forDuration: 1.5)
        let spawn = SKAction.run { [weak self] in self?.spawnPacket() }
        run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
    }
    
    func spawnPacket() {
        guard let source = sources.randomElement(),
              let targetRouter = routers.values.first else { return }
        
        let type: PacketType = [.video, .email, .malware].randomElement()!
        
        let packet = PacketNode(type: type)
        packet.position = source.position
        addChild(packet)
        
        // Move to Router
        let distance = hypot(targetRouter.position.x - source.position.x, targetRouter.position.y - source.position.y)
        let duration = distance / type.speed
        
        let move = SKAction.move(to: targetRouter.position, duration: duration)
        let decide = SKAction.run { [weak self] in
            self?.processPacketAtRouter(packet, router: targetRouter)
        }
        
        packet.run(SKAction.sequence([move, decide]))
    }

    // MARK: - ROUTING LOGIC
    func processPacketAtRouter(_ packet: PacketNode, router: RouterNode) {
        var selectedAction: RouterAction? = nil
        
        for rule in router.rules {
            if rule.conditionColor == packet.type {
                selectedAction = rule.action
                break
            }
        }
        
        // Default Fallback
        if selectedAction == nil {
            selectedAction = Bool.random() ? .sendTop : .sendBottom
        }
        
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
            // Karena dinamis, "Top" kita asumsikan mencari server Video
            if let dest = servers.first(where: { $0.acceptedType == .video }) {
                movePacket(packet, to: dest)
            } else { packet.removeFromParent() }
            
        case .sendBottom:
            // "Bottom" kita asumsikan mencari server Email
            if let dest = servers.first(where: { $0.acceptedType == .email }) {
                movePacket(packet, to: dest)
            } else { packet.removeFromParent() }
        }
    }
    
    func movePacket(_ packet: PacketNode, to node: SKNode) {
        let distance = hypot(node.position.x - packet.position.x, node.position.y - packet.position.y)
        let duration = distance / packet.type.speed
        
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
            server.animateError()
        }
        else if packet.type == server.acceptedType {
            gameController?.score += 10
            server.animateReceive()
        }
        else {
            gameController?.score -= 10
            server.animateError()
        }
        
        packet.removeFromParent()
    }
    
    // MARK: - VISUALS
    func drawTrack(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor.white.withAlphaComponent(0.1)
        line.lineWidth = 2
        line.zPosition = -10
        addChild(line)
    }
    
    // CATATAN PENTING:
    // Fungsi 'touchesBegan' DIHAPUS.
    // Klik sekarang ditangani oleh RouterView di SwiftUI.
}
