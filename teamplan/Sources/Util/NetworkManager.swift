//
//  NetworkManager.swift
//  teamplan
//
//  Created by 크로스벨 on 6/25/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Network

final class NetworkManager {
    static let shared = NetworkManager()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    private var _isConnected: Bool = false
    
    var isConnected: Bool {
        queue.sync {
            return _isConnected
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.updateConnectionStatus(isConnected: path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionStatus(isConnected: Bool) {
        queue.async {
            self._isConnected = isConnected
        }
    }
    
    func checkNetworkConnection() async -> Bool {
        let checkCount = 5
        var connectedCount = 0
        
        for _ in 0..<checkCount {
            let isConnected = await withCheckedContinuation { continuation in
                let path = monitor.currentPath
                self.updateConnectionStatus(isConnected: path.status == .satisfied)
                continuation.resume(returning: path.status == .satisfied)
            }
            if isConnected {
                connectedCount += 1
            }
        }
        return connectedCount > checkCount / 2
    }
}
