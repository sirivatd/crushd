//
//  VideoViewController.swift
//  crushd
//
//  Created by Don Sirivat on 12/13/17.
//  Copyright © 2017 Don Sirivat. All rights reserved.
//

import UIKit
import TwilioVideo
import Firebase
import SnapTimer
import SpinnerActivityIndicator

class VideoViewController: UIViewController {
    
    var groupsRef = Database.database().reference(withPath: "groups")
    
    let randomAdjectives: [String] = ["Macho","Like","Abiding","Nutritious","Lovely","Tranquil","Scary","Omniscient","Undesirable","Erratic","Horrible","Animated","Quack","Ruthless","Ignorant","Absorbing","Prickly","Irate","Violent","Powerful","Concerned","Nostalgic","Chilly","Conscious","Awesome","Sweltering","Icy","Imported","Unkempt","Political"]
    let randomColors: [String] = ["aqua", "black", "blue", "fuchsia", "gray", "green",
                                  "lime", "maroon", "navy", "olive", "orange", "purple", "red",
                                  "silver", "teal", "white", "yellow"]
    let nouns: [String] = ["Shake","Sense","Bite","Alarm","Wave","Dolphin","Knee","Roll","Activity","River","Notebook","Mind","Use","Connection","Copper","Child","Skate","Book","Engine","Alligator","Mouse","Moose","Volleyball","Rule","Theory","Reward","Zoo","Monkey","Salamander","Teacher","Tooth","Appliance","Man","Twist","Drop","Cap","Substance"]
     // Video SDK components
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    //var remoteView: TVIVideoView?
    
    var token: String?
    var userName: String?
    var group: String?
    var openRooms: [ChatRoom] = []
    var host: Bool = false
    var newRoomID: String?
    var newRoomName: String?
    var connected: Bool = false
    var divisor: CGFloat!
    var image1: String?
    var image2: String?
    
    var checkTimer = Timer()
    
    
    // `TVIVideoVilew` created from a storyboard
    @IBOutlet weak var previewView: TVIVideoView!
    @IBOutlet weak var timer: SnapTimerView!

//    @IBOutlet weak var spinner1: SpinnerActivityIndicator!
//    @IBOutlet weak var spinner2: SpinnerActivityIndicator!
//    @IBOutlet weak var spinner3: SpinnerActivityIndicator!
//    @IBOutlet weak var spinner4: SpinnerActivityIndicator!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var remoteView: TVIVideoView!
    @IBOutlet weak var heartImageView: UIImageView!
    
