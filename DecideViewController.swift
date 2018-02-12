//
//  DecideViewController.swift
//  crushd
//
//  Created by Don Sirivat on 1/19/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import UIKit

class DecideViewController: UIViewController {

    @IBOutlet weak var profileImage: UIImageView!
    
    var senderID: String?
    var senderName: String?
    var roomName: String?
    
    @IBAction func dismissPressed() {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Home") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
        }
    }
    @IBAction func heartPressed() {
        self.performSegue(withIdentifier: "toChat", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toChat") {
            let viewController: ChatViewController = segue.destination as! ChatViewController
            
            viewController.senderDisplayName = self.senderName
            viewController.senderId = self.senderID
            viewController.roomName = self.roomName!
        }
    }
    
   
    

}
