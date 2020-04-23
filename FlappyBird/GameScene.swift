//
//  GameScene.swift
//  FlappyBird
//
//  Created by 蓑輪 竜輝 on 2020/04/21.
//  Copyright © 2020 ryuki.minowa. All rights reserved.
//

import UIKit
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    //MARK: -propaty
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var bird: SKSpriteNode!
    var backGroundMusic: SKAudioNode!
    
    // スコア用
    var score = 0
    var itemScore = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    var itemScoreLabelNode: SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    //MARK: -method
    
    // SKView上にsceneが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        //重力の設定
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        self.physicsWorld.contactDelegate = self
        
        // 背景色の指定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        self.addChild(scrollNode)
        
        // 壁用ノードを追加
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // item用ノードを追加
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // BGM用ノードを追加
        let BGM = SKAction.repeatForever(SKAction.playSoundFileNamed("BGM.mp3", waitForCompletion: true))
        self.run(BGM)
        
        // 各スプライトを表示する
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
    }
    
    // 画面がタップされた時に呼び出される
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
        // 鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        // 鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    // 衝突したときに呼び出される
    func didBegin(_ contact: SKPhysicsContact) {
        // gemeoverの時なにもしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体とぶつかった
            print("score up")
            score += 1
            scoreLabelNode.text = "score: \(score)"
            // BESTSCOREの更新
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            // itemとぶつかった
            print("itemscore up")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score: \(itemScore)"
            
            // サウンド追加
            let itemGetSound = SKAction.playSoundFileNamed("pa1.mp3", waitForCompletion: true)
            self.run(itemGetSound)
            
//            if
            // 衝突したアイテムを消去
            contact.bodyA.node?.removeFromParent()

        } else {
            // 壁か地面とぶつかった
            print("game over")
            
            // サウンド追加
            let GameOverSound = SKAction.playSoundFileNamed("tin1.mp3", waitForCompletion: true)
            self.run(GameOverSound)
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)

            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "score: \(score)"
        itemScore = 0
        itemScoreLabelNode.text = "Item Score: \(itemScore)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zPosition = 0
        
        let resetRoll = SKAction.rotate(toAngle: 0, duration: 0)
        bird.run(resetRoll)
        
        itemNode.removeAllChildren()
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupGround() {
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest  //画質よりも処理速度優先
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分をスクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左スクロールとリセットを無限ループ
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトの表示位置を決定
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // sptireを表示する位置を指定する(positionは中心の位置を指定する)
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),    //needNumberだけ表示を行う
                y: groundTexture.size().height / 2
            )
            
            // spriteにアクションを指定する
            sprite.run(repeatScrollGround)
            
            // 物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリーを追加
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突時に動かないように設定
            sprite.physicsBody?.isDynamic = false
            
            // spriteを親ノードに追加
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupCloud() {
        //地面の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest  //画質よりも処理速度優先
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分をスクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左スクロールとリセットを無限ループ
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // groundのスプライトの表示位置を決定
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            
            // sptireを表示する位置を指定する(positionは中心の位置を指定する)
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),    //needNumberだけ表示を行う
                y: self.frame.size.height - cloudTexture.size().height / 2
            )
            sprite.zPosition = -100
            
            // spriteにアクションを指定する
            sprite.run(repeatScrollCloud)
            
            // spriteを親ノードに追加
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //壁の移動距離を計算
        let moveDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 壁の移動アクション作成
        let moveWall = SKAction.moveBy(x: -moveDistance,y: 0, duration: 4)
        
        // 壁自身を取り除くアクション作成
        let removeWall = SKAction.removeFromParent()
        
        // 移動と取り除きを順位実行するアクション作成
        let wallAction = SKAction.sequence([moveWall, removeWall])
        
        // 鳥のサイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
    
        // 壁の隙間の大きさを設定
        let slit_length = birdSize.height * 3
        
        // 壁の隙間の振れ幅を設定
        let random_y_range = birdSize.height * 3
        
        // 下の壁のY軸下限位置を設定
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - (slit_length + wallTexture.size().height + random_y_range) / 2
        
        // 壁を生成するアクション作成
        let createWallAction = SKAction.run( {
            // 壁関連のノードを乗せるノード作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50
            
            ///0~random_y_rangeまでのランダム値生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を追加して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁の生成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            // 物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突時に動かないように設定
            under.physicsBody?.isDynamic = false

            wall.addChild(under)
            
            // 上側の壁の生成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            // 物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突時に動かないように設定
            upper.physicsBody?.isDynamic = false
    
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory     // 自身(scoreNode)のカテゴリーを設定
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory   // 衝突相手(bird)のカテゴリーを設定
            
            wall.addChild(scoreNode)
            
            wall.run(wallAction)
            
//            // 物理演算を設定する
//            wall.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
//
//            // 衝突時に動かないように設定
//            wall.physicsBody?.isDynamic = false
            
            self.wallNode.addChild(wall)
        })
        
        // 次に壁を作成するまでの時間を設定
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁作成と待ち時間を無限ループ
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAction, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 2種類の鳥の画像を読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2枚のテクスチャを交互に表示する
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let frap = SKAction.repeatForever(textureAnimation)
        
        //spriteを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー追加
        bird.physicsBody?.categoryBitMask = birdCategory    // 自身(scoreNode)のカテゴリーを設定
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory  //衝突した際に跳ね返る
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory    // 衝突相手のカテゴリーを設定
        
        // アニメーションの追加
        bird.run(frap)
        
        // birdを親ノードに追加
        self.addChild(bird)
    }
    
    func setupItem() {
        let itemTexture = SKTexture(imageNamed: "piman" )
        itemTexture.filteringMode = .linear
        
        //itemの移動距離を計算
        let moveDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        // ground.heightを取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        // itemを生成するアクション作成
        let createItemAction = SKAction.run( {
            // itemのSpriteの作成
            let item = SKSpriteNode(texture: itemTexture)
            
            // Action関連生成
            // 2~10までのランダム値生成
            let random_time = Double(CGFloat.random(in: 2..<10))
            // itemの移動アクション作成
            let moveItem = SKAction.moveBy(x: -moveDistance, y: 0, duration: random_time)
            // item自身を取り除くアクション作成
            let removeItem = SKAction.removeFromParent()
            // 移動と取り除きを順位実行するアクション作成
            let itemAction = SKAction.sequence([moveItem, removeItem])
            
            /// itemのSpriteの設定
            // spritの拡大
            item.setScale(0.2)
            let itemLowerY = groundSize.height + item.size.height / 2
            let itemHigherY = self.frame.size.height - item.size.height / 2
            // itemLowerY~itemHigherYまでのランダム値生成
            let item_randomY = CGFloat.random(in: itemLowerY..<itemHigherY)
            item.position = CGPoint(x: self.frame.size.width + item.size.width / 2, y: item_randomY)
            item.zPosition = -50
            
            // 物理演算を設定
            item.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: item.size.width - (item.size.width / 3), height: item.size.height - (item.size.height / 3)))
            
            // 衝突判定
            item.physicsBody?.isDynamic = false
            item.physicsBody?.categoryBitMask = self.itemCategory    //自身のcategoryの設定
            item.physicsBody?.contactTestBitMask = self.birdCategory    // 衝突物の判定
            
            
            item.run(itemAction)

            // itemNodeに追加
            self.itemNode.addChild(item)
        })
        
        // 次に壁を作成するまでの時間を設定
        let itemWaitAnimation = SKAction.wait(forDuration: 1)
        // 壁作成と待ち時間を無限ループ
        let repeatItemForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAction, itemWaitAnimation]))
        
        itemNode.run(repeatItemForeverAnimation)
    }
    

    
    func setupScoreLabel() {
        // score
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score: \(score)"
        self.addChild(scoreLabelNode)
        
        // bestscore
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score: \(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //itemscore
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score: \(itemScore)"
        self.addChild(itemScoreLabelNode)
        
    }
    
    func collisionsound() {
        
    }
}
