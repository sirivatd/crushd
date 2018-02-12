//
//  LoadingViewController.swift
//  crushd
//
//  Created by Don Sirivat on 1/22/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import Firebase
import TwilioVideo


class LoadingViewController: UIViewController, URLSessionDownloadDelegate {
    
    var group: String?
    var userName: String?
    var token: String?
    var newRoomName: String?
    
    var shapeLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var matchPic: UIImageView!
    @IBOutlet weak var matchName: UILabel!
    @IBOutlet weak var loadingMessage: UILabel!
    
    var groupsRef: DatabaseReference?
    
    var accessToken = "TWILIO_ACCESS_TOKEN"
    var tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=RedGorilla"
    var randomName: String?
    let storage = Storage.storage()
    var image1: String?
    var image2: String?
    
    let randomAdjectives: [String] = ["Macho","Like","Abiding","Nutritious","Lovely","Tranquil","Scary","Omniscient","Undesirable","Erratic","Horrible","Animated","Quack","Ruthless","Ignorant","Absorbing","Prickly","Irate","Violent","Powerful","Concerned","Nostalgic","Chilly","Conscious","Awesome","Sweltering","Icy","Imported","Unkempt","Political"]
    let randomColors: [String] = ["aqua", "black", "blue", "fuchsia", "gray", "green",
                                  "lime", "maroon", "navy", "olive", "orange", "purple", "red",
                                  "silver", "teal", "white", "yellow"]
    let nouns: [String] = ["Shake","Sense","Bite","Alarm","Wave","Dolphin","Knee","Roll","Activity","River","Notebook","Mind","Use","Connection","Copper","Child","Skate","Book","Engine","Alligator","Mouse","Moose","Volleyball","Rule","Theory","Reward","Zoo","Monkey","Salamander","Teacher","Tooth","Appliance","Man","Twist","Drop","Cap","Substance"]
    
    var host: Bool = false
    var newRoomID: String?
    
