//
//  SettingsViewController.swift
//  iOSMeerkats
//
//  Created by Joshua Woods on 9/7/17.
//  Copyright © 2017 Anthony Cohn-Richardby. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - Actions
    
    @IBAction func donateTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "£1.25million has been deducted from your account!", message: "Have a nice day!", preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        let takeItBack = UIAlertAction(title: "I made a mistake!", style: .destructive) { (_) in
            let takeBackAlert = UIAlertController(title: "Too late!", message: "We've already taken your money, have a nice day!", preferredStyle: .alert)
            let takeBackOkay = UIAlertAction(title: "Okay", style: .default) { (_) in
                self.dismiss(animated: true, completion: nil)
            }
            takeBackAlert.addAction(takeBackOkay)
            self.present(takeBackAlert, animated: true, completion: nil)
        }
        alert.addAction(okay)
        alert.addAction(takeItBack)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}

