//
//  GameScene.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
        
    var sources: [SKShapeNode] = []
    var routers: [UUID: RouterNode] = [:]
    var servers: [DestinationNode] = []
    
    // Variabel untuk Drag & Drop Kabel
    private var activeDragLine: SKShapeNode?
    private var activeStartNode: SKNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = GameTheme.darkerBase
        
        gameController?.onRulesChanged = { [weak self] routerID, newRules in
            self?.routers[routerID]?.rules = newRules
        }
        
        gameController?.onLevelStructureChanged = { [weak self] in
            if let levelData = self?.gameController?.currentLevel {
                self?.loadLevel(levelData: levelData)
            }
        }
        
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
        
        // 1. Setup Clients
        for client in levelData.clients {
            let sourceNode = ClientNode()
            sourceNode.position = skPosition(for: client.position)
            // Simpan Data Tipe dan ID agar bisa divalidasi saat ditarik
            sourceNode.userData = ["id": client.id, "type": "client"]
            addChild(sourceNode)
            sources.append(sourceNode)
        }
        
        // 2. Setup Routers
        for routerData in levelData.routers {
            let rNode = RouterNode(radius: 40)
            rNode.position = skPosition(for: routerData.position)
            rNode.rules = routerData.rules
            rNode.userData = ["id": routerData.id, "type": "router"] // Penting untuk validasi
            addChild(rNode)
            routers[routerData.id] = rNode
        }
        
        // 3. Setup Servers
        for serverData in levelData.servers {
            let sNode = DestinationNode(type: serverData.acceptedType, id: serverData.id)
            sNode.position = skPosition(for: serverData.position)
            sNode.userData = ["id": serverData.id, "type": "server"] // Penting untuk validasi
            addChild(sNode)
            servers.append(sNode)
        }
        
        // 4. Gambar Kabel yang sudah terpasang (Berdasarkan data GameController)
        for connection in levelData.connections {
            // Cari posisi node awal dan akhir
            let startPos = getPosition(for: connection.fromID)
            let endPos = getPosition(for: connection.toID)
            if startPos != .zero && endPos != .zero {
                drawTrack(from: startPos, to: endPos, isTemporary: false)
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
        let spawnLogic = SKAction.run { [weak self] in
            guard let self = self, let controller = self.gameController else { return }
            
            // Jangan spawn kalau lagi dialog atau menu kebuka
            if !controller.isPausedForDialogue && !controller.showLogicMenu {
                self.spawnPacket()
            }
        }
        
        // Kita cek setiap 0.1 detik apakah sudah saatnya spawn berdasarkan spawnRate
        let wait = SKAction.wait(forDuration: 0.1)
        var timeSinceLastSpawn: TimeInterval = 0
        
        let loop = SKAction.customAction(withDuration: 0.1) { [weak self] _, _ in
            guard let self = self, let controller = self.gameController else { return }
            
            timeSinceLastSpawn += 0.1
            if timeSinceLastSpawn >= controller.scenario1.spawnRate {
                timeSinceLastSpawn = 0
                self.run(spawnLogic)
            }
        }
        
        run(SKAction.repeatForever(SKAction.sequence([wait, loop])))
    }
    func getPosition(for id: UUID) -> CGPoint {
        if let node = sources.first(where: { $0.userData?["id"] as? UUID == id }) { return node.position }
        if let node = routers[id] { return node.position }
        if let node = servers.first(where: { $0.userData?["id"] as? UUID == id }) { return node.position }
        return .zero
    }
    
    
    // MARK: - DRAG & DROP CABLES LOGIC
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Cek apakah pemain menyentuh Client atau Router
        let touchedNodes = nodes(at: location)
        if let startNode = touchedNodes.first(where: { $0.userData?["type"] != nil }) {
            let type = startNode.userData?["type"] as? String
            
            // Server tidak bisa jadi titik awal tarik kabel
            if type == "server" { return }
            
            activeStartNode = startNode
            
            // Buat garis sementara yang mengikuti jari
            activeDragLine = SKShapeNode()
            activeDragLine?.strokeColor = GameTheme.neonCyan
            activeDragLine?.lineWidth = 3
            activeDragLine?.glowWidth = 2
            activeDragLine?.zPosition = -5
            addChild(activeDragLine!)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startNode = activeStartNode, let line = activeDragLine else { return }
        let location = touch.location(in: self)
        
        // Update gambar garis dari startNode ke jari pemain
        let path = CGMutablePath()
        path.move(to: startNode.position)
        path.addLine(to: location)
        line.path = path
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startNode = activeStartNode else { return }
        let location = touch.location(in: self)
        let endNodes = nodes(at: location)
        
        // Hapus garis sementara
        activeDragLine?.removeFromParent()
        activeDragLine = nil
        
        // Ambil node target tempat jari dilepas
        if let targetNode = endNodes.first(where: { $0.userData?["type"] != nil && $0 != startNode }) {
            
            let startType = startNode.userData?["type"] as? String
            let targetType = targetNode.userData?["type"] as? String
            
            let startID = startNode.userData?["id"] as? UUID
            let targetID = targetNode.userData?["id"] as? UUID
            
            // VALIDASI ATURAN KABEL (Penting!)
            var isValid = false
            if startType == "client" && targetType == "router" { isValid = true }
            if startType == "router" && targetType == "server" { isValid = true }
            
            if isValid, let sID = startID, let tID = targetID {
                // Berhasil! Simpan kabel ke Controller
                gameController?.addConnection(from: sID, to: tID)
                
                // Animasi Sukses
                let flash = SKShapeNode(circleOfRadius: 30)
                flash.position = targetNode.position
                flash.fillColor = GameTheme.neonCyan
                addChild(flash)
                flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
            } else {
                // Gagal: Aturan dilanggar (misal Client ke Server langsung)
                showErrorShake(at: targetNode.position)
            }
        }
        else if let routerNode = startNode as? RouterNode, endNodes.contains(routerNode) {
            // Jari dilepas di tempat yang sama (Klik biasa, BUKAN ditarik)
            // Buka Logic Menu
            if let rID = routerNode.userData?["id"] as? UUID {
                gameController?.selectRouter(id: rID)
            }
        }
        
        activeStartNode = nil
    }
    func showErrorShake(at position: CGPoint) {
        let errorDot = SKShapeNode(circleOfRadius: 10)
        errorDot.position = position
        errorDot.fillColor = GameTheme.neonPink
        addChild(errorDot)
        
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ])
        errorDot.run(SKAction.sequence([SKAction.repeat(shake, count: 2), SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
    }
    
    func spawnPacket() {
        guard let source = sources.randomElement(),
              let allowed = gameController?.allowedPackets,
              let sourceID = source.userData?["id"] as? UUID else { return }
        
        guard let type = allowed.randomElement() else { return }
        
        let packet = PacketNode(type: type)
        packet.position = source.position
        addChild(packet)
        
        let connection = gameController?.currentLevel.connections.first(where: { $0.fromID == sourceID })
        
        if let connectedRouterID = connection?.toID, let targetRouter = routers[connectedRouterID] {
            
            let distance = hypot(targetRouter.position.x - source.position.x, targetRouter.position.y - source.position.y)
            let move = SKAction.move(to: targetRouter.position, duration: distance / type.speed)
            let decide = SKAction.run { [weak self] in self?.processPacketAtRouter(packet, router: targetRouter) }
            packet.run(SKAction.sequence([move, decide]))
        } else {
            let drop = SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.3),
                SKAction.removeFromParent()
            ])
            packet.run(drop)
        }
    }


    // MARK: - ROUTING LOGIC
    func processPacketAtRouter(_ packet: PacketNode, router: RouterNode) {
        guard let routerID = router.userData?["id"] as? UUID else { return }
        
        var selectedAction: RouterAction? = nil
        for rule in router.rules {
            if rule.conditionColor == packet.type {
                selectedAction = rule.action
                break
            }
        }
        
        if selectedAction == nil {
            // Jalankan animasi drop
            packet.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.2),
                SKAction.removeFromParent()
            ]))
                        
            gameController?.triggerPacketLoss()
            
            return
        }
        
        // Cari Server yang KONEK dengan Router ini
        let connectedServerIDs = gameController?.currentLevel.connections.filter({ $0.fromID == routerID }).map({ $0.toID }) ?? []
        
        switch selectedAction! {
            case .drop:
                packet.run(SKAction.sequence([SKAction.scale(to: 0, duration: 0.2), SKAction.removeFromParent()]))
                if packet.type == .malware {
                    gameController?.score += 5
                } else {
                    gameController?.score -= 5
                    gameController?.triggerPacketLoss()
                }
            case .forward(let targetID,  _) :// 
                let hasCable = gameController?.currentLevel.connections.contains(where: {
                    $0.fromID == routerID && $0.toID == targetID
                }) ?? false
                
                if hasCable {
                    if let destServer = servers.first(where: { $0.userData?["id"] as? UUID == targetID }) {
                        movePacket(packet, to: destServer)
                        
                    } else if let destRouter = routers[targetID] {
                        movePacket(packet, to: destRouter)
                        
                    } else {
                        packet.removeFromParent()
                    }
                } else {
                    packet.run(SKAction.sequence([SKAction.scale(to: 0, duration: 0.2), SKAction.removeFromParent()]))
                    gameController?.triggerPacketLoss()
                }
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
            gameController?.score -= 30
            gameController?.triggerPacketLoss()
            gameController?.serverAnimationTrigger = server.serverID
        }
        else if packet.type == server.acceptedType {
            gameController?.score += 10            
            gameController?.serverAnimationTrigger = server.serverID
        }
        else {
            gameController?.score -= 10
            gameController?.triggerPacketLoss()
            gameController?.serverAnimationTrigger = server.serverID
        }
        
        packet.removeFromParent()
    }
    
    // MARK: - VISUALS
    func drawTrack(from: CGPoint, to: CGPoint, isTemporary: Bool) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor.white.withAlphaComponent(0.2)
        line.lineWidth = 4
        line.zPosition = -10
        addChild(line)
    }
}
