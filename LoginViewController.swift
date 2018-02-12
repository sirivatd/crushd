//
//  LoginViewController.swift
//  crushd
//
//  Created by Don Sirivat on 1/2/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import Firebase
import SwiftyJSON
import FBSDKLoginKit

var emptyRoom: Bool = false



class LoginViewController: UIViewController, UIScrollViewDelegate, FBSDKLoginButtonDelegate, URLSessionDownloadDelegate {
    

    var ref: DatabaseReference?
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var shadowView: UIView!

    var userExists: Bool?
    var images: [String] = ["0","1","2"]
    var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
    private let readPermissions: [ReadPermission] = [.publicProfile, .email, .userFriends]
    @IBAction func pageChange(_ sender: UIPageControl) {
        var x = CGFloat(sender.currentPage) * scrollView.frame.size.width
        scrollView.contentOffset = CGPoint(x: x, y: 0)
    }
    
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Login button did log out")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("Did complete")
    }
    
    @IBAction func facebookLogin(sender: UIButton) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            
            guard let accessToken = FBSDKAccessToken.current() else {
                print("Failed to get access token")
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            // Perform login by calling Firebase APIs
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" :"id, name, email"])
                let connection = FBSDKGraphRequestConnection()
                
                connection.add(graphRequest, completionHandler: { (connection, result, error) -> Void in
                    let data = result as! [String : AnyObject]
                    print(data["name"] as? String)
                    let userName = Auth.auth().currentUser?.uid
                    let databaseRef = Database.database().reference()
                    databaseRef.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.hasChild(userName!) {
                            print("User exists!")
                            self.presentHome()
                        } else {
                            print("User doesn't exist!!!")
                            self.userExists = false
                        print("User does not exist!")
                    
                    let FBid = data["id"] as? String
                    let uid = user?.uid
                    let url = NSURL(string: "https://graph.facebook.com/\(FBid!)/picture?type=large&return_ssl_resources=1")
                    let urlString = "https://graph.facebook.com/\(FBid!)/picture?type=large&return_ssl_resources=1"
                    let randomImageString = uid!.prefix(10)
                    
                    //Download picture from FB
                    self.downloadFBImage(urlString: urlString)
                    
                  
                    print("This is the goddamn randomImageString in LoginViewController!!!")
                    print(randomImageString)
                    let storageRef = Storage.storage().reference().child("\(randomImageString).png")
                    if let uploadData = UIImagePNGRepresentation(UIImage(data: NSData(contentsOf: url! as URL)! as Data)!) {
                        storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                            if error != nil {
                                print(error)
                                return
                            }
                            print(metadata)
                        })
                    }
                    
                    
                    //Save user to Firebase
                            let userDict = ["name": data["name"] as? String, "email": user?.email, "imageURL": randomImageString, "firstTime": true, "errorReported": false, "gotCrushd": false, "points": 150, "token": "", "group": ""] as [String : Any]
                    self.ref!.child(uid!).setValue(userDict)
                    self.presentToSettings()
                    }
                })
                })
                connection.start()
            })
            
        }
    }
    
    func presentHome() {
        // Present the main view
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
  
    }
    
    func presentToSettings() {
        // Present preferences
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Settings") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference(withPath: "users")

        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowRadius = 10
    
//        Auth.auth().addStateDidChangeListener { auth, user in
//            if let user = user {
//                self.presentHome()
//            }
//        }
        
        pageControl.numberOfPages = images.count
        for index in 0..<images.count {
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            
            let imgView = UIImageView(frame: frame)
            imgView.image = UIImage(named: images[index])
            self.scrollView.addSubview(imgView)
        }
        
        scrollView.contentSize = CGSize(width: (scrollView.frame.size.width * CGFloat(images.count)), height: scrollView.frame.size.height)
  
        scrollView.delegate = self
        

        // Do any additional setup after loading the view.
    }
    
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Scrollview
    // ====================================
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(pageNumber)
        
    }
    // FBLogin Methods
    // ==================================================================
    
   
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished downloading file")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print(totalBytesWritten, totalBytesExpectedToWrite)
    }

    
    func downloadFBImage(urlString: String) {
        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        
        guard let urlDownload = URL(string: urlString) else { return }
        let downloadTask = urlSession.downloadTask(with: urlDownload)
        downloadTask.resume()
        
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
