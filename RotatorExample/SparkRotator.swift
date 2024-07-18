//
//  SparkRotator.swift
//  RotatorExample
//
//  Created by sfh on 2024/7/16.
//

import UIKit

// MARK: - 可旋转的屏幕方向【枚举】
public enum SparkOrientationType: CaseIterable {
    case portrait           // 竖屏 手机头在上边
    case portraitUpsideDown // 竖屏 手机头在下边
    case landscapeLeft      // 横屏 手机头在左边
    case landscapeRight     // 横屏 手机头在右边
}

public class SparkRotator {
    
    /// 单例
    public static let shared = SparkRotator()
    
    /// 可否旋转
    public private(set) var isEnabled = true
    
    /// 是否允许转向 竖屏-手机头在下边 的方向，默认不允许
    public var isAllowPortraitUpsideDown: Bool = false {
        didSet {
            if !isAllowPortraitUpsideDown, currentOrientation == .portraitUpsideDown {
                rotationToPortrait()
            }
        }
    }
    
    /// 当前屏幕方向，默认竖屏，手机头在上边
    public private(set) var currentOrientation: UIInterfaceOrientationMask = .portrait {
        didSet {
            if currentOrientation != oldValue {
                updateCurrentOrientationState()
            }
        }
    }
    
    /// 是否锁定当前屏幕方向，默认为true，表示不会随设备摆动自动改变屏幕方向
    public var isLockOrientation = true {
        didSet {
            guard isLockOrientation != oldValue else { return }
            updateLockOrientationState()
        }
    }
    
    /// 是否正在竖屏
    public var isPortrait: Bool { currentOrientation == .portrait }
    
    /// 当前屏幕方向枚举值
    public var orientation: SparkOrientationType {
        switch currentOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .landscape:
            let deviceOrientation = UIDevice.current.orientation
            switch deviceOrientation {
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .portrait
            }
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    /// 当前屏幕方向发生改变的通知
    public static let orientationDidChangeNotification = Notification.Name("OrientationDidChangeNotification")
    /// 锁定屏幕方向发生改变的通知
    public static let lockOrientationDidChangeNotification = Notification.Name("LockOrientationDidChangeNotification")
    
    /// 屏幕方向发生改变的回调
    public var orientationMaskDidChange: ((_ orientationMask: UIInterfaceOrientationMask) -> ())?
    /// 锁定屏幕方向发生改变的回调
    public var lockOrientationDidChange: ((_ isLock: Bool) -> ())?
    
    // MARK: - 添加通知
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 通知方法
    
    /// 退到后台
    @objc func willResignActive() {
        isEnabled = false
    }
    
    /// 进到前台
    @objc func didBecomeActive() {
        isEnabled = true
    }
    
    /// 设备方向发生改变
    @objc func deviceOrientationDidChange() {
        guard isEnabled else { return }
        guard !isLockOrientation else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .unknown, .faceUp, .faceDown:
            return
        case .portraitUpsideDown:
            if !isAllowPortraitUpsideDown {
                return
            }
        default:
            break
        }

        let orientationMask = Self.toInterfaceOrientationMask(deviceOrientation)
        rotation(to: orientationMask)
    }
    
    
    // MARK: - 状态发生改变，更新回调并发出通知
    
    /// 当前屏幕方向发生改变
    private func updateCurrentOrientationState() {
        orientationMaskDidChange?(currentOrientation)
        NotificationCenter.default.post(name: Self.orientationDidChangeNotification, object: currentOrientation)
    }
    
    /// 锁定方向状态发生改变
    private func updateLockOrientationState() {
        lockOrientationDidChange?(isLockOrientation)
        NotificationCenter.default.post(name: Self.lockOrientationDidChangeNotification, object: isLockOrientation)
    }
}

// MARK: - 私有API
private extension SparkRotator {
    
