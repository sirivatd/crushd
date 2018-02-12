//
//  QueueViewController.swift
//  crushd
//
//  Created by Don Sirivat on 1/1/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import Firebase
import TwilioVideo
import EMAlertController

class QueueViewController: UIViewController, TVIRoomDelegate {
    
    @IBOutlet weak var totalNumOfPeople: UILabel!
    @IBOutlet weak var estimatedTime: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var PopupView: UIView!
    
    var accessToken = "TWILIO_ACCESS_TOKEN"
    var tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=RedGorilla"
    var randomName: String?
    
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    
    var groupsRef = Database.database().reference(withPath: "groups")
    
    var timer = Timer()
    var counter = 0
    var token: String?
    var userName: String?
    var group: String?
    var openRooms: [ChatRoom] = []
    var host: Bool = false
    var newRoomID: String?
    var newRoomName: String?
    var connected: Bool = false
    var divisor: CGFloat!
    
    let randomAdjectives: [String] = ["Macho","Like","Abiding","Nutritious","Lovely","Tranquil","Scary","Omniscient","Undesirable","Erratic","Horrible","Animated","Quack","Ruthless","Ignorant","Absorbing","Prickly","Irate","Violent","Powerful","Concerned","Nostalgic","Chilly","Conscious","Awesome","Sweltering","Icy","Imported","Unkempt","Political"]
    let randomColors: [String] = ["aqua", "black", "blue", "fuchsia", "gray", "green",
                                  "lime", "maroon", "navy", "olive", "orange", "purple", "red",
                                  "silver", "teal", "white", "yellow"]
    let nouns: [String] = ["Shake","Sense","Bite","Alarm","Wave","Dolphin","Knee","Roll","Activity","River","Notebook","Mind","Use","Connection","Copper","Child","Skate","Book","Engine","Alligator","Mouse","Moose","Volleyball","Rule","Theory","Reward","Zoo","Monkey","Salamander","Teacher","Tooth","Appliance","Man","Twist","Drop","Cap","Substance"]
    
    @IBAction func cancelPressed() {
        if(host) {
    
                let roomRef = self.groupsRef.child(self.newRoomID!)
                roomRef.removeValue()
            }
        
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PopupView.isHidden = true
        PopupView.layer.cornerRadius = 5;
        PopupView.layer.masksToBounds = true
        PopupView.layer.shadowColor = UIColor.black.cgColor
        PopupView.layer.shadowOpacity = 1
        PopupView.layer.shadowOffset = CGSize.zero
        PopupView.layer.shadowRadius = 10
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(QueueViewController.updateLabels)), userInfo: nil, repeats: true)
        
        
        self.randomName = self.randomNameGenerator()
        self.userName = self.randomName
        self.tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=" + self.randomName!
        // Perform Action
        if (self.accessToken == "TWILIO_ACCESS_TOKEN") {
            do {
                self.accessToken = try TokenUtils.fetchToken(url: self.self.tokenUrl)
                self.token = self.accessToken
                print(self.accessToken)
                if self.group == "FM" {
                    host = true
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
    
    
    @objc func updateLabels() {
        totalNumOfPeople.text = "\(openRooms.count*2) people currently online"
        estimatedTime.text = "\(openRooms.count*3) seconds estimated wait time"
        counter = counter + 1
        timerLabel.text = String(self.counter)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        groupsRef.observeSingleEvent(of: .value) { (snapshot) in
            
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
        let connectOptions = TVIConnectOptions.init(token: self.token!) { (builder) in
        builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
        builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
        if chatRoom.numOfParticipants == 1 {
            builder.roomName = chatRoom.roomName
            let ref = self.groupsRef.child(chatRoom.key)
            ref.updateChildValues([
                "numOfParticipants": 2
                ])
            self.PopupView.isHidden = false
            var timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(QueueViewController.toRoom), userInfo: nil, repeats: false)
        } else {
            self.checkAvailableTokens()
            }
        }
        //self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
    }
    
    func prepareLocalMedia() {
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init()
            
            if(localAudioTrack == nil) {
                print("Failed to create audio track")
            }
        }
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
    
    func createNewRoom() {
        self.newRoomName = randomRoomGenerator()
        
        var ref = Database.database().reference()
        var itemRef = Database.database().reference()
        
        let newRoom = ChatRoom(roomName: newRoomName!, tokenString: self.token!, numOfParticipants: 1, timerStarted: false)
        if(self.group! == "MF" || self.group! == "FM") {
            ref = Database.database().reference(withPath: "groups").child("MF")
        } else {
            ref = Database.database().reference(withPath: "groups").child(self.group!) }
        let info = ["roomName": newRoomName, "tokenString": self.token!, "numOfParticipants": 1, "timerStarted": false] as [String : Any]
        
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
        
        itemRef.observe(.childChanged, with: { (snapshot) in
            if(snapshot.value! as! Int == 2) {
                print("Two people connected to the room")
                self.PopupView.isHidden = false
                var timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(QueueViewController.toRoom), userInfo: nil, repeats: false)
            }
            
        })
        //self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
    }
    
    @objc func toRoom() {
        self.PopupView.isHidden = true
        self.performSegue(withIdentifier: "toRoom", sender: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("I'm in the Queue!!!!!!")
        
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
            
        }
    }
}
