//
//  ViewController.swift
//  crushd
//
//  Created by Don Sirivat on 12/10/17.
//  Copyright © 2017 Don Sirivat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import TTSegmentedControl
import Firebase
import FacebookShare
import FacebookCore
import SwiftyJSON
import EMAlertController

class LandingViewController: UIViewController, URLSessionDownloadDelegate {
    

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var whiteView: UIView!
    
    @IBAction func logoutPressed() {
        
        let alert = EMAlertController(title: "Sign out", message: "Are you sure you want to logout?")
        
        let cancel = EMAlertAction(title: "GO BACK", style: .cancel)
        let confirm = EMAlertAction(title: "CONTINUE", style: .normal) {
            if Auth.auth().currentUser != nil {
                do {
                    try Auth.auth().signOut()
                    self.logout()
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
        
        alert.addAction(action: cancel)
        alert.addAction(action: confirm)
        
        let icon = UIImage(named: "slice")
        alert.iconImage = icon
        
        self.present(alert, animated: true, completion: nil)
    }
    
    let ref = Database.database().reference(withPath: "users")
    let user = Auth.auth().currentUser
    let storage = Storage.storage()
    let crushdPink = UIColor(red: 249, green: 62, blue: 157)

    @IBOutlet weak var videoView: UIView!
    
 
    @IBAction func startPressed() {
        self.performSegue(withIdentifier: "toHome", sender: nil)
    }
    
    @IBAction func settingsPressed() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Settings")
        self.present(vc, animated: true, completion: nil)
    }
    
    
    func logout() {
        self.dismiss(animated: true, completion: nil)
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Login")
        self.present(vc, animated: true, completion: nil)
    }
    
    
    func setupView() {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: "Fun Fair", ofType: "mov")!)
        let player = AVPlayer(url: path)
        
        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = self.videoView.frame
        self.videoView.layer.addSublayer(newLayer)
        newLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        player.play()
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        NotificationCenter.default.addObserver(self, selector: #selector(LandingViewController.videoDidPlayToEnd(_:)), name: NSNotification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification"), object: player.currentItem)
    }
    
    @objc func videoDidPlayToEnd(_ notification: Notification) {
        let player: AVPlayerItem = notification.object as! AVPlayerItem
        player.seek(to: kCMTimeZero)
    }
    
    func setupProfile() {
        self.profileImage.layer.cornerRadius = self.profileImage.frame.height/2
        self.profileImage.layer.borderWidth = 1.0
        self.profileImage.layer.borderColor = UIColor.clear.cgColor
        
        self.profileImage.layer.masksToBounds = false
        self.profileImage.clipsToBounds = true
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        self.whiteView.layer.shadowColor = UIColor.black.cgColor
        self.whiteView.layer.shadowOpacity = 1
        self.whiteView.layer.shadowOffset = CGSize.zero
        self.whiteView.layer.shadowRadius = 10
        self.whiteView.layer.borderWidth = 1
        self.whiteView.layer.borderColor = UIColor.clear.cgColor
        self.whiteView.layer.cornerRadius = 5
        self.whiteView.layer.opacity = 0.7
        
        profileImage.alpha = 0
        print("Why am I here")
        let conditionItemRef = self.ref.child(user!.uid)
        conditionItemRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let m = snapshot.value as? [String:Any?]
            let imageName = (m?["imageURL"])!
            let name = (m?["name"])!
            let firstTime = (m?["firstTime"])!
            if(firstTime as! Bool == true) {
                //self.performSegue(withIdentifier: "toPreferences", sender: nil)
            }
            
            print("This is Landing ViewController viewDidLoad")
            print(m!)
            print("Why isn't this what I think it should be")
            print(imageName!)
            self.downloadFBImage(imageName: "\(imageName!).png")
            
            self.startButton.layer.shadowColor = UIColor.black.cgColor
            self.startButton.layer.shadowOpacity = 1
            self.startButton.layer.shadowOffset = CGSize.zero
            self.startButton.layer.shadowRadius = 10
            self.startButton.layer.borderWidth = 1
            self.startButton.layer.borderColor = UIColor.clear.cgColor
            self.startButton.layer.cornerRadius = 5
            
//            DispatchQueue.main.async(execute: {
//                print(imageName as! String)
//                let storageRef = self.storage.reference(withPath: "\(imageName!).png")
//                storageRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
//                   // let pic = UIImage(data: data!)
//                    //self.profileImage.image = pic
//                }
//            })
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupView()
    }
    
    func downloadFBImage(imageName: String) {
        print("Attempting to download file")
        let storageRef = storage.reference(forURL: "gs://crushd-29ca1.appspot.com/")
        let imageURL = storageRef.child(imageName)
        
        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        
        imageURL.downloadURL { (url, error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                
                if error != nil {
                    print(error)
                    return
                }
                
                guard let imageData = UIImage(data: data!) else { return }
                
                DispatchQueue.main.async {
                    self.profileImage.image = imageData
                    self.profileImage.layer.cornerRadius = self.profileImage.frame.height/2
                    self.profileImage.layer.borderWidth = 3.0
                    self.profileImage.layer.borderColor = UIColor.clear.cgColor
                    self.profileImage.layer.masksToBounds = false
                    self.profileImage.clipsToBounds = true
                    UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut], animations: {
                        self.profileImage.alpha = 1
                    },
                                   completion: nil
                    )
                }
                
            }).resume()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished downloading picture!")
    }


}

