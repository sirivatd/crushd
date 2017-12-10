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

class LandingViewController: UIViewController {
    
    @IBOutlet weak var userGender: TTSegmentedControl!
    @IBOutlet weak var userInterest: TTSegmentedControl!

    
    @IBOutlet weak var videoView: UIView!
    
    func setupView() {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: "sd_movie", ofType: "mov")!)
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
    
    func setUpSegments() {
        userGender.itemTitles = ["MALE", "FEMALE"]
        userInterest.itemTitles = ["MEN", "WOMAN"]
        
        userGender.selectedTextFont = UIFont(name: "Futura", size: 13.0)!
        userInterest.selectedTextFont = UIFont(name: "Futura", size: 13.0)!

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        self.setUpSegments()
        self.setupView()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

