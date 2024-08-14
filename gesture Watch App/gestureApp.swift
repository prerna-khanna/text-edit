import SwiftUI
import CoreMotion
import WatchConnectivity

@main
struct gesture_Watch_AppApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        VStack {
            Text("Device Motion Data")
                .font(.headline)
            Text("Rotation X: \(motionManager.rotationRateX, specifier: "%.2f")")
            Text("Rotation Y: \(motionManager.rotationRateY, specifier: "%.2f")")
            Text("Rotation Z: \(motionManager.rotationRateZ, specifier: "%.2f")")
        }
        .onAppear {
            motionManager.startUpdates()
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
    }
}

class MotionManager: NSObject, ObservableObject, WCSessionDelegate {
    private var motionManager: CMMotionManager
    private var wcSession: WCSession?
    
    @Published var rotationRateX: Double = 0.0
    @Published var rotationRateY: Double = 0.0
    @Published var rotationRateZ: Double = 0.0

    override init() {
        self.motionManager = CMMotionManager()
        super.init()
        setupWatchConnectivity()
    }
    
    func startUpdates() {
        if motionManager.isDeviceMotionAvailable {
            print("Device Motion is available.")
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motionData, error) in
                guard let self = self, let motionData = motionData else {
                    if let error = error {
                        print("Device Motion update error: \(error.localizedDescription)")
                    }
                    return
                }
                
                self.rotationRateX = motionData.rotationRate.x
                self.rotationRateY = motionData.rotationRate.y
                self.rotationRateZ = motionData.rotationRate.z
                
                // Debug statements to see the values
                print("Rotation Rate X: \(self.rotationRateX)")
                print("Rotation Rate Y: \(self.rotationRateY)")
                print("Rotation Rate Z: \(self.rotationRateZ)")
                
                self.sendRotationDataToPhone()
            }
        } else {
            print("Device Motion is not available.")
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }
    
    private func sendRotationDataToPhone() {
        guard let session = wcSession, session.isReachable else {
            print("WCSession is not reachable.")
            return
        }
        
        let data = [
            "rotationRateX": rotationRateX,
            "rotationRateY": rotationRateY,
            "rotationRateZ": rotationRateZ
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Failed to send data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("WCSession is reachable")
        } else {
            print("WCSession is not reachable")
        }
    }
}
