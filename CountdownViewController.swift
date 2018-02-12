//
//  CountdownViewController.swift
//  crushd
//
//  Created by Don Sirivat on 1/20/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import Firebase

class CountdownViewController: UIViewController, URLSessionDownloadDelegate {

    var countdownTimer = Timer()
    var imageOne: String?
    var imageTwo: String?
    
    @IBOutlet weak var participant1Image: UIView!
    @IBOutlet weak var participant2Image: UIView!
    @IBOutlet weak var propic1: UIImageView!
    @IBOutlet weak var propic2: UIImageView!
    @IBOutlet weak var number1: UILabel!
    @IBOutlet weak var number2: UILabel!
    @IBOutlet weak var number3: UILabel!

    
    let ref = Database.database().reference(withPath: "users")
    let user = Auth.auth().currentUser
    let storage = Storage.storage()
    let crushdPink = UIColor(red: 249, green: 62, blue: 157)
    
    func runTimer() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: (#selector(CountdownViewController.printCountdown)), userInfo: nil, repeats: false)
    }
    
    @objc func printCountdown() {
        //self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        print(imageOne!)
        print(imageTwo!)
        downloadFBImages(imageName1: imageOne!, imageName2: imageTwo!)
        runTimer()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        participant1Image.center.x -= view.bounds.width
        participant2Image.center.x += view.bounds.width
        number1.alpha = 0
        number2.alpha = 0
        number3.alpha = 0
    }
    
    func downloadFBImages(imageName1: String, imageName2: String) {
        print("Attempting to set profile pictures")
        let storageRef = storage.reference(forURL: "gs://crushd-29ca1.appspot.com/")
        let url1 = storageRef.child(imageName1)
        let url2 = storageRef.child(imageName2)
        
        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        
        url1.downloadURL { (url, error) in
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
                    self.propic1.image = imageData
                    self.propic1.layer.cornerRadius = self.propic1.frame.height/2
                    self.propic1.layer.borderWidth = 3.0
                    self.propic1.layer.borderColor = self.crushdPink.cgColor
                    self.propic1.layer.masksToBounds = false
                    self.propic1.clipsToBounds = true
                    UIView.animate(withDuration: 1, delay: 1, options: [.curveEaseOut], animations: {
                        self.participant1Image.center.x += self.view.bounds.width
                    },
                                   completion: nil
                    )
                }
                
            }).resume()
        }
        url2.downloadURL { (url, error) in
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
                    self.propic2.image = imageData
                    self.propic2.layer.cornerRadius = self.propic2.frame.height/2
                    self.propic2.layer.borderWidth = 3.0
                    self.propic2.layer.borderColor = self.crushdPink.cgColor
                    self.propic2.layer.masksToBounds = false
                    self.propic2.clipsToBounds = true
                    UIView.animate(withDuration: 1, delay: 1, options: [.curveEaseOut], animations: {
                        self.participant2Image.center.x -= self.view.bounds.width
                    },
                                   completion: nil
                    )
                    UIView.animate(withDuration: 1.5, delay: 2, options: [], animations: {
                        self.number3.alpha = 1
                    },
                                   completion: { (finished: Bool) in
                                    self.number3.isHidden = true
                    }
                    )
                    UIView.animate(withDuration: 1.5, delay: 3.5, options: [], animations: {
                        self.number2.alpha = 1
                    },
                                   completion: { (finished: Bool) in
                                    self.number2.isHidden = true
                    }
                    )
                    UIView.animate(withDuration: 1.5, delay: 5, options: [], animations: {
                        self.number1.alpha = 1
                    },
                                   completion: { (finished: Bool) in
                                     self.dismiss(animated: true, completion: nil)
                    }
                    )
                    
                }
                
            }).resume()
        }
    }
    
    func animateCountdown() {
        print("I should be animating now")
      
       
        print("I should dismiss the countdown now")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished acquiring pictures")
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