    let percentageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        return label
    }()
    
    @IBAction func cancelPressed() {
        if(host) {
            
            let roomRef = self.groupsRef!.child(self.newRoomID!)
            roomRef.updateChildValues([
                "numOfParticipants": 2
                ])
            //roomRef.removeValue()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func handleEnterForeground() {
     
        //animatePulsatingLayer()
    }
    
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 100, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 20
        layer.fillColor = fillColor.cgColor
        layer.lineCap = kCALineCapRound
        layer.position = view.center
        return layer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationObservers()
        groupsRef = Database.database().reference(withPath: "groups")
        view.backgroundColor = UIColor.backgroundColor
        
        self.setupCircleLayers()

        
        cancelButton.layer.shadowColor = UIColor.black.cgColor
        cancelButton.layer.shadowOpacity = 1
        cancelButton.layer.shadowOffset = CGSize.zero
        cancelButton.layer.shadowRadius = 10
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.clear.cgColor
        cancelButton.layer.cornerRadius = 5
        
        generateTWLOToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.animatePulsatingLayer()

    }
    

    
    func checkAvailableTokens() {
        if self.group == "FM" {
            createNewRoom()
        }
        if(self.group == "MM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MM")
        } else if(self.group == "MF") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else if(self.group == "FM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else {
            self.groupsRef = Database.database().reference(withPath: "groups").child("FF")
        }
        
        groupsRef!.observeSingleEvent(of: .value) { (snapshot) in
            
            for item in snapshot.children {
                let chatRoomRef = ChatRoom(snapshot: item as! DataSnapshot)
                if chatRoomRef.numOfParticipants == 1 {
                    self.newRoomID = chatRoomRef.key
                    self.newRoomName = chatRoomRef.roomName
                    self.connectToRoom(chatRoom: chatRoomRef)
                    return
                }
            }
            if self.group == "MF" {
                self.checkAvailableTokens()
            } else {
                self.host = true
                self.createNewRoom()
            }
        }
    }
    
    func connectToRoom(chatRoom: ChatRoom) {
        //self.animatePulsatingLayer()

        if chatRoom.numOfParticipants == 1 {
            let ref = self.groupsRef!.child(chatRoom.key)
            ref.updateChildValues([
                "numOfParticipants": 2,
                "participant2": Auth.auth().currentUser?.uid
                ])
            let imageURL: String = chatRoom.participant1 as! String
            let matchURL = imageURL.prefix(10)
            print("This is my prefix")
            print(matchURL)
            self.showMatch(match: String("\(matchURL).png"))
        }
        
    }
    
    private func generateTWLOToken() {
        
        DispatchQueue.main.async {
            self.randomName = self.randomNameGenerator()
            self.userName = self.randomName
            self.tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=" + self.randomName!
            // Perform Action
                do {
                    self.accessToken = try TokenUtils.fetchToken(url: self.self.tokenUrl)
                    self.token = self.accessToken
                    print("This is my access token!!!!")
                    print(self.accessToken)
                    if self.group == "FM" {
                        self.host = true
                        self.createNewRoom()
                    } else {
                        self.checkAvailableTokens()
                        // Do any additional setup after loading the view.
                    }
                } catch {
                    let message = "Failed to fetch access token"
                    //logMessage(messageText: message)
                    return
                }
            }
    }
    
    
    private func createNewRoom() {
        print(self.token!)
        self.newRoomName = randomRoomGenerator()

        var uid = Auth.auth().currentUser!.uid
        var ref = Database.database().reference()
        var itemRef = Database.database().reference()
        
        if(self.group! == "MF" || self.group! == "FM") {
            ref = Database.database().reference(withPath: "groups").child("MF")
        } else {
            ref = Database.database().reference(withPath: "groups").child(self.group!) }
        let info = ["roomName": newRoomName, "tokenString": self.token!, "numOfParticipants": 1, "participant1": uid, "participant2": "empty", "timerStarted": false, "errorReported": false, "participant1Ready": false, "participant2Ready": false] as [String : Any]
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: 20)
        
        for i in 0 ..< 20 {
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        print("Opened a new room and looking for client")
        self.newRoomID = randomString as String
        itemRef = ref.child(randomString as String)
        itemRef.setValue(info)
        
        itemRef.observe(DataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String : AnyObject]
            print(postDict)
            if postDict!["participant2"] as! String != "empty" {
                print("I just got a new participant!")
                let imageURL: String = postDict!["participant2"] as! String
                let matchURL = imageURL.prefix(10)
                print("This is my prefix")
                print(matchURL)
                self.showMatch(match: String("\(matchURL).png"))
            }
            
        })
    }
    
    private func showMatch(match: String) {
     print("Showing the match now!")
     downloadFBImage(imageName: match)
        self.image1 = match
        let currentUser = Auth.auth().currentUser?.uid
        self.image2 = "\(currentUser!.prefix(10)).png"
    
    }
    
    func downloadFBImage(imageName: String) {
        print("Attempting to download file")
        print(imageName)
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
                    self.matchPic.image = imageData
                    self.matchPic.layer.cornerRadius = self.matchPic.frame.height/2
                    self.matchPic.layer.borderWidth = 2.0
                    self.matchPic.layer.borderColor = UIColor.clear.cgColor
                    self.matchPic.layer.masksToBounds = false
                    self.matchPic.clipsToBounds = true
                    self.view.bringSubview(toFront: self.matchPic)
                    //self.animateCircle()
                    self.updateLabels()
                    var timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(LoadingViewController.toRoom), userInfo: nil, repeats: false)
                }
                
            }).resume()
        }
    }
    
    @objc func toRoom() {
        self.performSegue(withIdentifier: "toRoom", sender: nil)
    }
    
    private func updateLabels() {
        self.cancelButton.isHidden = true
        self.loadingMessage.text = "Match found"
    }
    

    private func setupCircleLayers() {
        self.loadingMessage.text = "Finding a match..."
        
        pulsatingLayer = createCircleShapeLayer(strokeColor: .clear, fillColor: UIColor.pulsatingFillColor)
        view.layer.addSublayer(pulsatingLayer)
       
        
        let trackLayer = createCircleShapeLayer(strokeColor: .trackStrokeColor, fillColor: .backgroundColor)
        view.layer.addSublayer(trackLayer)
        
        shapeLayer = createCircleShapeLayer(strokeColor: .outlineStrokeColor, fillColor: .clear)
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        shapeLayer.strokeEnd = 0
        view.layer.addSublayer(shapeLayer)
    }
    
    private func animatePulsatingLayer() {

        let animation = CABasicAnimation(keyPath: "transform.scale")
        
        animation.toValue = 1.5
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        
        self.pulsatingLayer.add(animation, forKey: "pulsing")
        
    }
    
    let urlString = "https://firebasestorage.googleapis.com/v0/b/firestorechat-e64ac.appspot.com/o/intermediate_training_rec.mp4?alt=media&token=e20261d0-7219-49d2-b32d-367e1606500c"
    
    private func beginDownloadingFile() {
        print("Attempting to download file")
        
        shapeLayer.strokeEnd = 0
        
        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        
        guard let url = URL(string: urlString) else { return }
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentage = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.percentageLabel.text = "\(Int(percentage * 100))%"
            self.shapeLayer.strokeEnd = percentage
        }
        
        print(percentage)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished downloading file")
    }
    
    fileprivate func animateCircle() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        basicAnimation.toValue = 1
        
        basicAnimation.duration = 2
        
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.isRemovedOnCompletion = false
        
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
    }

    
    func randomNameGenerator() -> String {
        let randomNumber1 = UInt32(arc4random_uniform(UInt32(self.randomAdjectives.count-1)))
        let randomNumber2 = UInt32(arc4random_uniform(UInt32(self.randomColors.count - 1)))
        let randomNumber3 = UInt32(arc4random_uniform(UInt32(self.nouns.count - 1)))
        
        let randomWord1 = self.randomAdjectives[Int(randomNumber1)]
        let randomWord2 = self.randomColors[Int(randomNumber2)]
        let randomWord3 = self.nouns[Int(randomNumber3)]
        
        let randomWord = randomWord1+randomWord2+randomWord3
        
        return randomWord
    }
    
    func randomRoomGenerator() -> String {
        let randomNumber1 = UInt32(arc4random_uniform(UInt32(self.randomAdjectives.count-1)))
        let randomNumber2 = UInt32(arc4random_uniform(UInt32(self.randomColors.count - 1)))
        let randomNumber3 = UInt32(arc4random_uniform(UInt32(self.nouns.count - 1)))
        
        let randomWord1 = self.randomAdjectives[Int(randomNumber1)]
        let randomWord2 = self.randomColors[Int(randomNumber2)]
        let randomWord3 = self.nouns[Int(randomNumber3)]
        
        let randomWord = randomWord1+randomWord2+randomWord3
        
        return randomWord
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toRoom") {
            let viewController: VideoViewController = segue.destination as! VideoViewController
            viewController.token = self.token!
            viewController.userName = self.userName!
            viewController.newRoomName = self.newRoomName!
            viewController.newRoomID = self.newRoomID!
            viewController.host = self.host
            viewController.group = self.group!
            viewController.image1 = self.image1!
            viewController.image2 = self.image2!
        }
    }
    
}

