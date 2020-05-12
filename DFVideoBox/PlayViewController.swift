//
//  PlayViewController.swift
//  DFVideoBox
//
//  Created by Ben on 2020/5/12.
//  Copyright © 2020 DoFun. All rights reserved.
//

import UIKit
import AVKit

class PlayViewController: UIViewController {

    var filePath: String!
    var playVc: AVPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        playVc = AVPlayerViewController()
        playVc.player = AVPlayer(url: URL(fileURLWithPath: filePath))
        playVc.view.frame = view.bounds
        playVc.showsPlaybackControls = true
        
        view.addSubview(playVc.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVc.player?.play()
    }

}
