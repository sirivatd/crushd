//
//  HomeViewController.swift
//  crushd
//
//  Created by Don Sirivat on 12/11/17.
//  Copyright © 2017 Don Sirivat. All rights reserved.
//

import UIKit
import EMAlertController
import TwilioVideo
import Firebase

var firstTime: Bool = false
class HomeViewController: UIViewController {
    
    let crushdPink = UIColor(red: 249, green: 62, blue: 157)

    let ref = Database.database().reference(withPath: "users")
    let user = Auth.auth().currentUser

    var group: String?
    var accessToken: String?
    
    let adjectives: [String] = ["Mammoth","Giant","Spotty","Boundless","Thoughtful","Barbarous","Languid","Chunky","Dizzy", "Unsightly", "Sore", "Fallacious", "Guiltless", "Ugly", "Zealous", "Black", "Aware", "Efficient", "Acid", "Industrious", "Blue-eyed", "Cold", "Tiny", "Frightening", "Naughty", "Soggy", "Tricky", "Nonchalant", "Spooky", "Curious", "Tired", "Relieved", "Elderly", "Violent", "Sulky", "Eminent", "Imaginary", "Billowy", "Fast", "Quick", "Possessive", "Waggish"]
    let colors: [String] = ["Salmon", "Plum", "DarkGoldenrod", "DarkOrchid", "Goldrenrod", "Linen","DarkOrange","AliceBlue","Thistle","LightYellow","SlateBlue", "SteelBlue","SteelBlue","Beige","Turquoise","PaleRed","Mint","Sienna","Magenta","Khaki","PeachPuff","LawnGreen","DarkRed","Lime","OliveGreen","SeaGreen","FloralWhite","DarkGray","Red","Maroon","Orange","RoyalPurple"]
    let nouns: [String] = ["Shake","Sense","Bite","Alarm","Wave","Dolphin","Knee","Roll","Activity","River","Notebook","Mind","Use","Connection","Copper","Child","Skate","Book","Engine","Alligator","Mouse","Moose","Volleyball","Rule","Theory","Reward","Zoo","Monkey","Salamander","Teacher","Tooth","Appliance","Man","Twist","Drop","Cap","Substance"]
    
    let messages: [String] =
        ["Looking good, you got this", "They're going to love you", "Go get 'em tiger", "Damnnnnnnnn", "You should model", "Magezine cover material right here", "Your face belongs in the limelight", "I can put you on a Hallmark card", "They're going to drool over you", "Have fun and don't take it too seriously", "Don't play too hard to get ;)"]
    
    
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    var remoteView: TVIVideoView?
    var randomName: String?
    
    // at https://www.twilio.com/console/video/runtime/testing-tools
    
    // Configure remote URL to fetch token from
    var tokenUrl = "http://cryptic-tundra-90870.herokuapp.com/?identity=RedGorilla"
    
    @IBOutlet weak var previewView: TVIVideoView!
    @IBOutlet weak var logoBar: UIView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var  messageLabel: UILabel!
    @IBOutlet weak var messageView: UIView!
    
    @IBAction func connectPressed() {
        self.performSegue(withIdentifier: "toLoading", sender: nil)
    }
    
    @IBAction func backPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showTutorial() {
        //self.performSegue(withIdentifier: "toTutorial", sender: nil)
        firstTime = false
    }
    
