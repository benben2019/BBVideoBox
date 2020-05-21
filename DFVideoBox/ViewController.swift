//
//  ViewController.swift
//  DFVideoBox
//
//  Created by Ben on 2020/5/12.
//  Copyright © 2020 DoFun. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    
    var dataSource = [String]()
    let tableView = UITableView(frame: .zero, style: .plain)
    let activity = UIActivityIndicatorView(style: .medium)
    
    let onePath = Bundle.main.path(forResource: "1.mp4", ofType: nil)!
    let twoPath = Bundle.main.path(forResource: "2.mp4", ofType: nil)!
    let threePath = Bundle.main.path(forResource: "3.mp4", ofType: nil)!
    let naturePath = Bundle.main.path(forResource: "nature.mp4", ofType: nil)!
    
    let audioOnePath = Bundle.main.path(forResource: "audio_1.m4a", ofType: nil)!
    let audioTwoPath = Bundle.main.path(forResource: "audio_2.mp3", ofType: nil)!
    let videoNoSoundPath = Bundle.main.path(forResource: "videoNoSound.mp4", ofType: nil)!
    
    let R0Path = Bundle.main.path(forResource: "R0.MOV", ofType: nil)!
    let R90Path = Bundle.main.path(forResource: "R90.MOV", ofType: nil)!
    let R180Path = Bundle.main.path(forResource: "R180.MOV", ofType: nil)!
    let R270Path = Bundle.main.path(forResource: "R270.MOV", ofType: nil)!
    
    var assetVideoTrack: AVAssetTrack?
    var assetAudioTrack: AVAssetTrack?
    /// 音视频组合对象
    var mutableComposition: AVMutableComposition?
    var cacheComposition: AVMutableComposition?
    /// 视频画面合成器
    var mutableVideoComposition: AVMutableVideoComposition?
    /// 音频合成器
    var mutableAudioMix: AVMutableAudioMix?
    
    /// 视频指令集
    var instructions: [AVMutableVideoCompositionInstruction] = []
    /// 音频指令集
    var audioMixParams: [AVMutableAudioMixInputParameters] = []
    
    var trackDegree: Int = 0
    var totalDuration: CMTime?
    
    /// 标记是否在执行拼接操作
    var isAppending = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Demos"
        setUpUI()
        dataSource = ["时长裁剪","旋转","加水印","更换声音","混音","变速","视频拼接","组合操作"]
    }
    
    fileprivate func setUpUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ].forEach{ $0.isActive = true }
        
        activity.hidesWhenStopped = true
        view.addSubview(activity)
        
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}

extension ViewController: UITableViewDataSource,UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId")!
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 获取音视频资源
        let asset = AVAsset.init(url: URL(fileURLWithPath: naturePath))
        if !asset.isPlayable { return }
        
        activity.startAnimating()
        
        perform(with: asset)
        
        switch indexPath.row {
        case 0:
            // 从第6s开始  时长5.5s
            let range = CMTimeRangeMake(start: CMTimeMake(value: 3600, timescale: 600), duration: CMTimeMake(value: 3300, timescale: 600))
            rangeVideo(range)
            
//            rangeVideo(from: 20, to: 26.4)
        case 1:
            rotateVideo(90)
        case 2:
            addWaterMark(UIImage(named: "witcher")!, relativeRect: .init(x: 0.6, y: 0.2, width: 0.3, height: 0))
//            let imageUrl = URL(string: "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1590041390826&di=5312005de6e1776501fa9a5f766417a1&imgtype=0&src=http%3A%2F%2Fimage.biaobaiju.com%2Fuploads%2F20190928%2F19%2F1569669470-HUgmtnIZPl.jpg")!
//            addWaterMark(imageUrl, relativeRect: .init(x: 0.6, y: 0.2, width: 0.3, height: 0))
            
//            let gifUrl = URL(string: "http://imgsrc.baidu.com/forum/w=580/sign=daa65c96d200baa1ba2c47b37711b9b1/d51572f082025aafe194efb1f8edab64034f1a2f.jpg")!
//            let gifUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "haicao.gif", ofType: nil)!)
//            addWaterMark(gifUrl,relativeRect: .init(x: 0.6, y: 0.2, width: 0.3, height: 0))
        case 3:
            replaceAudio(audioTwoPath)
        case 4:
            mixSound(audioTwoPath,at: 3)
        case 5:
            geerBox(scale: 2)
        case 6:
            append(R180Path)
        case 7:
            // 裁前10s + 旋转90° + 拼接 + 混音 + 变速 + 裁前6s
            rangeVideo(to: 10).rotateVideo(90).append(R0Path).append(R90Path).mixSound(audioTwoPath).geerBox(scale: 2)//.rangeVideo(to: 6)
        default:
            print("do nothing...")
        }
