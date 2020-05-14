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

    let tableView = UITableView(frame: .zero, style: .plain)
    var dataSource = [String]()
    
    let onePath = Bundle.main.path(forResource: "1.mp4", ofType: nil)!
    let twoPath = Bundle.main.path(forResource: "2.mp4", ofType: nil)!
    let threePath = Bundle.main.path(forResource: "3.mp4", ofType: nil)!
    let naturePath = Bundle.main.path(forResource: "nature.mp4", ofType: nil)!
    let nature1Path = Bundle.main.path(forResource: "nature1.mov", ofType: nil)!
    
    var assetVideoTrack: AVAssetTrack?
    var assetAudioTrack: AVAssetTrack?
    var duration: CMTime?
    
    var mutableComposition: AVMutableComposition?
    var mutableVideoComposition: AVMutableVideoComposition?
    
    var trackDegree: Int = 0
    
    let activity = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Demos"
        setUpUI()
        dataSource = ["时长裁剪","旋转","加水印","更换声音","视频拼接"]
    }
    
    fileprivate func setUpUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
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
        
        let asset = AVAsset.init(url: URL(fileURLWithPath: onePath))
        if !asset.isPlayable { return }
        
        activity.startAnimating()
        
        perform(with: asset)
        performVideoComposition()
        
        switch indexPath.row {
        case 0:
            // 从第6s开始  时长5.5s
            let range = CMTimeRangeMake(start: CMTimeMake(value: 3600, timescale: 600), duration: CMTimeMake(value: 3300, timescale: 600))
            rangeVideo(range)
            
//            rangeVideo(from: 20, to: 26.4)
        case 1:
            rotateVideo(90)
        case 2:
//            addWateMark(image: UIImage(named: "witcher")!, relativeRect: .init(x: 0.6, y: 0.2, width: 0.3, height: 0))
            let gifUrl = URL(string: "http://imgsrc.baidu.com/forum/w=580/sign=daa65c96d200baa1ba2c47b37711b9b1/d51572f082025aafe194efb1f8edab64034f1a2f.jpg")!  // 要翻墙
//            let gifUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "haicao.gif", ofType: nil)!)
            addWaterMark(gifUrl,relativeRect: .init(x: 0.6, y: 0.2, width: 0.3, height: 0))
        case 3:
            replaceAudio(twoPath)
        case 4:
            append(twoPath)
        default:
            print("do noting...")
        }
        
        outPut()
    }
}

// MARK: public
extension ViewController {
    
    func rangeVideo(_ timeRange: CMTimeRange) {
    
        // 轨道裁剪
        for compositionTrack in mutableComposition!.tracks(withMediaType: .video) {
            subTimeRange(compositionTrack: compositionTrack, range: timeRange)
        }
        for compositionTrack in mutableComposition!.tracks(withMediaType: .audio) {
            subTimeRange(compositionTrack: compositionTrack, range: timeRange)
        }
        
        duration = timeRange.duration
    }
    
    func rangeVideo(from: Float, to: Float) {
        if from >= to { fatalError("传入的时间有误！") }
        let seconds = Float(CMTimeGetSeconds(duration!))
        let value = Float(duration!.value)
        let fromTime = CMTimeMake(value: Int64(from / seconds * value), timescale: duration!.timescale)
        let toTime = CMTimeMake(value: Int64((to - from) / seconds * value), timescale: duration!.timescale)
        rangeVideo(CMTimeRangeMake(start: fromTime, duration: toTime))
    }
    
