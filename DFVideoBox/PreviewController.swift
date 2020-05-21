//
//  PreviewController.swift
//  DFVideoBox
//
//  Created by Ben on 2020/5/21.
//  Copyright © 2020 DoFun. All rights reserved.
//

import UIKit

class PreviewController: UITableViewController {

    var datas: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datas = ["audio_1.m4a","audio_2.mp3","videoNoSound.mp4","nature.mp4","1.mp4","2.mp4","3.mp4","R0.MOV","R90.MOV","R180.MOV","R270.MOV"]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId")!
        cell.textLabel?.text = datas[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = datas[indexPath.row]
        let playVc = PlayViewController()
        playVc.filePath = Bundle.main.path(forResource: fileName, ofType: nil)
        navigationController?.pushViewController(playVc, animated: true)
    }
}
