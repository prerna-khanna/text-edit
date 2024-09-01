import UIKit
import WatchConnectivity
import Foundation

extension Notification.Name {
    static let didReceiveRotationData = Notification.Name("didReceiveRotationData")
}

class ViewController: UIViewController, UITextFieldDelegate, WCSessionDelegate, UIDocumentPickerDelegate {

    // IBOutlets for UI elements
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBOutlet weak var recordButton: UIButton!

    var isRecording = false
    var isRecognitionMode = true
    var selectedOption: Int = 1
    private var wcSession: WCSession?
    private var lastGestureRecognized = false
    private var touchCoordinates: [String] = []

    private var gestureRecognition = GestureRecognition(bufferSize: 20)
    private var currentRotorIndex = 0 // Track the current rotor index

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRotationDataObserver()
        setupWatchConnectivity()

        // Add observer for VoiceOver focus changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)

        setupHideKeyboardOnTap()

        // Setup custom rotors
        setupCustomRotors()

        modeSwitch.addTarget(self, action: #selector(modeSwitchToggled), for: .valueChanged)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        recordSwitch.addTarget(self, action: #selector(toggleRecording(_:)), for: .valueChanged)
    }

    // Remove labels and custom navigation, implementing custom rotors instead
    private func setupCustomRotors() {
        let customWordRotor = UIAccessibilityCustomRotor(name: "Custom Words") { predicate in
            return self.moveCursor(in: self.userInputTextField, for: predicate, granularity: .word)
            
        }

        let customCharRotor = UIAccessibilityCustomRotor(name: "Custom Characters") { predicate in
            return self.moveCursor(in: self.userInputTextField, for: predicate, granularity: .character)
        }

        let customLineRotor = UIAccessibilityCustomRotor(name: "Custom Lines") { predicate in
            return self.moveCursor(in: self.userInputTextField, for: predicate, granularity: .line)
        }
        userInputTextField.accessibilityCustomRotors = [customWordRotor, customCharRotor, customLineRotor]
        print("custom rotor added")
    }

private func moveCursor(in textField: UITextField, for predicate: UIAccessibilityCustomRotorSearchPredicate, granularity: UITextGranularity) -> UIAccessibilityCustomRotorItemResult? {
    guard let textRange = textField.selectedTextRange else {
        print("No selected text range.")
        return nil
    }
    
    var currentPosition = predicate.searchDirection == .next ? textRange.end : textRange.start
    let offset = predicate.searchDirection == .next ? 1 : -1
    
    print("Current position: \(currentPosition), Direction: \(predicate.searchDirection == .next ? "Forward" : "Backward")")
    
    if granularity == .character {
        // Simple movement for characters by offset
        if let newPosition = textField.position(from: currentPosition, offset: offset) {
            if let charRange = textField.textRange(from: newPosition, to: newPosition) {
                print("Moving to character at position: \(newPosition)")
                textField.selectedTextRange = charRange
                return UIAccessibilityCustomRotorItemResult(targetElement: textField, targetRange: nil)
            }
        }
        
        print("Failed to move to the next or previous character.")
        return nil
    }
    
    // Handle word granularity
    while true {
        if let newRange = textField.tokenizer.rangeEnclosingPosition(currentPosition, with: .word, inDirection: predicate.searchDirection == .next ? .storage(.forward) : .storage(.backward)) {
            if (predicate.searchDirection == .next && newRange.start == currentPosition) ||
               (predicate.searchDirection == .previous && newRange.end == currentPosition) {
                print("Stuck at the same position, trying to adjust.")
                if let adjustedPosition = textField.position(from: currentPosition, offset: offset) {
                    currentPosition = adjustedPosition
                    continue
                } else {
                    print("Failed to adjust position.")
                    break
                }
            }
            
            print("Moving to word range: Start = \(newRange.start), End = \(newRange.end)")
            textField.selectedTextRange = newRange
            return UIAccessibilityCustomRotorItemResult(targetElement: textField, targetRange: nil)
        } else {
            print("Failed to find range, adjusting position incrementally.")
            if let adjustedPosition = textField.position(from: currentPosition, offset: offset) {
                currentPosition = adjustedPosition
                continue
            } else {
                print("No more positions available, breaking.")
                break
            }
        }
    }
    
    print("Failed to move to the next or previous word.")
    return nil
}




