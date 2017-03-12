//
//  ViewController.swift
//  SpeechPlayground
//
//  Created by Martin Mitrevski on 02/03/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit
import Speech
import ApiAI

class ViewController: UIViewController, SFSpeechRecognizerDelegate, UITableViewDataSource {
    
    @IBOutlet private var recordingButton: UIButton!
    @IBOutlet private var recognizedText: UITextView!
    @IBOutlet private var productsTableView: UITableView!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer! =
        SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var products: Set<String> = Set<String>()
    private var addedProducts: [String] = [String]()
    private var cancelCalled = false
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var audioSession = AVAudioSession.sharedInstance()
    private var timer: Timer?
    private var apiAiResponse: ApiAIResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettingsButton()
        checkPermissions()
        speechRecognizer.delegate = self
    }
    
    func checkPermissions() {
        var message: String? = nil
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            switch authStatus {
            case .denied:
                message = "Please enable access to speech recognition."
            case .restricted:
                message = "Speech recognition not available on this device."
            case .notDetermined:
                message = "Speech recognition is still not authorized."
            default: break
            }
            
            OperationQueue.main.addOperation() {
                self.recordingButton.isEnabled = authStatus == .authorized
                if message != nil {
                    self.showAlert(title: "Permissions error", message: message!)
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: "Permissions error",
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAudioError() {
        let errorTitle = "Audio Error"
        let errorMessage = "Recording is not possible at the moment."
        self.showAlert(title: errorTitle, message: errorMessage)
    }
    
    func handleRecordingStateChange() {
        if audioEngine.isRunning {
            extractProducts(fromText: recognizedText.text)
            audioEngine.stop()
            self.stopAudioSession()
            recognitionRequest?.endAudio()
            recordingButton.isEnabled = false
            recordingButton.setTitle("Start Recording", for: .normal)
        } else {
            self.recognizedText.text = ""
            cancelCalled = false
            checkExistingRecognitionTask()
            startAudioSession()
            createRecognitionRequest()
            startRecording()
            recordingButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        guard let inputNode = audioEngine.inputNode else {
            showAudioError()
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!,
                                                           resultHandler:{
                                                            [unowned self] (result, error) in
            
            var recognized: String?
            if result != nil {
                recognized = result?.bestTranscription.formattedString
                self.timer?.invalidate()
                self.timer = nil
                
                if !self.cancelCalled {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 2,
                                                      repeats: false,
                                                      block: { _ in
                                                        _ = self.handleStop()
                    })
                }
                self.recognizedText.text = recognized
            }
            
            var finishedRecording = false
            if result != nil {
                finishedRecording = result!.isFinal
            }
            if error != nil || finishedRecording {
                inputNode.removeTap(onBus: 0)
                self.handleFinishedRecording()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [unowned self] (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        startAudioEngine()
    }
    
    func startAudioEngine() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            showAudioError()
        }
    }
    
    func handleFinishedRecording() {
        self.audioEngine.stop()
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        self.recordingButton.isEnabled = true
    }
    
    func handleStop() -> Bool {
        if self.cancelCalled == false {
            self.handleRecordingStateChange()
            self.cancelCalled = true
            return true
        }
        
        return false
    }
    
    func checkExistingRecognitionTask() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
    }
    
    func playRemainingText() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.continueSpeaking()
        } else {
            speechSynthesizer.speak(self.createUtterance())
        }
    }
    
    func createUtterance() -> AVSpeechUtterance {
        let text = createRemainingText()
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.rate = SettingsManager.currentRate()
        speechUtterance.pitchMultiplier = SettingsManager.currentPitch()
        speechUtterance.volume = SettingsManager.currentVolume()
        speechUtterance.preUtteranceDelay = SettingsManager.currentDelay()
        speechUtterance.voice = AVSpeechSynthesisVoice(language: SettingsManager.languageCode())
        return speechUtterance
    }
    
    func createRemainingText() -> String {
        var text = "You need to buy the following products: "
        if addedProducts.count > 0 {
            for product in addedProducts {
                text += product
                text += ","
            }
            text += "."
        } else {
            text = "You don't have any remaining products on your grocery list."
        }
        return text
    }
    
    func startAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            showAudioError()
        }
    }
    
    func stopAudioSession() {
        do {
            try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            print("error stopping audio session")
        }
    }
    
    func createRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        if available {
            recordingButton.isEnabled = true
        } else {
            recordingButton.isEnabled = false
        }
    }
    
    // Navigation bar
    func setupSettingsButton() {
        let settingsButton = UIBarButtonItem(title: "Settings",
                                             style: .plain, 
                                             target: self,
                                             action: #selector(settingsButtonClicked))
        self.navigationItem.rightBarButtonItem = settingsButton
    }
    
    func settingsButtonClicked() {
        self.performSegue(withIdentifier: "ShowSettings", sender: self)
    }
    
    // IBActions
    @IBAction func startRecording(sender: UIButton) {
        handleRecordingStateChange()
    }
    
    @IBAction func remainingProducts(sender: UIButton) {
        playRemainingText()
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "ProductCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "ProductCell")
        }
        
        cell?.textLabel?.text = addedProducts[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedProducts.count
    }
    
    // api.ai
    func extractProducts(fromText text: String) {
        ApiAIService.sharedInstance.extractProducts(fromText: text,
                                                    success: { [unowned self] response in
            if let response = response {
                let toBeAdded = response.addedProducts
                let toBeRemoved = response.removedProducts
                var tmp = self.addedProducts
                tmp.append(contentsOf: toBeAdded)
                self.addedProducts = [String]()
                for product in tmp {
                    if !toBeRemoved.contains(product) {
                        self.addedProducts.append(product)
                    }
                }
                OperationQueue.main.addOperation() {
                    self.productsTableView.reloadData()
                }
            }
        }) { error in
            print(error ?? "An error occured")
        }
    }
    
}

