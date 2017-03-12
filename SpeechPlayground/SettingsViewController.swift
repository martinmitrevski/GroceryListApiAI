//
//  SettingsViewController.swift
//  SpeechPlayground
//
//  Created by Martin Mitrevski on 11/03/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var delaySlider: UISlider!
    @IBOutlet weak var rateSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettingsButton()
        setupSlidersValues()
    }
    
    func setupSlidersValues() {
        volumeSlider.value = SettingsManager.currentVolume()
        pitchSlider.value = SettingsManager.currentPitch()
        delaySlider.value = Float(SettingsManager.currentDelay())
        rateSlider.value = SettingsManager.currentRate()
    }
    
    // IBAction
    @IBAction func changeLanguageClicked(sender: UIButton) {
        self.performSegue(withIdentifier: "ShowLanguages", sender: self)
    }
    
    // Navigation bar
    func setupSettingsButton() {
        let settingsButton = UIBarButtonItem(title: "Save",
                                             style: .plain,
                                             target: self,
                                             action: #selector(saveButtonClicked))
        self.navigationItem.rightBarButtonItem = settingsButton
    }
    
    func saveButtonClicked() {
        SettingsManager.setVolume(value: volumeSlider.value)
        SettingsManager.setPitch(value: pitchSlider.value)
        SettingsManager.setDelay(value: Double(delaySlider.value))
        SettingsManager.setRate(value: rateSlider.value)
        _ = self.navigationController?.popViewController(animated: true)
    }
}