//        print("😀合成完毕！即将输出..")
//        print(mutableComposition!.tracks(withMediaType: .video))
//        print(mutableComposition!.tracks(withMediaType: .audio))
        outPut()
    }
}

// MARK: public
extension ViewController {
    
    @discardableResult
    func rangeVideo(_ timeRange: CMTimeRange) -> Self {
    
        // 轨道裁剪
        for compositionTrack in mutableComposition!.tracks(withMediaType: .video) {
            subTimeRange(compositionTrack: compositionTrack, range: timeRange)
        }
        for compositionTrack in mutableComposition!.tracks(withMediaType: .audio) {
            subTimeRange(compositionTrack: compositionTrack, range: timeRange)
        }
        
        totalDuration = timeRange.duration
        
        return self
    }
    
    @discardableResult
    func rangeVideo(from: Float = 0, to: Float) -> Self {
        if from >= to { fatalError("传入的时间有误！") }
        let seconds = Float(CMTimeGetSeconds(totalDuration!))
        let value = Float(totalDuration!.value)
        let fromTime = CMTimeMake(value: Int64(from / seconds * value), timescale: totalDuration!.timescale)
        let toTime = CMTimeMake(value: Int64((to - from) / seconds * value), timescale: totalDuration!.timescale)
        rangeVideo(CMTimeRangeMake(start: fromTime, duration: toTime))
        return self
    }
    
    @discardableResult
    func rotateVideo(_ degress: CGFloat) -> Self {
        
        if degress.truncatingRemainder(dividingBy: 360) == 0 { return self }
        
        performVideoComposition()
        
        for instruction in mutableVideoComposition!.instructions {
            let ins = instruction as! AVMutableVideoCompositionInstruction
            let layerInstruction = ins.layerInstructions.first as! AVMutableVideoCompositionLayerInstruction
            
            var t1: CGAffineTransform
            var t2: CGAffineTransform
            var renderSize: CGSize
            
            let originWidth = mutableVideoComposition!.renderSize.width
            let originHeight = mutableVideoComposition!.renderSize.height
            
            // 保证角度在90的倍数 360度范围内
            // degress % 360.0 % 90.0
            let deg = degress - degress.truncatingRemainder(dividingBy: 360).truncatingRemainder(dividingBy: 90)
            
            if deg == 90 {
                t1 = CGAffineTransform(translationX: originHeight, y: 0)
                renderSize = CGSize(width: originHeight, height: originWidth)
            } else if deg == 180 {
                t1 = CGAffineTransform(translationX: originWidth, y: originHeight)
                renderSize = CGSize(width: originWidth, height: originHeight)
            } else if deg == 270 {
                t1 = CGAffineTransform(translationX: 0, y: originWidth)
                renderSize = CGSize(width: originHeight, height: originWidth)
            } else {
                t1 = CGAffineTransform(translationX: 0, y: 0)
                renderSize = CGSize(width: originWidth, height: originHeight)
            }
            
            t2 = t1.rotated(by: deg / 180 * .pi)
            
            mutableVideoComposition!.renderSize = renderSize
            mutableComposition!.naturalSize = renderSize
            
            var existingTransform: CGAffineTransform = .identity
            if !layerInstruction.getTransformRamp(for: totalDuration!, start: &existingTransform, end: nil, timeRange: nil) {
                layerInstruction.setTransform(t2, at: .zero)
            } else {
                let newt = existingTransform.concatenating(t2)
                layerInstruction.setTransform(newt, at: .zero)
            }
            
            ins.layerInstructions = [layerInstruction]
        }
        return self
    }
    