    @objc private func handleVoiceOverFocusChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey] as? UIView else {
            return
        }

        let point = focusedElement.accessibilityActivationPoint
        print("VoiceOver focused on element at X: \(point.x), Y: \(point.y)")
    }

    @objc private func toggleRecording(_ sender: UISwitch) {
        isRecording = sender.isOn
        if !isRecording {
            saveCoordinatesToFile()
        }
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

    private func recordTouches(_ touches: Set<UITouch>) {
        guard isRecording, let touch = touches.first else { return }
        let position = touch.location(in: view)
        let coordinate = "Touch X: \(position.x), Y: \(position.y)"
        touchCoordinates.append(coordinate)
        print(coordinate)
    }

    private func saveCoordinatesToFile() {
        guard let userId = userIdTextField.text, !userId.isEmpty else {
            print("User ID is empty")
            return
        }
        if touchCoordinates.isEmpty {
            print("No coordinates to save")
            return
        }

        let fileName = "User_\(userId)_Option\(selectedOption).txt"
        let tempDirectory = FileManager.default.temporaryDirectory
        let filePath = tempDirectory.appendingPathComponent(fileName)

        do {
            try touchCoordinates.joined(separator: "\n").write(to: filePath, atomically: true, encoding: .utf8)
            print("Coordinates saved to temporary file: \(filePath)")
            presentDocumentPicker(for: filePath)
        } catch {
            print("Failed to save coordinates: \(error.localizedDescription)")
        }
    }

    private func saveRecordedDataToCSV(data: [Double]) {
        guard let userId = userIdTextField.text, !userId.isEmpty else {
            print("User ID is empty")
            return
        }
        if data.isEmpty {
            print("No gesture data to save")
            return
        }

        let fileName = "GestureData_User_\(userId)_Option\(selectedOption).csv"
        let tempDirectory = FileManager.default.temporaryDirectory
        let filePath = tempDirectory.appendingPathComponent(fileName)

        let csvText = data.map { "\($0)" }.joined(separator: "\n")

        do {
            try csvText.write(to: filePath, atomically: true, encoding: .utf8)
            print("Gesture data saved to temporary file: \(filePath)")
            presentDocumentPicker(for: filePath)
        } catch {
            print("Failed to save gesture data: \(error.localizedDescription)")
        }
    }

    private func presentDocumentPicker(for fileURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            print("File saved to: \(url)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    @objc private func modeSwitchToggled() {
        isRecognitionMode = modeSwitch.isOn
        recordButton.isEnabled = !isRecognitionMode
        messageLabel.text = isRecognitionMode ? "Recognition Mode" : "Recording Mode"
        print("Switched to \(isRecognitionMode ? "Recognition" : "Recording") Mode")
    }

    @objc private func recordButtonTapped() {
        if isRecording {
            isRecording = false
            let recordedTemplate = gestureRecognition.stopRecording()
            saveRecordedDataToCSV(data: recordedTemplate)
            recordButton.setTitle("Start Recording", for: .normal)
            print("Gesture recording stopped and saved.")
        } else {
            isRecording = true
            gestureRecognition.startRecording()
            recordButton.setTitle("Stop Recording", for: .normal)
            print("Gesture recording started.")
        }
    }

    private func setupRotationDataObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRotationData(notification:)),
                                               name: .didReceiveRotationData,
                                               object: nil)
    }

    @objc private func handleRotationData(notification: Notification) {
        guard let rotationData = notification.userInfo as? [String: Double] else {
            print("Invalid rotation data received.")
            return
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
        wcSession?.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let rotationRateX = message["rotationRateX"] as? Double,
           let rotationRateY = message["rotationRateY"] as? Double,
           let rotationRateZ = message["rotationRateZ"] as? Double {

            if isRecognitionMode {
                let gestureRecognized = gestureRecognition.addGyroData(rotationRateX: rotationRateX, rotationRateY: rotationRateY, rotationRateZ: rotationRateZ)
                
                if gestureRecognized {
                    if !lastGestureRecognized {
                        moveToNextRotor()
                    }
                    lastGestureRecognized = true
                } else {
                    lastGestureRecognized = false
                }
            } else if isRecording {
            
                gestureRecognition.addGyroData(rotationRateX: rotationRateX, rotationRateY: rotationRateY, rotationRateZ: rotationRateZ)
            }

            NotificationCenter.default.post(name: .didReceiveRotationData, object: nil, userInfo: message)
        } else {
            print("Received message with unknown data.")
        }
    }

    private func moveToNextRotor() {
        guard let rotors = userInputTextField.accessibilityCustomRotors, !rotors.isEmpty else {
            print("No custom rotors available.")
            return
        }

        currentRotorIndex = (currentRotorIndex + 1) % rotors.count
        let nextRotor = rotors[currentRotorIndex]
        
        UIAccessibility.post(notification: .announcement, argument: nextRotor.name)
        // The rotor will change based on the announcement, we assume here
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
        sliderValueLabel.text = "Option \(selectedOption)"
    }

    func updateOptionDisplay() {
        let options = [
            "See what concerts we have for you in your city.",
            "The injury is more serious than the Panthers first expected.",
            "History repeated itself last season when Barcelona beat Madrid.",
            "The law enforcement has a responsibility for the safety of the public.",
            "He pleaded guilty in February under an agreement with the government."
        ]
        
        messageLabel.text = options[selectedOption - 1]
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
