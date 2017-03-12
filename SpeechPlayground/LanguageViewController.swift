//
//  LanguageViewController.swift
//  SpeechPlayground
//
//  Created by Martin Mitrevski on 11/03/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit
import AVFoundation

class LanguageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var languages: [String] = [String]()
    var selectedLanguage: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedLanguage = SettingsManager.languageCode()
        languages = Array(Set(AVSpeechSynthesisVoice.speechVoices().map { return $0.language }))
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "ProductCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "ProductCell")
        }
        
        let current = languages[indexPath.row]
        cell?.textLabel?.text = current
        cell?.accessoryType = current == selectedLanguage ? .checkmark : .none
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedLanguage = languages[indexPath.row]
        SettingsManager.setLanguageCode(value: selectedLanguage)
        tableView.reloadData()
    }

}
