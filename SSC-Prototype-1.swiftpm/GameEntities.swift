//
//  GameEntities.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit

// 1. Define the Types
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