    @discardableResult
    func addWaterMark(_ image: UIImage,relativeRect: CGRect) -> Self {
        
        performVideoComposition()
        
        let videoSize = mutableVideoComposition!.renderSize
        
        let waterLayer = CALayer()
        let videoLayer = CALayer()
        let parentLayer = CALayer()
        
        parentLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        var h: CGFloat = 0
        if relativeRect.size.height > 0 {
            h = videoSize.height * relativeRect.height
        } else {
            h = videoSize.width * relativeRect.size.width * image.size.height / image.size.width
        }
        
        let x = videoSize.width * relativeRect.origin.x
        let y = videoSize.height * relativeRect.origin.y
        let w = videoSize.width * relativeRect.size.width
        
        let imageRect = CGRect(x: x, y: y, width: w, height: h)
        waterLayer.contents = image.cgImage!
        waterLayer.frame = imageRect
        
//        let textLayer = CATextLayer()
//        textLayer.string = "www.dofun.com"
//        textLayer.font = "Helvetica-Bold" as CFTypeRef
//        textLayer.fontSize = 26
//        textLayer.foregroundColor = UIColor.red.cgColor
//        textLayer.backgroundColor = UIColor.white.cgColor
//        textLayer.alignmentMode = .center
//        textLayer.opacity = 0.6
//        textLayer.frame = .init(x: 0, y: 0, width: 200, height: 30)
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(waterLayer)
//        parentLayer.addSublayer(textLayer)
        let animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        mutableVideoComposition?.animationTool = animationTool
        return self
    }
    
    @discardableResult
    func addWaterMark(_ url: URL,relativeRect: CGRect) -> Self {
        
        performVideoComposition()
        
        let videoSize = mutableVideoComposition!.renderSize
        
        let waterLayer = CALayer()
        let videoLayer = CALayer()
        let parentLayer = CALayer()
        
        parentLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        var gifWidth: CGFloat
        var gifHeight: CGFloat
        guard let gifSource = source else { return self }
        let dict = CGImageSourceCopyPropertiesAtIndex(gifSource, 0, nil) as! [AnyHashable : Any]
        gifWidth = CGFloat((dict[kCGImagePropertyPixelWidth as String] as? NSNumber)?.floatValue ?? 0.0)
        gifHeight = CGFloat((dict[kCGImagePropertyPixelHeight as String] as? NSNumber)?.floatValue ?? 0.0)
        
        var h: CGFloat = 0
        if relativeRect.size.height > 0 {
            h = videoSize.height * relativeRect.height
        } else {
            h = videoSize.width * relativeRect.size.width * gifHeight / gifWidth
        }
        
        let x = videoSize.width * relativeRect.origin.x
        let y = videoSize.height * relativeRect.origin.y
        let w = videoSize.width * relativeRect.size.width
        
        let imageRect = CGRect(x: x, y: y, width: w, height: h)
        
        waterLayer.frame = imageRect
        waterLayer.add(createAnimationForGif(gifSource: gifSource,dic: dict), forKey: "gif")
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(waterLayer)
        
        mutableVideoComposition?.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        return self
    }
    
