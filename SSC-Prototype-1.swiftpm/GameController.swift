//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

class GameController: ObservableObject {
    @Published var score: Int = 0
    
    @Published var showLogicMenu: Bool = false
    @Published var selectedRouterLogic: RouterLogic = .random
    
    var onLogicChanged: ((RouterLogic) -> Void)?
    
    func updateLogic(_ newLogic: RouterLogic) {
        selectedRouterLogic = newLogic
        onLogicChanged?(newLogic)
    }
}