    func randomNameGenerator() -> String {
        let randomNumber1 = UInt32(arc4random_uniform(UInt32(self.adjectives.count-1)))
        let randomNumber2 = UInt32(arc4random_uniform(UInt32(self.colors.count - 1)))
        let randomNumber3 = UInt32(arc4random_uniform(UInt32(self.nouns.count - 1)))
        
        let randomWord1 = self.adjectives[Int(randomNumber1)]
        let randomWord2 = self.colors[Int(randomNumber2)]
        let randomWord3 = self.nouns[Int(randomNumber3)]
        
        let randomWord = randomWord1+randomWord2+randomWord3
        
        return randomWord
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.connectButton.isHidden = true
        self.randomName = randomNameGenerator()
        let conditionItemRef = self.ref.child(user!.uid)
        conditionItemRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let m = snapshot.value as? [String:Any?]
            let imageName = (m?["imageURL"])!
            let name = (m?["name"])!
            let firstTime = (m?["firstTime"])!
            self.group = (m?["group"])! as! String
            self.accessToken = (m?["token"])! as! String
            print(self.group!)
            self.connectButton.isHidden = false

        })
        print("Pussynibblets!")
        logoBar.layer.shadowColor = UIColor.black.cgColor
        logoBar.layer.shadowOpacity = 1
        logoBar.layer.shadowOffset = CGSize.zero
        logoBar.layer.shadowRadius = 10
       // messageView.layer.cornerRadius = 10
       // messageView.layer.masksToBounds = true
        connectButton.layer.shadowColor = UIColor.black.cgColor
        connectButton.layer.shadowOpacity = 1
        connectButton.layer.shadowOffset = CGSize.zero
        connectButton.layer.shadowRadius = 10
        connectButton.layer.borderWidth = 1
        connectButton.layer.borderColor = UIColor.clear.cgColor
        connectButton.layer.cornerRadius = 5
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.startPreview()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func flipCamera() {
        if (self.camera?.source == .frontCamera) {
            self.camera?.selectSource(.backCameraWide)
        } else {
            self.camera?.selectSource(.frontCamera)
        }
    }
    
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }
        
        // Preview our local camera track in the local video preview view.
        camera = TVICameraCapturer(source: .frontCamera, delegate: self as! TVICameraCapturerDelegate)
        localVideoTrack = TVILocalVideoTrack.init(capturer: camera!)
        if (localVideoTrack == nil) {
            //logMessage(messageText: "Failed to create video track")
        } else {
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            
            //logMessage(messageText: "Video track created")
            
            // We will flip camera on tap.
            let tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.flipCamera))
            self.previewView.addGestureRecognizer(tap)
        }
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
    
    func showRoomUI(inRoom: Bool) {
//        self.connectButton.isHidden = inRoom
//        self.roomTextField.isHidden = inRoom
//        self.roomLine.isHidden = inRoom
//        self.roomLabel.isHidden = inRoom
//        self.micButton.isHidden = !inRoom
//        self.disconnectButton.isHidden = !inRoom
        //UIApplication.shared.isIdleTimerDisabled = inRoom
    }
    
    func setupRemoteVideoView() {
        // Creating `TVIVideoView` programmatically
        self.remoteView = TVIVideoView.init(frame: CGRect.zero, delegate:self)
        
        self.view.insertSubview(self.remoteView!, at: 0)
        
        // `TVIVideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFit;
        
        let centerX = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutAttribute.centerX,
                                         relatedBy: NSLayoutRelation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutAttribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutAttribute.centerY,
                                         relatedBy: NSLayoutRelation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutAttribute.centerY,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: self.remoteView!,
                                       attribute: NSLayoutAttribute.width,
                                       relatedBy: NSLayoutRelation.equal,
                                       toItem: self.view,
                                       attribute: NSLayoutAttribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: self.remoteView!,
                                        attribute: NSLayoutAttribute.height,
                                        relatedBy: NSLayoutRelation.equal,
                                        toItem: self.view,
                                        attribute: NSLayoutAttribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toLoading") {
            let viewController: LoadingViewController = segue.destination as! LoadingViewController
            //viewController.token = self.accessToken
            viewController.userName = self.randomName!
            
            viewController.token = self.accessToken!
            viewController.group = self.group!
        }
    }

}

// ==============================================================================

// MARK: TVIRoomDelegate
extension HomeViewController : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        // At the moment, this example only supports rendering one Participant at a time.
        
        //logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        
        if (room.participants.count > 0) {
            self.participant = room.participants[0]
            self.participant?.delegate = self
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        //logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")
        
        self.cleanupRemoteParticipant()
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        //logMessage(messageText: "Failed to connect to room with error")
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        if (self.participant == nil) {
            self.participant = participant
            self.participant?.delegate = self
        }
        //logMessage(messageText: "Room \(room.name), Participant \(participant.identity) connected")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
        if (self.participant == participant) {
            cleanupRemoteParticipant()
        }
        //logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIParticipantDelegate
extension HomeViewController : TVIParticipantDelegate {
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        //logMessage(messageText: "Participant \(participant.identity) added video track")
        
        if (self.participant == participant) {
            setupRemoteVideoView()
            videoTrack.addRenderer(self.remoteView!)
        }
    }
    
    func participant(_ participant: TVIParticipant, removedVideoTrack videoTrack: TVIVideoTrack) {
        //logMessage(messageText: "Participant \(participant.identity) removed video track")
        
        if (self.participant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        //logMessage(messageText: "Participant \(participant.identity) added audio track")
        
    }
    
    func participant(_ participant: TVIParticipant, removedAudioTrack audioTrack: TVIAudioTrack) {
        //logMessage(messageText: "Participant \(participant.identity) removed audio track")
    }
    
    func participant(_ participant: TVIParticipant, enabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        //logMessage(messageText: "Participant \(participant.identity) enabled \(type) track")
    }
    
    func participant(_ participant: TVIParticipant, disabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        //logMessage(messageText: "Participant \(participant.identity) disabled \(type) track")
    }
}

// MARK: TVIVideoViewDelegate
extension HomeViewController : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension HomeViewController : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        self.previewView.shouldMirror = (source == .frontCamera)
    }
}