    @discardableResult
    func replaceAudio(_ audioPath: String) -> Self {
        if !FileManager.default.fileExists(atPath: audioPath) { return self }
        let audioAsset = AVURLAsset(url: URL(fileURLWithPath: audioPath))
        guard audioAsset.isPlayable else { return self }
        mutableComposition?.tracks(withMediaType: .audio).forEach({ (audioTrack) in
            mutableComposition?.removeTrack(audioTrack)
        })
        
        let minDuration = CMTimeMinimum(audioAsset.duration, totalDuration!)
        for track in audioAsset.tracks(withMediaType: .audio) {
            let compositionAudioTrack = mutableComposition!.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionAudioTrack!.insertTimeRange(CMTimeRange(start: .zero, duration: minDuration), of: track, at: .zero)
            } catch {
                print(error.localizedDescription)
            }
        }
        return self
    }
    
    @discardableResult
    func append(_ path: String) -> Self {
        isAppending = true
        perform(with: cacheComposition!)
        
        let appendAeest = AVAsset(url: URL(fileURLWithPath: path))
        guard appendAeest.isPlayable else { return self }
        
        var appendVideoTrack: AVAssetTrack?
        var appendAudioTrack: AVAssetTrack?
        
        if appendAeest.tracks(withMediaType: .video).count > 0 {
            appendVideoTrack = appendAeest.tracks(withMediaType: .video).first!
        }
        if appendAeest.tracks(withMediaType: .audio).count > 0 {
            appendAudioTrack = appendAeest.tracks(withMediaType: .audio).first!
        }
        
        var natureSize = appendVideoTrack!.naturalSize
        let degrees = getDegree(appendVideoTrack!.preferredTransform)
        
        if appendVideoTrack != nil {
            performVideoComposition()
            
            // 添加一条视频轨道
            let newVideoTrack = mutableComposition!.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            // 给新加的视频轨道插入视频 并 设置好该对轨道接入的时间点和时长
            do {
                try newVideoTrack!.insertTimeRange(CMTimeRange(start: .zero, duration: appendAeest.duration), of: appendVideoTrack!, at: totalDuration!)
            } catch {
                print(error.localizedDescription)
            }
            
            // 处理视频方向和渲染尺寸等问题
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: totalDuration!, duration: appendAeest.duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: newVideoTrack!)
            let renderSize = mutableVideoComposition!.renderSize
            
            if degrees == 90 || degrees == 270 {
                natureSize = CGSize(width: natureSize.height, height: natureSize.width)
            }
            
            let scale = min(renderSize.width / natureSize.width,renderSize.height / natureSize.height)
            
            let translate = CGPoint(x: (renderSize.width - natureSize.width * scale) * 0.5, y: (renderSize.height - natureSize.height * scale) * 0.5)
            
            let t1 = appendVideoTrack!.preferredTransform
            let t2 = CGAffineTransform(a: t1.a * scale, b: t1.b * scale, c: t1.c * scale, d: t1.d * scale, tx: t1.tx * scale + translate.x, ty: t1.ty * scale + translate.y)
            layerInstruction.setTransform(t2, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            instructions.append(instruction)
            mutableVideoComposition?.instructions = instructions
        }
        
        if appendAudioTrack != nil {
            var audioTrack = mutableComposition!.tracks(withMediaType: .audio).last
            if audioTrack == nil {
                audioTrack = mutableComposition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            do {
                try audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: appendAeest.duration), of: appendAudioTrack!, at: totalDuration!)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        totalDuration = CMTimeAdd(totalDuration!, appendAeest.duration)
        return self
    }
    
    @discardableResult
    func mixSound(_ path: String,at: Float64 = 0,volume: Float = 1.0, mixVolume: Float = 1.0) -> Self {
        
        let mixAeest = AVURLAsset(url: URL(fileURLWithPath: path))
        if !mixAeest.isPlayable { return self }
        
        let insertTime = CMTimeMakeWithSeconds(at, preferredTimescale: totalDuration!.timescale)
        
        performAudioComposition()
        
        if CMTimeCompare(totalDuration!, insertTime) != 1 { return self }
        
        // 设置原音音量
        for param in audioMixParams {
            param.setVolume(volume, at: .zero)
        }
        
        // 从音频资源中取出音频
        let mixAudioTrack = mixAeest.tracks(withMediaType: .audio).first
        // 添加一条音频轨道
        let compositionAudioTrack = mutableComposition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        // 音频轨道插入音频，且设置时间点
        let endPoint = CMTimeAdd(insertTime, mixAeest.duration)
        let duration = CMTimeSubtract(CMTimeMinimum(endPoint, totalDuration!), insertTime)
        
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: mixAudioTrack!, at: insertTime)
        } catch {
            print(error.localizedDescription)
        }
        
        // 设置混音音量
        let mixParam = AVMutableAudioMixInputParameters(track: mixAudioTrack)
        mixParam.setVolume(mixVolume, at: insertTime)
        audioMixParams.append(mixParam)
        
        mutableAudioMix?.inputParameters = audioMixParams
        return self
    }
    
    @discardableResult
    func geerBox(scale: Int64) -> Self {
        
        // 处理视频
        mutableComposition?.tracks(withMediaType: .video).forEach({ (videoTrack) in
            videoTrack.scaleTimeRange(videoTrack.timeRange, toDuration: CMTimeMake(value: videoTrack.timeRange.duration.value / scale, timescale: videoTrack.timeRange.duration.timescale))
        })
        
        // 处理音频
        mutableComposition?.tracks(withMediaType: .audio).forEach({ (audioTrack) in
            audioTrack.scaleTimeRange(audioTrack.timeRange, toDuration: CMTimeMake(value: audioTrack.timeRange.duration.value / scale, timescale: audioTrack.timeRange.duration.timescale))
        })
        
        totalDuration = CMTimeMultiplyByFloat64(totalDuration!, multiplier: 1 / Float64(scale))
        
        // 处理视频指令
        var insertPoint: CMTime = .zero
        for instruction in instructions {
            let duration = instruction.timeRange.duration
            instruction.timeRange = CMTimeRangeMake(start: insertPoint, duration: CMTime(value: duration.value / scale, timescale: duration.timescale))
            insertPoint = CMTimeAdd(instruction.timeRange.start, instruction.timeRange.duration)
        }
        
        // 确保最后一条指令能到视频的最后，否则导出的时候出现报错问题
        // 例如totalDuration = 14.67334  而lastInstruction的endTime只有14.6716667，此时需要调整lastInstruction的timeRange与totalDuration保持一致
//        print(instructions)
        if let lastInstruction = instructions.last {
            lastInstruction.timeRange = CMTimeRangeMake(start: lastInstruction.timeRange.start, duration: CMTimeSubtract(totalDuration!, lastInstruction.timeRange.start))
        }
        return self
    }
}