    func rotateVideo(_ degress: CGFloat) {
        
        if degress.truncatingRemainder(dividingBy: 360) == 0 { return }
        
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
            if !layerInstruction.getTransformRamp(for: duration!, start: &existingTransform, end: nil, timeRange: nil) {
                layerInstruction.setTransform(t2, at: CMTime.zero)
            } else {
                let newt = existingTransform.concatenating(t2)
                layerInstruction.setTransform(newt, at: .zero)
            }
            
            ins.layerInstructions = [layerInstruction]
        }
    }
    
    func addWateMark(image: UIImage,relativeRect: CGRect) {
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
        
        mutableVideoComposition?.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    func addWaterMark(_ url: URL,relativeRect: CGRect) {
        let videoSize = mutableVideoComposition!.renderSize
        
        let waterLayer = CALayer()
        let videoLayer = CALayer()
        let parentLayer = CALayer()
        
        parentLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = .init(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        var gifWidth: CGFloat
        var gifHeight: CGFloat
        guard let gifSource = source else { return }
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
    }
    
    func replaceAudio(_ audioPath: String) {
        if !FileManager.default.fileExists(atPath: audioPath) { return }
        let audioAsset = AVURLAsset(url: URL(fileURLWithPath: audioPath))
        guard audioAsset.isPlayable else { return }
        let audioTrack = mutableComposition?.tracks(withMediaType: .audio).first
        mutableComposition?.removeTrack(audioTrack!)
        
        let minDuration = CMTimeMinimum(audioAsset.duration, duration!)
        for track in audioAsset.tracks(withMediaType: .audio) {
            let compositionAudioTrack = mutableComposition!.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionAudioTrack!.insertTimeRange(CMTimeRange(start: .zero, duration: minDuration), of: track, at: .zero)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func append(_ path: String) {
        let appendAeest = AVAsset(url: URL(fileURLWithPath: path))
        guard appendAeest.isPlayable else { return }
        
        perform(with: appendAeest)
        
        var appendVideoTrack: AVAssetTrack?
        var appendAudioTrack: AVAssetTrack?
        
        if appendAeest.tracks(withMediaType: .video).count > 0 {
            appendVideoTrack = appendAeest.tracks(withMediaType: .video).first!
        }
        if appendAeest.tracks(withMediaType: .audio).count > 0 {
            appendAudioTrack = appendAeest.tracks(withMediaType: .audio).first!
        }
        
        let natureSize = appendVideoTrack!.naturalSize
        
        if appendVideoTrack != nil {
            performVideoComposition()
            
            // 加一条视频轨道
            let newVideoTrack = mutableComposition!.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            // 给新加的视频轨道插入视频资源 并 设置好该对轨道接入的时间点和时长
            do {
                try newVideoTrack!.insertTimeRange(CMTimeRange(start: .zero, duration: appendAeest.duration), of: appendVideoTrack!, at: duration!)
            } catch {
                print(error.localizedDescription)
            }
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: duration!, duration: appendAeest.duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: newVideoTrack!)
            
            
            instruction.layerInstructions = [layerInstruction]
            mutableVideoComposition?.instructions = [instruction]
        }
        
        if appendAudioTrack != nil {
            
        }
    }
}

// MARK: private
extension ViewController {
    
    func perform(with asset: AVAsset) {
        // 1. 拿到视频中的视频和音频
        if asset.tracks(withMediaType: .video).count != 0 {
            assetVideoTrack = asset.tracks(withMediaType: .video).first
        }
        if asset.tracks(withMediaType: .audio).count != 0 {
            assetAudioTrack = asset.tracks(withMediaType: .audio).first
        }
        
        mutableComposition = AVMutableComposition()
        
        let compositionVideoTrack = mutableComposition!.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetVideoTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        // assetVideoTrack!.nominalFrameRate 获取帧率fps
        duration = mutableComposition!.duration
//        trackDegree = getDegree(assetVideoTrack!.preferredTransform)
        mutableComposition!.naturalSize = compositionVideoTrack!.naturalSize
        
//        if trackDegree % 360 > 0 {
//            performVideoComposition()
//        }
        
        let compositionAudioTrack = mutableComposition!.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetAudioTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func performVideoComposition() {
//        if mutableVideoComposition != nil { return }
        mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30) // 30fps
        mutableVideoComposition?.renderSize = assetVideoTrack!.naturalSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mutableComposition!.duration)
        
        let videoTrack = mutableComposition!.tracks(withMediaType: .video).first!
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//        layerInstruction.setTransform(transform(degree: trackDegree, natureSize: assetVideoTrack!.naturalSize), at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        mutableVideoComposition?.instructions = [instruction]
        
//        if trackDegree == 90 || trackDegree == 270 {
//            mutableVideoComposition!.renderSize = .init(width: assetVideoTrack!.naturalSize.height, height: assetVideoTrack!.naturalSize.width)
//        }
    }
    
    func transform(degree: Int,natureSize: CGSize) -> CGAffineTransform {
        if degree == 90 {
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: natureSize.height, ty: 0)
        } else if degree == 180 {
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: natureSize.width, ty: natureSize.height)
        } else if degree == 270 {
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
        
        if CMTimeCompare(duration!, endPoint) != -1 {
            compositionTrack.removeTimeRange(CMTimeRangeMake(start: endPoint, duration: CMTimeSubtract(duration!, endPoint)))
        }
        
        if CMTimeGetSeconds(range.start) != 0 {
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
            let gifDic = dic[kCGImagePropertyGIFDictionary] as! [AnyHashable : Any]
            delayTimes.append(gifDic[kCGImagePropertyGIFUnclampedDelayTime] as! CGFloat)
            totalTime += gifDic[kCGImagePropertyGIFUnclampedDelayTime] as! CGFloat
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
        animation.values = images
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = CFTimeInterval(totalTime)
        animation.repeatCount = MAXFLOAT
        return animation
    }
    
    func outPut() {
        let exportSession = AVAssetExportSession(asset: mutableComposition!, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = mutableVideoComposition
        exportSession?.timeRange = CMTimeRangeMake(start: .zero, duration: duration!)
        let filePath = createFilePath()
        exportSession?.outputURL = URL(fileURLWithPath: filePath)
        exportSession?.outputFileType = .mp4
//        exportSession?.fileLengthLimit =
        
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.activity.stopAnimating()
                switch exportSession?.status {
                case .completed:
                    print("completed!")
                    let playVc = PlayViewController()
                    playVc.filePath = filePath
                    self.navigationController?.pushViewController(playVc, animated: true)
                    
                    // 保存到相册
                    //                    self.saveVideoToAlbum(filePath)
                    
                case .failed:
                    print("failed: ",exportSession!.error?.localizedDescription as Any)
                case .cancelled:
                    print("canceled")
                case .exporting:
                    print("exporting...")
                default:
                    break
                }
            }
        })
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






//
//   XPCropCommand.m
//   WAVideoBox
//
//   Created  by Hallfry on 2019/4/17
//   Modified by Hallfry
//   Copyright © 2019年 XPLO. All rights reserved.
//
   

//#import "XPCropCommand.h"
//
//
//@interface AVAssetTrack(XPAssetTrack)
//
//- (CGAffineTransform)getTransformWithCropRect:(CGRect)cropRect;
//
//@end
//
//@implementation AVAssetTrack(XPAssetTrack)
//- (CGAffineTransform)getTransformWithCropRect:(CGRect)cropRect {
//
//    CGSize renderSize = cropRect.size;
//    CGFloat renderScale = renderSize.width / cropRect.size.width;
//    CGPoint offset = CGPointMake(-cropRect.origin.x, -cropRect.origin.y);
//    double rotation = atan2(self.preferredTransform.b, self.preferredTransform.a);
//
//    CGPoint rotationOffset = CGPointMake(0, 0);
//    if (self.preferredTransform.b == -1.0) { // 倒着拍 -M_PI_2
//        rotationOffset.y = self.naturalSize.width;
//    } else if (self.preferredTransform.c == -1.0) { // 正着拍 M_PI_2
//        // 奇怪的偏移
//        rotationOffset.x = self.naturalSize.height;
//    } else if (self.preferredTransform.a == -1.0) { // 两侧拍 M_PI
//        rotationOffset.x = self.naturalSize.width;
//        rotationOffset.y = self.naturalSize.height;
//    }
//
//    CGAffineTransform transform = CGAffineTransformIdentity;
//    transform = CGAffineTransformScale(transform, renderScale, renderScale);
//    transform = CGAffineTransformTranslate(transform, offset.x + rotationOffset.x, offset.y + rotationOffset.y);
//    transform = CGAffineTransformRotate(transform, rotation);
//
//    return transform;
//}
//
//@end
//
//
//@implementation XPCropCommand
//
//- (void)performWithAsset:(AVAsset *)asset cropRect:(CGRect)cropRect {
//    [super performWithAsset:asset];
//
//    if ([[self.composition.mutableComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
//
//        [super performVideoCompopsition];
//
//        // 绿边问题，是因为宽或高不是偶数
//        int64_t renderWidth = round(cropRect.size.width);
//        int64_t renderHeight = round(cropRect.size.height);
//        if (renderWidth % 2 != 0) {
//            renderWidth -= 1;
//        }
//        if (renderHeight % 2 != 0) {
//            renderHeight -= 1;
//        }
//
//        AVMutableVideoCompositionInstruction *instruction = [self.composition.instructions lastObject];
//        AVMutableVideoCompositionLayerInstruction *layerInstruction = (AVMutableVideoCompositionLayerInstruction *)instruction.layerInstructions[0];
//        AVAssetTrack *videoTrack = self.assetVideoTrack;
//
//        [layerInstruction setTransform:[videoTrack getTransformWithCropRect:cropRect] atTime:kCMTimeZero];
//        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
//
//
//        self.composition.mutableVideoComposition.renderSize = CGSizeMake(renderWidth, renderHeight);
//    }
//}
//
//@end
