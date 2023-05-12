//
//  FirstViewController.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 18/12/22.
//

import UIKit

class FirstViewController: UIViewController, ResizeTransitable {

    var viewToResize: UIView { scanButton }
    var viewToHide: [UIView] { [] }

    @IBOutlet weak var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }        
}
