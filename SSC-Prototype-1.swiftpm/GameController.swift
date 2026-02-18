//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

class GameController: ObservableObject {
    @Published var score: Int = 0    
    @Published var statusText: String = "SYSTEM_READY"
        
    func incrementScore() {
        score += 1
    }
}