// MARK: private
extension ViewController {
    
    func perform(with asset: AVAsset) {
        print(asset.tracks(withMediaType: .video))
        print(asset.tracks(withMediaType: .audio))
        // 1. 拿到视频资源中的视频和音频
        if asset.tracks(withMediaType: .video).count != 0 {
            assetVideoTrack = asset.tracks(withMediaType: .video).first
        }
        if asset.tracks(withMediaType: .audio).count != 0 {
            assetAudioTrack = asset.tracks(withMediaType: .audio).first
        }
        
        if isAppending { return }
        
        // 2. 创建一个音视频组合对象
        mutableComposition = AVMutableComposition()
        // 2.1 添加一条视频轨道
        let compositionVideoTrack = mutableComposition!.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            // 2.2 给视频轨道插入视频，并设置好时间
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetVideoTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        // 2.3 添加一条音频轨道
        let compositionAudioTrack = mutableComposition!.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            // 2.4 给音频轨道插入音频，并设置好时间
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetAudioTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        
        // assetVideoTrack!.nominalFrameRate 获取帧率fps
        totalDuration = mutableComposition!.duration
        trackDegree = getDegree(assetVideoTrack!.preferredTransform)
        mutableComposition!.naturalSize = compositionVideoTrack!.naturalSize
        
        if trackDegree % 360 > 0 {
            performVideoComposition()
        }
        
        // 视频拼接的时候用到
        cacheComposition = mutableComposition
    }
    
