//
//  MainViewController.swift
//  crushd
//
//  Created by Don Sirivat on 2/5/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class MainViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var whiteView: UIView!
    @IBOutlet weak var startButton: UIButton!


    func setupView() {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: "Fun Fair", ofType: "mov")!)
        let player = AVPlayer(url: path)
        
        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = self.videoView.frame
        self.videoView.layer.addSublayer(newLayer)
        newLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        player.play()
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.videoDidPlayToEnd(_:)), name: NSNotification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification"), object: player.currentItem)
    }
    
    @objc func videoDidPlayToEnd(_ notification: Notification) {
        let player: AVPlayerItem = notification.object as! AVPlayerItem
        player.seek(to: kCMTimeZero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.whiteView.layer.shadowColor = UIColor.black.cgColor
        self.whiteView.layer.shadowOpacity = 1
        self.whiteView.layer.shadowOffset = CGSize.zero
        self.whiteView.layer.shadowRadius = 10
        self.whiteView.layer.borderWidth = 1
        self.whiteView.layer.borderColor = UIColor.clear.cgColor
        self.whiteView.layer.cornerRadius = 5
        self.whiteView.layer.opacity = 0.7
        
        self.startButton.layer.shadowColor = UIColor.black.cgColor
        self.startButton.layer.shadowOpacity = 1
        self.startButton.layer.shadowOffset = CGSize.zero
        self.startButton.layer.shadowRadius = 10
        self.startButton.layer.borderWidth = 1
        self.startButton.layer.borderColor = UIColor.clear.cgColor
        self.startButton.layer.cornerRadius = 5
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
