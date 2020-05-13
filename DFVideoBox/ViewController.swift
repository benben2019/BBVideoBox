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
    var filePath = NSTemporaryDirectory() + String(Date().timeIntervalSince1970) + ".mp4"
    
    let onePath = Bundle.main.path(forResource: "1.mp4", ofType: nil)!
    let twoPath = Bundle.main.path(forResource: "2.mp4", ofType: nil)!
    let threePath = Bundle.main.path(forResource: "3.mp4", ofType: nil)!
    
    var assetVideoTrack: AVAssetTrack?
    var assetAudioTrack: AVAssetTrack?
    var duration: CMTime?
    
    var mutableComposition = AVMutableComposition()
    var mutableVideoComposition: AVMutableVideoComposition?
    
    var trackDegree: Int = 0
    
    let activity = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpUI()
        dataSource = ["时长裁剪","旋转"]
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
        // 从第6s开始  时长5.5s
//        let range = CMTimeRangeMake(start: CMTimeMake(value: 3600, timescale: 600), duration: CMTimeMake(value: 3300, timescale: 600))
//        rangeVideo(range)
        
//        rangeVideo(from: 20, to: 26.4)
        rotateVideo(90)
        
        outPut()
    }
}

extension ViewController {
    
    func rangeVideo(_ timeRange: CMTimeRange) {
    
        // 轨道裁剪
        for compositionTrack in mutableComposition.tracks(withMediaType: .video) {
            subTimeRange(compositionTrack: compositionTrack, range: timeRange)
        }
        for compositionTrack in mutableComposition.tracks(withMediaType: .audio) {
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
    
    func rotateVideo(_ degress: Int) {
        for instruction in mutableVideoComposition!.instructions {
            let ins = instruction as! AVMutableVideoCompositionInstruction
            let layerInstruction = ins.layerInstructions.first as! AVMutableVideoCompositionLayerInstruction
            
            var t1: CGAffineTransform
            var t2: CGAffineTransform
            var renderSize: CGSize
            
            let originWidth = mutableVideoComposition!.renderSize.width
            let originHeight = mutableVideoComposition!.renderSize.height
            
            // 保证角度在90的倍数 360度范围内
            let deg = degress - degress % 360 % 90
            
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
            
            t2 = t1.rotated(by: CGFloat(deg / 180) * CGFloat.pi)
            
            mutableVideoComposition!.renderSize = renderSize
            mutableComposition.naturalSize = renderSize
            
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
}

extension ViewController {
    
    func perform(with asset: AVAsset) {
        // 1. 拿到视频中的视频和音频
        if asset.tracks(withMediaType: .video).count != 0 {
            assetVideoTrack = asset.tracks(withMediaType: .video).first
        }
        if asset.tracks(withMediaType: .audio).count != 0 {
            assetAudioTrack = asset.tracks(withMediaType: .audio).first
        }
        
        
        let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetVideoTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        // assetVideoTrack!.nominalFrameRate 获取帧率fps
        duration = mutableComposition.duration
        trackDegree = getDegree(assetVideoTrack!.preferredTransform)
        mutableComposition.naturalSize = compositionVideoTrack!.naturalSize
        
        let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: assetAudioTrack!, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func performVideoComposition() {
        if mutableVideoComposition != nil { return }
        mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30) // 30fps
        mutableVideoComposition?.renderSize = assetVideoTrack!.naturalSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mutableComposition.duration)
        
        let videoTrack = mutableComposition.tracks(withMediaType: .video).first!
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(transform(degree: trackDegree, natureSize: assetVideoTrack!.naturalSize), at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        mutableVideoComposition?.instructions = [instruction]
        
        if trackDegree == 90 || trackDegree == 270 {
            mutableVideoComposition!.renderSize = .init(width: assetVideoTrack!.naturalSize.height, height: assetVideoTrack!.naturalSize.width)
        }
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
    
    func outPut() {
        let exportSession = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = mutableVideoComposition
        exportSession?.timeRange = CMTimeRangeMake(start: .zero, duration: duration!)
        exportSession?.outputURL = URL(fileURLWithPath: filePath)
        exportSession?.outputFileType = .mp4
//        exportSession?.fileLengthLimit =
        
        exportSession?.exportAsynchronously(completionHandler: {
            switch exportSession?.status {
            case .completed:
                print("completed!")
                DispatchQueue.main.async {
                    self.activity.stopAnimating()
                    let playVc = PlayViewController()
                    playVc.filePath = self.filePath
                    self.navigationController?.pushViewController(playVc, animated: true)
                    
                    // 保存到相册
//                    self.saveVideoToAlbum()
                }
            case .failed:
                print("failed: ",exportSession!.error?.localizedDescription as Any)
            case .cancelled:
                print("canceled")
            case .exporting:
                print("exporting...")
            default:
                break
            }
        })
    }
    
    func saveVideoToAlbum() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: self.filePath))
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
