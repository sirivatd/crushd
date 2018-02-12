//
//  SettingsViewController.swift
//  crushd
//
//  Created by Don Sirivat on 2/8/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import TTSegmentedControl
import Firebase
import EMAlertController

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var userGender: TTSegmentedControl!
    @IBOutlet weak var userInterest: TTSegmentedControl!
    @IBOutlet weak var startButton: UIButton!

    let ref = Database.database().reference(withPath: "users")
    let user = Auth.auth().currentUser
    let crushdPink = UIColor(red: 249, green: 62, blue: 157)
    
    var accessToken = "TWILIO_ACCESS_TOKEN"
    var tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=RedGorilla"
    var token: String?
    var group: String?
    
    @IBAction func startPressed() {
        print("Start pressed")
        // Present the main view
        let gender = userGender.currentIndex
        let interest = userInterest.currentIndex
        if(gender == 0 && interest == 0) {
            self.group = "MM"
        } else if(gender == 1 && interest == 0) {
            self.group = "FM"
        } else if(gender == 1 && interest == 1) {
            self.group = "FF"
        } else if(gender == 0 && interest == 1) {
            self.group = "MF"
        }
        
        let userRef = self.ref.child(self.user!.uid)
        userRef.updateChildValues(["group": self.group!])
        
        ref.child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            let currentUser = User(snapshot: snapshot as! DataSnapshot)
            if currentUser.firstTime == true {
                let alert = EMAlertController(title: "Adults only", message: "This app is for 18+ only")
                
                let cancel = EMAlertAction(title: "GO BACK", style: .cancel)
                let confirm = EMAlertAction(title: "CONTINUE", style: .normal) {
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
                        UIApplication.shared.keyWindow?.rootViewController = viewController
                        self.dismiss(animated: true, completion: nil)
                    }
                    let userRef = self.ref.child(self.user!.uid)
                    userRef.updateChildValues(["firstTime": false])
                }
                
                alert.addAction(action: cancel)
                alert.addAction(action: confirm)
                
                let icon = UIImage(named: "slice")
                alert.iconImage = icon
                
                self.present(alert, animated: true, completion: nil)
            } else {
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
                    UIApplication.shared.keyWindow?.rootViewController = viewController
                    self.dismiss(animated: true, completion: nil)
                }
            }
        })
    }
    
    func setupSegments() {
        userGender.itemTitles = ["MALE", "FEMALE"]
        userInterest.itemTitles = ["MEN", "WOMEN"]
        
        userGender.defaultTextFont = UIFont(name: "Avenir Next", size: 13.0)!
        userInterest.defaultTextFont = UIFont(name: "Avenir Next", size: 13.0)!
        
        userGender.selectedTextFont = UIFont(name: "Avenir Next", size: 15.0)!
        userInterest.selectedTextFont = UIFont(name: "Avenir Next", size: 15.0)!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.startButton.isHidden = true
        self.setupSegments()
        
        self.generateTWLOToken()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func generateTWLOToken() {
        let queue = DispatchQueue(label: "com.heroku.generateToken")
        queue.async {
            self.tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=" + self.user!.uid
            
            if (self.accessToken == "TWILIO_ACCESS_TOKEN") {
                do {
                    self.accessToken = try TokenUtils.fetchToken(url: self.self.tokenUrl)
                    self.token = self.accessToken
                    print("This is my access token!!!!")
                    print(self.accessToken)
                    let userRef = self.ref.child(self.user!.uid)
                    userRef.updateChildValues(["token": self.accessToken])

                } catch {
                    let message = "Failed to fetch access token"
                    //logMessage(messageText: message)
                    return
                }
            }
        }
        queue.sync {
            self.startButton.isHidden = false
        }
        }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