    /// 把屏幕方向旋转至设备方向
    /// - Parameter orientationMask: 屏幕方向
    /// - Returns: 设备方向
    static func toDeviceOrientation(_ orientationMask: UIInterfaceOrientationMask) -> UIDeviceOrientation {
        switch orientationMask {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .landscape:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    /// 把设备方向旋转至屏幕方向
    /// - Parameter orientation: 设备方向
    /// - Returns: 屏幕方向
    static func toInterfaceOrientationMask(_ orientation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    static func setNeedsUpdateOfSupportedInterfaceOrientations(_ currentVC: UIViewController, _ presentedVC: UIViewController?) {
        if #available(iOS 16.0, *) { currentVC.setNeedsUpdateOfSupportedInterfaceOrientations() }
        
        let currentPresentedVC = currentVC.presentedViewController
        
        if let currentPresentedVC, currentPresentedVC != presentedVC {
            setNeedsUpdateOfSupportedInterfaceOrientations(currentPresentedVC, nil)
        }
        
        for childVC in currentVC.children {
            setNeedsUpdateOfSupportedInterfaceOrientations(childVC, currentPresentedVC)
        }
    }
    
    
    /// 转屏方法
    /// - Parameter orientationMask: 屏幕方向
    func rotation(to orientationMask: UIInterfaceOrientationMask) {
        guard isEnabled else { return }
        guard self.currentOrientation != orientationMask else { return }
        
        // 更新并广播屏幕方向
        self.currentOrientation = orientationMask
        
        // 控制横竖屏
        if #available(iOS 16.0, *) {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationMask)
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    guard let rootViewController = window.rootViewController else { continue }
                    Self.setNeedsUpdateOfSupportedInterfaceOrientations(rootViewController, nil)
                }
                for window in windowScene.windows {
                    window.windowScene?.requestGeometryUpdate(geometryPreferences)
                }
            }
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
            let deviceOrientation = Self.toDeviceOrientation(orientationMask)
            UIDevice.current.setValue(NSNumber(value: deviceOrientation.rawValue), forKeyPath: "orientation")
        }
    }
}

// MARK: - 公开API
public extension SparkRotator {
    /// 旋转至目标方向
    /// - Parameters:
    ///   - orientation: 目标方向
    func rotation(to orientation: SparkOrientationType) {
        guard isEnabled else { return }
        let orientationMask: UIInterfaceOrientationMask
        switch orientation {
        case .landscapeLeft:
            orientationMask = .landscapeRight
        case .landscapeRight:
            orientationMask = .landscapeLeft
        case .portraitUpsideDown:
            if !isAllowPortraitUpsideDown {
                return
            }
            orientationMask = .portraitUpsideDown
        default:
            orientationMask = .portrait
        }
        rotation(to: orientationMask)
    }
    
    /// 旋转至竖屏-手机头在上边
    func rotationToPortrait() {
        rotation(to: UIInterfaceOrientationMask.portrait)
    }
    
    /// 旋转至竖屏-手机头在下边
    func rotationToPortraitUpsideDown() {
        guard isAllowPortraitUpsideDown else { return }
        rotation(to: UIInterfaceOrientationMask.portraitUpsideDown)
    }
    
    /// 旋转至横屏（如果锁定了屏幕，则转向手机头在左边）
    func rotationToLandscape() {
        guard isEnabled else { return }
        var orientationMask = Self.toInterfaceOrientationMask(UIDevice.current.orientation)
        if orientationMask == .portrait || orientationMask == .portraitUpsideDown {
            orientationMask = .landscapeRight
        }
        rotation(to: orientationMask)
    }
    
    /// 旋转至横屏（手机头在左边）
    func rotationToLandscapeLeft() {
        rotation(to: UIInterfaceOrientationMask.landscapeRight)
    }
    
    /// 旋转至横屏（手机头在右边）
    func rotationToLandscapeRight() {
        rotation(to: UIInterfaceOrientationMask.landscapeLeft)
    }
    
    /// 横竖屏切换
    func toggleOrientation() {
        guard isEnabled else { return }
        var orientationMask = Self.toInterfaceOrientationMask(UIDevice.current.orientation)
        if orientationMask == self.currentOrientation {
            orientationMask = (self.currentOrientation == .portrait || self.currentOrientation == .portraitUpsideDown) ? .landscapeRight : .portrait
        }
        rotation(to: orientationMask)
    }
}
