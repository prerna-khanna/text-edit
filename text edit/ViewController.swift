import UIKit
import WatchConnectivity
import Foundation

extension Notification.Name {
    static let didReceiveRotationData = Notification.Name("didReceiveRotationData")
}

class ViewController: UIViewController, UITextFieldDelegate, WCSessionDelegate {
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!

    var isRecording = false
    var touchCoordinates = [String]()
    var selectedOption = 1
    private var wcSession: WCSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRotationDataObserver()
        setupWatchConnectivity()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)
        setupHideKeyboardOnTap()
        
        let customRotor = UIAccessibilityCustomRotor(name: "Custom Navigation") { predicate in
            return self.handleRotorSearch(predicate: predicate)
        }
        
        view.accessibilityCustomRotors = [customRotor]
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            if let session = wcSession, session.activationState != .activated {
                session.activate()
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated.")
        session.activate()
    }

    // Implement this method to handle incoming messages from the Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Extract the rotation data from the message
        if let rotationRateX = message["rotationRateX"] as? Double,
           let rotationRateY = message["rotationRateY"] as? Double,
           let rotationRateZ = message["rotationRateZ"] as? Double {
            //print("Received rotation rates - X: \(rotationRateX), Y: \(rotationRateY), Z: \(rotationRateZ)")
            
            // Optionally, post a notification to notify other parts of your app about the received data
            NotificationCenter.default.post(name: .didReceiveRotationData, object: nil, userInfo: message)
        } else {
            print("Received message with unknown data.")
        }
    }

    private func setupRotationDataObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRotationData(notification:)),
                                               name: .didReceiveRotationData,
                                               object: nil)
    }

    @objc private func handleRotationData(notification: Notification) {
        guard let rotationData = notification.userInfo as? [String: Double] else { return }
        detectTap(rotationData: rotationData)
    }

    private func detectTap(rotationData: [String: Double]) {
        let threshold: Double = 0.2

        if abs(rotationData["rotationRateX"] ?? 0) > threshold ||
           abs(rotationData["rotationRateY"] ?? 0) > threshold ||
           abs(rotationData["rotationRateZ"] ?? 0) > threshold {
            
            print("Tap detected with rotation data: \(rotationData)")
            UIAccessibility.post(notification: .pageScrolled, argument: nil)
        }
    }
    
    private func handleRotorSearch(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        guard let currentElement = predicate.currentItem.targetElement as? UIView else {
            print("Current element is not a UIView.")
            return nil
        }
        let direction = predicate.searchDirection
        
        guard let nextElement = findNextElement(from: currentElement, direction: direction) else {
            print("Next element not found.")
            return nil
        }
        
        print("Navigating to next element: \(String(describing: nextElement.accessibilityLabel))")
        return UIAccessibilityCustomRotorItemResult(targetElement: nextElement, targetRange: nil)
    }
    
    private func findNextElement(from currentElement: UIView, direction: UIAccessibilityCustomRotor.Direction) -> UIView? {
        let elements: [UIView] = [label1, label2, label3]
        guard let currentIndex = elements.firstIndex(of: currentElement) else {
            print("Current element not found in elements array.")
            return nil
        }
        
        let nextIndex: Int
        if direction == .next {
            nextIndex = (currentIndex + 1) % elements.count
        } else {
            nextIndex = (currentIndex - 1 + elements.count) % elements.count
        }
        
        return elements[nextIndex]
    }

    func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    func setupUI() {
        recordSwitch.isOn = false
        userIdTextField.delegate = self
        userInputTextField.delegate = self
        setupSlider()
    }

    func setupSlider() {
        optionSlider.minimumValue = 1
        optionSlider.maximumValue = 5
        optionSlider.value = 1
        optionSlider.isContinuous = true
        updateSliderValueLabel()
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.value = roundedValue
        selectedOption = Int(roundedValue)
        updateOptionDisplay()
        updateSliderValueLabel()
        userInputTextField.text = ""
    }

    func updateSliderValueLabel() {
        sliderValueLabel.text = "Option \(Int(optionSlider.value))"
    }

    func updateOptionDisplay() {
        let options = ["See what concerts we have for you in your city.",
                       "The injury is more serious than the Panthers first expected.",
                       "History repeated itself last season when Barcelona beat Madrid.",
                       "The law enforcement has a responsibility for the safety of the public.",
                       "He pleaded guilty in February under an agreement with the government."
        ]
        messageLabel.text = options[selectedOption - 1]
    }

    @IBAction func toggleRecording(_ sender: UISwitch) {
        isRecording = sender.isOn
        if !isRecording {
            saveCoordinatesToFile()
        }
    }

    @objc func handleVoiceOverFocusChanged(notification: Notification) {
        guard isRecording,
              let userInfo = notification.userInfo,
              let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey] as? UIView else {
            return
        }
        let point = focusedElement.accessibilityActivationPoint
        let coordinate = "VoiceOver Focus X: \(point.x), Y: \(point.y)"
        touchCoordinates.append(coordinate)
        print(coordinate)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        recordTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        recordTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        recordTouches(touches)
    }

    func recordTouches(_ touches: Set<UITouch>) {
        guard isRecording, let touch = touches.first else { return }
        let position = touch.location(in: view)
        let coordinate = "Touch X: \(position.x), Y: \(position.y)"
        touchCoordinates.append(coordinate)
        print(coordinate)
    }

    func saveCoordinatesToFile() {
        guard let userId = userIdTextField.text, !userId.isEmpty else {
            print("User ID is empty")
            return
        }
        if touchCoordinates.isEmpty {
            print("No coordinates to save")
            return
        }

        let fileName = "User_\(userId)_Option\(selectedOption).txt"
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find document directory")
            return
        }
        let filePath = directory.appendingPathComponent(fileName)

        do {
            try touchCoordinates.joined(separator: "\n").write(to: filePath, atomically: true, encoding: .utf8)
            print("Coordinates saved to: \(filePath)")
            touchCoordinates.removeAll()
        } catch {
            print("Failed to save coordinates: \(error)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
