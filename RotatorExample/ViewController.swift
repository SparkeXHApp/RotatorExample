//
//  ViewController.swift
//  RotatorExample
//
//  Created by sfh on 2024/7/10.
//

import UIKit
import SFStyleKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapBtn.center = self.view.center
        self.view.sf.backgroundColor(.white).addSubview(tapBtn)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SparkRotator.shared.rotationToPortrait()
    }
    
    @objc func btnTap(_ sender: UIButton) {
        self.navigationController?.pushViewController(RotatorVC(), animated: true)   
    }
    
    lazy var tapBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.sf.frame(CGRect(x: 0, y: 0, width: 250, height: 60))
            .title("看视频", for: .normal)
            .titleColor(.blue, for: .normal)
            .titleFont(UIFont.systemFont(ofSize: 16.0, weight: .medium))
            .makeRadius(10.0)
            .makeBorder(color: .systemTeal, with: 1.0)
            .addTarget(self, action: #selector(btnTap(_:)), for: .touchUpInside)
        return btn
    }()

}

