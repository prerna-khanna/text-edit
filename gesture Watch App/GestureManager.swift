import SwiftUI
import WatchConnectivity
import CoreMotion

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
            Text("Motion Data")
                .font(.headline)
            Text("X: \(motionManager.accelerationX, specifier: "%.2f")")
            Text("Y: \(motionManager.accelerationY, specifier: "%.2f")")
            Text("Z: \(motionManager.accelerationZ, specifier: "%.2f")")
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
    
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0

    override init() {
        self.motionManager = CMMotionManager()
        super.init()
        setupWatchConnectivity()
    }
    
    func startUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] (accelData, error) in
                guard let self = self, let accelData = accelData else {
                    if let error = error {
                        print("Accelerometer update error: \(error.localizedDescription)")
                    }
                    return
                }
                
                self.accelerationX = accelData.acceleration.x
                self.accelerationY = accelData.acceleration.y
                self.accelerationZ = accelData.acceleration.z
                
                let accelerationInfo: [String: Double] = [
                    "accelerationX": accelData.acceleration.x,
                    "accelerationY": accelData.acceleration.y,
                    "accelerationZ": accelData.acceleration.z
                ]
                
                self.sendAccelerationData(accelerationInfo)
            }
        } else {
            print("Accelerometer is not available.")
        }
    }
    
    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }
    
    private func sendAccelerationData(_ accelerationInfo: [String: Double]) {
        guard let session = wcSession, session.isReachable else {
            print("Session is not reachable")
            return
        }
        session.sendMessage(accelerationInfo, replyHandler: nil) { error in
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
            print("Session is reachable")
        } else {
            print("Session is not reachable")
        }
    }
}
