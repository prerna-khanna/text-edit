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
    @IBOutlet weak var modeSwitch: UISwitch! // Switch to toggle between recording and recognition
    @IBOutlet weak var recordButton: UIButton! // Button to start/stop recording

    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!

    var isRecording = false
    var isRecognitionMode = true // Start in recognition mode
    var selectedOption: Int = 1  // Default selected option
    private var wcSession: WCSession?
    private var lastGestureRecognized = false
    private var touchCoordinates: [String] = [] // Stores touch coordinates

    // Gesture recognition instance
    private var gestureRecognition = GestureRecognition(bufferSize: 20)

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

        let customRotor = UIAccessibilityCustomRotor(name: "Custom Navigation") { predicate in
            return self.handleRotorSearch(predicate: predicate)
        }

        view.accessibilityCustomRotors = [customRotor]

        modeSwitch.addTarget(self, action: #selector(modeSwitchToggled), for: .valueChanged)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        recordSwitch.addTarget(self, action: #selector(toggleRecording(_:)), for: .valueChanged)
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
                        performRotorAction()
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

    private func performRotorAction() {
        DispatchQueue.main.async {
            // Attempt to start with the first label if the current element is not in the array
            var currentElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView
            
            if currentElement == nil || !(self.findNextElement(from: currentElement!, direction: .next) != nil) {
                currentElement = self.label1
            }
            
            guard let nextItem = self.findNextElement(from: currentElement!, direction: .next) else {
                print("No element found to move the rotor.")
                return
            }
            
            UIAccessibility.post(notification: .screenChanged, argument: nextItem)
            print("Moved to the next custom rotor item.")
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
    
    // Access the accessibilityLabel directly
    print("Navigating to next element: \(String(describing: nextElement.accessibilityLabel))")
    return UIAccessibilityCustomRotorItemResult(targetElement: nextElement, targetRange: nil)
}


    private func findNextElement(from currentElement: UIView, direction: UIAccessibilityCustomRotor.Direction) -> UIView? {
        let elements: [UIView] = [label1, label2, label3]

        // Log details of each element in the array
        for (index, element) in elements.enumerated() {
            print("Element \(index): \(element), Accessibility Label: \(String(describing: element.accessibilityLabel))")
        }
        
        // Log the details of the current element
        print("Current Element: \(currentElement), Accessibility Label: \(String(describing: currentElement.accessibilityLabel))")
        
        // Try to find the current element in the array
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