    func performVideoComposition() {
        
        if mutableVideoComposition != nil { return }
        // 1. 创建视频画面合成器
        mutableVideoComposition = AVMutableVideoComposition()
        // 2. 设置视频帧率
        mutableVideoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30) // 30fps
        // 3. 设置渲染尺寸
        mutableVideoComposition?.renderSize = assetVideoTrack!.naturalSize
        // 4. 创建视频指令对象并设置时长
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mutableComposition!.duration)
        // 5. 创建视频图层指令对象并进行矩阵校正
        let videoTrack = mutableComposition!.tracks(withMediaType: .video).first!
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        // 矩阵校正
        layerInstruction.setTransform(transform(degree: trackDegree, natureSize: assetVideoTrack!.naturalSize), at: .zero)
        
        // 6. 给视频指令对象的图层指令赋值
        instruction.layerInstructions = [layerInstruction]
        instructions.append(instruction)
        // 7. 给视频画面合成器的指令集赋值
        mutableVideoComposition?.instructions = instructions
        
        if trackDegree == 90 || trackDegree == 270 {
            mutableVideoComposition!.renderSize = .init(width: assetVideoTrack!.naturalSize.height, height: assetVideoTrack!.naturalSize.width)
        }
    }
    
    func performAudioComposition() {
        
        if mutableAudioMix != nil { return }
        // 创建音频合成器
        mutableAudioMix = AVMutableAudioMix()
        
        for audioTrack in mutableComposition!.tracks(withMediaType: .audio) {
            let audioMixParam = AVMutableAudioMixInputParameters(track: audioTrack)
            audioMixParam.setVolume(1.0, at: .zero)
            audioMixParams.append(audioMixParam)
        }
        mutableAudioMix?.inputParameters = audioMixParams
    }

    // 矩阵校正
    // x' = ax + cy + tx     y' = bx + dy + ty
    func transform(degree: Int,natureSize: CGSize) -> CGAffineTransform {
        if degree == 90 {
//            let t1 = CGAffineTransform(translationX: natureSize.height, y: 0)
//            let t2 = t1.rotated(by: 90.0 / 180.0 * .pi)
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: natureSize.height, ty: 0)
        } else if degree == 180 {
//            let t1 = CGAffineTransform(translationX: natureSize.width, y: natureSize.height)
//            let t2 = t1.rotated(by: .pi)
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: natureSize.width, ty: natureSize.height)
        } else if degree == 270 {
//            let t1 = CGAffineTransform(translationX: 0, y: natureSize.width)
//            let t2 = t1.rotated(by: -90.0 / 180.0 * .pi)
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: natureSize.width)
        } else {
            return .identity
        }
    }
    
    func getDegree(_ t: CGAffineTransform) -> Int {
        var degree: Int = 0
        if t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 {
            degree = 90
        } else if t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0 {
            degree = 270
        } else if t.a == -1 && t.b == 0 && t.c == 0 && t.d == -1 {
            degree = 180
        } else if t.a == 1 && t.b == 0 && t.c == 0 && t.d == 1 {
            degree = 0
        }
        return degree
    }
    
    func subTimeRange(compositionTrack: AVMutableCompositionTrack, range: CMTimeRange) {
        let endPoint = CMTimeAdd(range.start, range.duration)
        
        if CMTimeCompare(totalDuration!, endPoint) != -1 { // 去除尾部多余的
            compositionTrack.removeTimeRange(CMTimeRangeMake(start: endPoint, duration: CMTimeSubtract(totalDuration!, endPoint)))
        }
        
        if CMTimeGetSeconds(range.start) != 0 { // 去除头部多余的
            compositionTrack.removeTimeRange(CMTimeRangeMake(start: .zero, duration: range.start))
        }
    }
    
    func createAnimationForGif(gifSource: CGImageSource,dic: [AnyHashable: Any]) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = true
        
        var frams: [CGImage] = []
        var delayTimes: [CGFloat] = []
        let frameCount = CGImageSourceGetCount(gifSource)
        var totalTime: CGFloat = 0
        var times: [NSNumber] = []
        
        for i in 0..<frameCount {
            frams.append(CGImageSourceCreateImageAtIndex(gifSource, i, nil)!)
            let gifDic = dic[kCGImagePropertyGIFDictionary] as? [AnyHashable : Any]
            if let gifDictionary = gifDic {
                delayTimes.append(gifDictionary[kCGImagePropertyGIFUnclampedDelayTime] as! CGFloat)
                totalTime += gifDictionary[kCGImagePropertyGIFUnclampedDelayTime] as! CGFloat
            }
        }
        
        var currentTime: CGFloat = 0
        for i in 0..<delayTimes.count {
            times.append(NSNumber(value: Float(currentTime / totalTime)))
            currentTime += delayTimes[i]
        }
        
        var images: [CGImage] = []
        for i in 0..<delayTimes.count {
            images.append(frams[i])
        }
        
        animation.keyTimes = times
        animation.values = images.count > 0 ? images : frams
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = CFTimeInterval(totalTime) == 0 ? 1 : CFTimeInterval(totalTime)
        animation.repeatCount = MAXFLOAT
        return animation
    }
    
    func outPut() {
        let exportSession = AVAssetExportSession(asset: mutableComposition!, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = mutableVideoComposition
        exportSession?.audioMix = mutableAudioMix
        exportSession?.timeRange = CMTimeRangeMake(start: .zero, duration: totalDuration!)
        let filePath = createFilePath()
        exportSession?.outputURL = URL(fileURLWithPath: filePath)
        exportSession?.outputFileType = .mp4
//        exportSession?.fileLengthLimit =
        
        exportSession?.exportAsynchronously(completionHandler: {
            self.clear()
            DispatchQueue.main.async {
                self.activity.stopAnimating()
                switch exportSession?.status {
                case .completed:
                    print("completed!")
                    let playVc = PlayViewController()
                    playVc.filePath = filePath
                    self.navigationController?.pushViewController(playVc, animated: true)
                default:
                    break
                }
            }
        })
    }
    
    func clear() {
        assetAudioTrack = nil
        assetVideoTrack = nil
        mutableComposition = nil
        cacheComposition = nil
        mutableVideoComposition = nil
        mutableAudioMix = nil
        isAppending = false
        instructions = []
        audioMixParams = []
        trackDegree = 0
        totalDuration = nil
    }
    
    func createFilePath() -> String {
        return NSTemporaryDirectory() + String(Date().timeIntervalSince1970) + ".mp4"
    }
    
    func saveVideoToAlbum(_ filePath: String) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
        }) { (success, error) in
            DispatchQueue.main.async {
                var alert: UIAlertController
                if let err = error {
                    print("保存失败: ",err.localizedDescription)
                    alert = UIAlertController(title: "保存失败", message: error?.localizedDescription, preferredStyle: .alert)
                } else {
                    print("保存成功！")
                    alert = UIAlertController(title: "保存成功", message: "", preferredStyle: .alert)
                }
                let okAction = UIAlertAction(title: "确定", style: .default) { _ in}
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
