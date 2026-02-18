//
//  Theme.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import SpriteKit

struct Theme {
    // Background & Grid
    static let background = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
    static let gridLine = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.3)
    
    // UI Elements
    static let nodeCore = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    static let track = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
    
    // Packet Colors (The "Neon" Palette)
    static let packetVideo = SKColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0) // Neon Red
    static let packetEmail = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Neon Cyan
    static let packetMalware = SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0) // Matrix Green
}
