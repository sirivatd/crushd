//
//  PoolViewController.swift
//  crushd
//
//  Created by Don Sirivat on 2/4/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit
import Firebase

class PoolViewController: UIViewController {
    
    let randomAdjectives: [String] = ["Macho","Like","Abiding","Nutritious","Lovely","Tranquil","Scary","Omniscient","Undesirable","Erratic","Horrible","Animated","Quack","Ruthless","Ignorant","Absorbing","Prickly","Irate","Violent","Powerful","Concerned","Nostalgic","Chilly","Conscious","Awesome","Sweltering","Icy","Imported","Unkempt","Political"]
    let randomColors: [String] = ["aqua", "black", "blue", "fuchsia", "gray", "green",
                                  "lime", "maroon", "navy", "olive", "orange", "purple", "red",
                                  "silver", "teal", "white", "yellow"]
    let nouns: [String] = ["Shake","Sense","Bite","Alarm","Wave","Dolphin","Knee","Roll","Activity","River","Notebook","Mind","Use","Connection","Copper","Child","Skate","Book","Engine","Alligator","Mouse","Moose","Volleyball","Rule","Theory","Reward","Zoo","Monkey","Salamander","Teacher","Tooth","Appliance","Man","Twist","Drop","Cap","Substance"]
    
    var token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzQ5Y2ZiMTNiYzJlMGZmNmI0N2YzODg5YTBlODFjMWIwLTE1MTgwNDY3NzciLCJncmFudHMiOnsiaWRlbnRpdHkiOiJBd2Vzb21lbmF2eVJ1bGUiLCJ2aWRlbyI6e319LCJpYXQiOjE1MTgwNDY3NzcsImV4cCI6MTUxODA1MDM3NywiaXNzIjoiU0s0OWNmYjEzYmMyZTBmZjZiNDdmMzg4OWEwZTgxYzFiMCIsInN1YiI6IkFDZDNjMDVhYmUwMzMzMjEyZTMzNmRiMjQ3YmU0ZTFjNTYifQ.4-CyEBk2aHrqmeFLyuTlHRTk49Z1E-M7lnctWugTlyg"
    
    var groupsRef: DatabaseReference?

    var group: String = "FM"
    var host: Bool = false
    var chatRoom: ChatRoom?
    
    var newRoomName: String?
    var newRoomID: String?
    var shapeLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Hello")
        view.backgroundColor = UIColor.backgroundColor
        setupCircleLayers()
       
        // Do any additional setup after loading the view.
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
    
    private func setupCircleLayers() {
        pulsatingLayer = createCircleShapeLayer(strokeColor: .clear, fillColor: UIColor.pulsatingFillColor)
        view.layer.addSublayer(pulsatingLayer)
        animatePulsatingLayer()
        
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
        
        pulsatingLayer.add(animation, forKey: "pulsing")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
