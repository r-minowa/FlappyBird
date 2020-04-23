//
//  ViewController.swift
//  FlappyBird
//
//  Created by 蓑輪 竜輝 on 2020/04/20.
//  Copyright © 2020 ryuki.minowa. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SKViewに型を変更する
        let skView = self.view as! SKView
        
        // FPSを表示する
        skView.showsFPS = true

        // node数を表示する
        skView.showsNodeCount = true
        
        // シーンサイズをskViewと同じサイズで作成
        let scene = GameScene(size: skView.frame.size)        // GameSceneクラスを使うように指定 //fremeの代わりにboundsを使ってみる
        
        // skViewにsceneを表示する
        skView.presentScene(scene)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