    func resetRemoteView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.remoteView.center = self.view.center
            self.heartImageView.alpha = 0
            self.remoteView.alpha = 1
            self.remoteView.transform = CGAffineTransform.identity
        })
    }
    
    @IBAction func panCard(_ sender: UIPanGestureRecognizer) {
        let remoteView = sender.view!
        let point = sender.translation(in: view)
        let xFromCenter = remoteView.center.x - view.center.x
        remoteView.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
        
        let scale = min(100/abs(xFromCenter), 1)
        remoteView.transform = CGAffineTransform(rotationAngle: xFromCenter/divisor).scaledBy(x: scale, y: scale)
        
        if xFromCenter > 0 {
            heartImageView.image = #imageLiteral(resourceName: "crushd_image")
            heartImageView.tintColor = UIColor.red
        } else {
            heartImageView.image = #imageLiteral(resourceName: "crushd_image")
            heartImageView.tintColor = UIColor.red
        }
        
        heartImageView.alpha = abs(xFromCenter/view.center.x)
        
        if sender.state == UIGestureRecognizerState.ended {
            if remoteView.center.x < 75 {
                // Move off to the left
                UIView.animate(withDuration: 0.3, animations: {
                    remoteView.center = CGPoint(x: remoteView.center.x - 200, y: remoteView.center.y + 50)
                    remoteView.alpha = 0
                    print("THIS IS WHY@!!!!!!!!")
                    self.room!.disconnect()
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
                        UIApplication.shared.keyWindow?.rootViewController = viewController
                        self.dismiss(animated: true, completion: nil)
                    }
                })
                return
            }
            else if remoteView.center.x > (view.frame.width - 75) {
                // Move off to the right side
                UIView.animate(withDuration: 0.3, animations: {
                    remoteView.center = CGPoint(x: remoteView.center.x + 200, y: remoteView.center.y + 50)
                    remoteView.alpha = 0
                    print("THIS IS WHY!!!!!!!!!")
                    self.room!.disconnect()
                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
                        UIApplication.shared.keyWindow?.rootViewController = viewController
                        self.timer.pauseAnimation()

                        self.dismiss(animated: true, completion: nil)
                    }
                })
                return
//                UIView.animate(withDuration: 0.3, animations: {
//                    remoteView.center = CGPoint(x: remoteView.center.x + 200, y: remoteView.center.y + 50)
//                    remoteView.alpha = 0
//                })
            }
        }
    }
    
    func validateTimer() {
    checkTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: (#selector(VideoViewController.checkRoom)), userInfo: nil, repeats: false)
    }
    
    @objc func runTimer() {
        self.timer.animateOuterToValue(100, duration: 30) {
            print("DOOOOOOOONE!")
            //self.room?.disconnect()
            self.performSegue(withIdentifier: "toDecide", sender: nil)
        }
    }
    
    @objc func checkRoom() {
        print("Checking the room now!")
        if(self.group == "MM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MM")
        } else if(self.group == "MF") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else if(self.group == "FM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else {
            self.groupsRef = Database.database().reference(withPath: "groups").child("FF")
        }
        
         let ref = self.groupsRef.child(self.newRoomID!)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            let currentRoom = ChatRoom(snapshot: snapshot as! DataSnapshot)
            if currentRoom.timerStarted == false {
                print("This is an empty room!")
                self.room?.disconnect()
                //ref.removeValue()
                emptyRoom = true
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
                    UIApplication.shared.keyWindow?.rootViewController = viewController
                    self.timer.pauseAnimation()
                    self.dismiss(animated: true, completion: nil)
                }
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
    
    func connectToRoom() {
        print("CONNECTING TO ROOM")
        let connectOptions = TVIConnectOptions.init(token: self.token!) { (builder) in
            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
            
            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = self.newRoomName!
        }
        
        self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
        self.showRoomUI(inRoom: true)
    }
    
    func showCountdown() {
        self.performSegue(withIdentifier: "toCountdown", sender: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareLocalMedia()
        self.connectToRoom()
        remoteView.layer.cornerRadius = 10;
        remoteView.layer.masksToBounds = true;
        validateTimer()
        var timer = Timer.scheduledTimer(timeInterval: 7, target: self, selector: #selector(VideoViewController.runTimer), userInfo: nil, repeats: false)
        print("This is the token" + self.token!)
        
        divisor = (view.frame.width / 2) / 0.61
        
        if(self.group == "MM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MM")
        } else if(self.group == "MF") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else if(self.group == "FM") {
            self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
        } else {
            self.groupsRef = Database.database().reference(withPath: "groups").child("FF")
        }
        let ref = self.groupsRef.child(self.newRoomID!)
        ref.observe(.childChanged, with: { (snapshot) in
            if(snapshot.value! as! Bool == true) {
                print("ATTTTENTION TIMER SHOULD START")
                
            }
            
        
            
        })

        
//        spinner1.style = .custom(size: CGSize(width: 1000, height: 1000), image: spinnerImage!)
//        spinner2.style = .custom(size: CGSize(width: 1000, height: 1000), image: spinnerImage!)
//        spinner3.style = .custom(size: CGSize(width: 1000, height: 1000), image: spinnerImage!)
//        spinner4.style = .custom(size: CGSize(width: 1000, height: 1000), image: spinnerImage!)
        //print(userName!)
        //print(token!)
        //print(self.group!)
        // Do any additional setup after loading the view.
    }
    
  
    override func viewDidAppear(_ animated: Bool) {
        self.showCountdown()
        print(self.newRoomName!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupRemoteVideoView() {
        // Creating `TVIVideoView` programmatically
        //self.remoteView = TVIVideoView.init(frame: CGRect.zero, delegate:self)
        
        //self.view.insertSubview(self.remoteView!, at: 4)
        
        // `TVIVideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
        //self.remoteView!.contentMode = .scaleAspectFit;
        
//        let centerX = NSLayoutConstraint(item: self.remoteView!,
//                                         attribute: NSLayoutAttribute.centerX,
//                                         relatedBy: NSLayoutRelation.equal,
//                                         toItem: self.view,
//                                         attribute: NSLayoutAttribute.centerX,
//                                         multiplier: 1,
//                                         constant: 0);
//        self.view.addConstraint(centerX)
//        let centerY = NSLayoutConstraint(item: self.remoteView!,
//                                         attribute: NSLayoutAttribute.centerY,
//                                         relatedBy: NSLayoutRelation.equal,
//                                         toItem: self.view,
//                                         attribute: NSLayoutAttribute.centerY,
//                                         multiplier: 1,
//                                         constant: 0);
//        self.view.addConstraint(centerY)
//        let width = NSLayoutConstraint(item: self.remoteView!,
//                                       attribute: NSLayoutAttribute.width,
//                                       relatedBy: NSLayoutRelation.equal,
//                                       toItem: self.view,
//                                       attribute: NSLayoutAttribute.width,
//                                       multiplier: 1,
//                                       constant: 0);
//        self.view.addConstraint(width)
//        let height = NSLayoutConstraint(item: self.remoteView!,
//                                        attribute: NSLayoutAttribute.height,
//                                        relatedBy: NSLayoutRelation.equal,
//                                        toItem: self.view,
//                                        attribute: NSLayoutAttribute.height,
//                                        multiplier: 1,
//                                        constant: 0);
//        self.view.addConstraint(height)
    }
    // MARK: Private
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }
        
        previewView.layer.cornerRadius = self.previewView.frame.height/2
        previewView.layer.borderWidth = 1.0
        previewView.layer.borderColor = UIColor.clear.cgColor
        previewView.layer.masksToBounds = false
        previewView.clipsToBounds = true
        
        // Preview our local camera track in the local video preview view.
        camera = TVICameraCapturer(source: .frontCamera, delegate: self)
        localVideoTrack = TVILocalVideoTrack.init(capturer: camera!)
        if (localVideoTrack == nil) {
            logMessage(messageText: "Failed to create video track")
        } else {
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            
            logMessage(messageText: "Video track created")
            
            // We will flip camera on tap.
            let tap = UITapGestureRecognizer(target: self, action: #selector(VideoViewController.flipCamera))
            self.previewView.addGestureRecognizer(tap)
        }
    }
    
    @objc func flipCamera() {
        if (self.camera?.source == .frontCamera) {
            self.camera?.selectSource(.backCameraWide)
        } else {
            self.camera?.selectSource(.frontCamera)
        }
    }
    
    func prepareLocalMedia() {
        
        // We will share local audio and video when we connect to the Room.
        
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init()
            
            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
        
        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            self.startPreview()
        }
    }
    
    // Update our UI based upon if we are in a Room or not
    func showRoomUI(inRoom: Bool) {
//        //self.micButton.isHidden = !inRoom
//        UIApplication.shared.isIdleTimerDisabled = inRoom
//        //self.titleLabel.isHidden = inRoom
//        self.timer.isHidden = !inRoom
//
//        self.messageLabel.isHidden = inRoom
    }
    

    
    func cleanupRemoteParticipant() {
        if ((self.participant) != nil) {
            if ((self.participant?.videoTracks.count)! > 0) {
                self.participant?.videoTracks[0].removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        self.participant = nil
    }
    
    func logMessage(messageText: String) {
        //messageLabel.text = messageText
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toDecide") {
            let viewController: DecideViewController = segue.destination as! DecideViewController
            viewController.senderID = self.token!
            viewController.roomName = self.newRoomID!
            viewController.senderName = self.userName!
        }
        if(segue.identifier == "toCountdown") {
            let viewController: CountdownViewController = segue.destination as! CountdownViewController
            viewController.imageOne = self.image1!
            viewController.imageTwo = self.image2!
        }
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

// ===========================================================================

// MARK: TVIRoomDelegate
extension VideoViewController : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        // At the moment, this example only supports rendering one Participant at a time.
        print("I am the storm")
        print("messageText: Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
//        if(host) {
//            let newRoom = ChatRoom(roomName: newRoomName!, tokenString: self.token!, numOfParticipants: 1)
//            let ref = Database.database().reference(withPath: "groups").child(self.group!)
//            let info = ["roomName": newRoomName, "tokenString": self.token!, "numOfParticipants": 1] as [String : Any]
//
//            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//
//            var randomString : NSMutableString = NSMutableString(capacity: 20)
//
//            for i in 0 ..< 20 {
//                var length = UInt32 (letters.length)
//                var rand = arc4random_uniform(length)
//                randomString.appendFormat("%C", letters.character(at: Int(rand)))
//            }
//            self.newRoomID = randomString as String
//            let itemRef = ref.child(randomString as String)
//            itemRef.setValue(info)
//        }
        
//        if (room.participants.count > 0) {
//            self.participant = room.participants[0]
//            self.participant?.delegate = self
//            if(host) {
//            let roomRef = self.groupsRef.child(self.newRoomID!)
//            roomRef.removeValue()
//            }
//            self.timer.animateOuterToValue(100, duration: 30) {
//                print("DOOOOOOOONE!")
//                //self.room?.disconnect()
//                //self.dismiss(animated: true, completion: nil)
//            }
//        }
        if (room.participants.count > 0) {
            self.participant = room.participants[0]
            self.participant?.delegate = self
        }
        print("I connected to a room in VideoViewController!")
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("messageText: Disconncted from room \(room.name), error = \(String(describing: error))")
        print("I find myself in this peculiar situation")
        self.cleanupRemoteParticipant()
        self.room = nil
        
//        if(host) {
//            if(self.group! == "MM" || self.group! == "FF") {
//            let roomRef = self.groupsRef.child(self.newRoomID!)
//            roomRef.removeValue()
//            }
//            else if(self.group! == "FM" || self.group == "MF") {
//                let roomRef = Database.database().reference(withPath: "groups").child(self.group!).child(self.newRoomID!)
//                roomRef.removeValue()
//            }
//        }
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print("messageText: Failed to connect to room with error")
        self.room = nil
        
        self.showRoomUI(inRoom: false)
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.timer.pauseAnimation()

            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        if (self.participant == nil) {
            self.participant = participant
            self.participant?.delegate = self
        }
        
        self.connected = true
        let roomRef = self.groupsRef.child(self.newRoomID!)
        //roomRef.removeValue()
        
        //self.timer.animateOuterToValue(100, duration: 30) {
            //print("DOOOOOOOONE!")
            //self.room?.disconnect()
            //self.dismiss(animated: true, completion: nil)
        //}
        
        // delete ref at database
//        if(!host) {
//
//            self.timer.animateOuterToValue(100, duration: 30) {
//                print("DOOOOOOOONE!")
//                self.room?.disconnect()
//                self.dismiss(animated: true, completion: nil)
//            }
//        }
    
        print("messageText: Room \(room.name), Participant \(participant.identity) connected")
    }
    
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
            cleanupRemoteParticipant()
            self.room?.disconnect()
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.timer.pauseAnimation()

            self.dismiss(animated: true, completion: nil)
        }
        print("messageText: Room \(room.name), Participant \(participant.identity) disconnected")
    }
    
}

// MARK: TVIParticipantDelegate
extension VideoViewController : TVIParticipantDelegate {
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        print("messageText: Participant \(participant.identity) added video track")
        
        if (self.participant == participant) {
            if (self.group! == "MM" || self.group! == "FF") {
                self.groupsRef = Database.database().reference(withPath: "groups").child(self.group!)
            } else {
                self.groupsRef = Database.database().reference(withPath: "groups").child("MF")
            }
            let ref = self.groupsRef.child(self.newRoomID!)
            print(groupsRef)
            ref.updateChildValues([
                "timerStarted": true
                ])
            
            videoTrack.addRenderer(self.remoteView)
        }
        setupRemoteVideoView()
    }
    
    func participant(_ participant: TVIParticipant, removedVideoTrack videoTrack: TVIVideoTrack) {
        print("messageText: Participant \(participant.identity) removed video track")
        
        if (self.participant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        print("messageText: Participant \(participant.identity) added audio track")
        
    }
    
    func participant(_ participant: TVIParticipant, removedAudioTrack audioTrack: TVIAudioTrack) {
        print("messageText: Participant \(participant.identity) removed audio track")
    }
    
    func participant(_ participant: TVIParticipant, enabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        print("messageText: Participant \(participant.identity) enabled \(type) track")
    }
    
    func participant(_ participant: TVIParticipant, disabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        print("messageText: Participant \(participant.identity) disabled \(type) track")
    }
}

// MARK: TVIVideoViewDelegate
extension VideoViewController : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension VideoViewController : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        self.previewView.shouldMirror = (source == .frontCamera)
    }
}
