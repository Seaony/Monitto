import AppKit
import Combine
import SwiftUI

enum MenuBarRunnerSpeed {
    static func framesPerSecond(for metric: MenuBarMetric, snapshot: SystemSnapshot) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--monitto-runner-max-load") {
            return framesPerSecond(load: 100)
        }
        #endif

        let load: Double = switch metric {
        case .cpu: snapshot.cpu.total
        case .memory: snapshot.memory.usedPercent
        case .network: networkLoad(bytesPerSecond: snapshot.network.downloadBytesPerSecond)
        case .disk, .battery, .temperature: 0
        }
        return framesPerSecond(load: load)
    }

    static func networkLoad(bytesPerSecond: Double) -> Double {
        // 10 KB/s 到 100 MB/s 正好跨四个十倍区间。
        min(100, log10(max(10_000, bytesPerSecond) / 10_000) * 25)
    }

    static func framesPerSecond(load: Double) -> Double {
        2 + 0.28 * min(100, max(0, load))
    }
}

enum MenuBarRunnerFrames {
    static let images = Dictionary(uniqueKeysWithValues: MenuBarRunner.allCases.map { runner in
        let frames = (0..<runner.frameCount).map { index in
            let image = NSImage(named: "\(runner.rawValue)-frame-\(index)")!
            image.isTemplate = true
            return image
        }
        return (runner, frames)
    })

    static let templates = images.mapValues { originals in
        originals.map { original in
            let template = NSImage(size: original.size)
            for scale in [1.0, 2.0] {
                let rep = NSBitmapImageRep(cgImage: bitmap(original, scale: scale))
                rep.size = original.size
                template.addRepresentation(rep)
            }
            template.isTemplate = true
            return template
        }
    }

    private static func bitmap(_ image: NSImage, scale: CGFloat) -> CGImage {
        let context = CGContext(
            data: nil,
            width: Int(image.size.width * scale),
            height: Int(image.size.height * scale),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.scaleBy(x: scale, y: scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()!
    }
}

final class MenuBarRunnerPlayback: ObservableObject {
    static let shared = MenuBarRunnerPlayback()

    @Published private(set) var isPaused = false

    private enum PauseReason: Hashable {
        case screen, session, lock
    }

    private var reasons: Set<PauseReason> = []
    private var observers: [NSObjectProtocol] = []

    private init() {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.screensDidSleepNotification, reason: .screen, pause: true)
        observe(workspace, NSWorkspace.screensDidWakeNotification, reason: .screen, pause: false)
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification, reason: .session, pause: true)
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification, reason: .session, pause: false)
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked"), reason: .lock, pause: true)
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked"), reason: .lock, pause: false)
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, reason: PauseReason, pause: Bool) {
        observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if pause {
                    self.reasons.insert(reason)
                } else {
                    self.reasons.remove(reason)
                }
                let shouldPause = !self.reasons.isEmpty
                if self.isPaused != shouldPause { self.isPaused = shouldPause }
            }
        })
    }
}

struct MenuBarRunnerPlacement: Equatable {
    let metric: MenuBarMetric
    let runner: MenuBarRunner
    let origin: CGFloat
    let framesPerSecond: Double
}

enum MenuBarRunnerSurface {
    case preview, activeMenuBar, inactiveMenuBar
}

struct MenuBarRunnerOverlay: NSViewRepresentable {
    let placements: [MenuBarRunnerPlacement]
    let isPaused: Bool

    func makeNSView(context: Context) -> MenuBarRunnerOverlayView {
        MenuBarRunnerOverlayView()
    }

    func updateNSView(_ view: MenuBarRunnerOverlayView, context: Context) {
        view.update(placements, isPaused: isPaused)
    }
}

final class MenuBarRunnerOverlayView: NSView {
    private var sprites: [MenuBarMetric: MenuBarRunnerLayer] = [:]
    private var surface = MenuBarRunnerSurface.preview

    init() {
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func update(
        _ placements: [MenuBarRunnerPlacement],
        isPaused: Bool,
        surface: MenuBarRunnerSurface = .preview
    ) {
        self.surface = surface
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let present = Set(placements.map(\.metric))
        for metric in sprites.keys where !present.contains(metric) {
            sprites.removeValue(forKey: metric)?.removeFromSuperlayer()
        }

        let scale = window?.backingScaleFactor ?? 1
        let tint = templateColor
        for placement in placements {
            let sprite = sprites[placement.metric] ?? MenuBarRunnerLayer()
            if sprite.superlayer == nil {
                sprites[placement.metric] = sprite
                layer?.addSublayer(sprite)
            }
            sprite.update(placement, scale: scale, tint: tint, isPaused: isPaused, surface: surface)
        }
        CATransaction.commit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let tint = templateColor
        for sprite in sprites.values { sprite.updateTint(tint, surface: surface) }
        CATransaction.commit()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        let scale = window?.backingScaleFactor ?? 1
        for sprite in sprites.values { sprite.updateScale(scale) }
    }

    private var templateColor: CGColor {
        var color: CGColor!
        effectiveAppearance.performAsCurrentDrawingAppearance {
            color = NSColor.labelColor.cgColor
        }
        return color
    }
}

private final class MenuBarRunnerLayer: CALayer {
    private let frameLayer = CALayer()
    private var runner: MenuBarRunner?
    private var scale: CGFloat = 0
    private var runningTint: CGColor?
    private var parkedPhase: CFTimeInterval?

    override init() {
        super.init()
        configureMask()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureMask() {
        mask = frameLayer
        frameLayer.speed = 0
        frameLayer.contentsGravity = .resize
    }

    func update(
        _ placement: MenuBarRunnerPlacement,
        scale: CGFloat,
        tint: CGColor,
        isPaused: Bool,
        surface: MenuBarRunnerSurface
    ) {
        let size = MenuBarRunnerFrames.images[placement.runner]![0].size
        frame = CGRect(origin: CGPoint(x: placement.origin, y: 0), size: size)
        frameLayer.frame = bounds
        updateTint(tint, surface: surface)
        if runner != placement.runner {
            runner = placement.runner
            self.scale = 0
        }
        updateScale(scale)
        updatePlayback(
            speed: isPaused ? 0 : Float(placement.framesPerSecond),
            showFirstFrame: surface == .inactiveMenuBar
        )
    }

    func updateTint(_ tint: CGColor, surface: MenuBarRunnerSurface) {
        // 同一块深色菜单栏的两个图标扣除背景后，失焦与聚焦的线性亮度比为 0.38、0.33。
        // 系统复制菜单栏时读模型图层。模型保留暗色，实时显示用动画图层的正常颜色。
        let modelTint = surface == .preview ? tint : tint.copy(alpha: tint.alpha * 0.36)
        if backgroundColor != modelTint { backgroundColor = modelTint }
        let liveTint = surface == .activeMenuBar ? tint : nil
        guard runningTint != liveTint else { return }
        runningTint = liveTint
        if let liveTint {
            let color = CABasicAnimation(keyPath: "backgroundColor")
            color.fromValue = liveTint
            color.toValue = liveTint
            color.duration = 1
            color.fillMode = .both
            color.isRemovedOnCompletion = false
            add(color, forKey: "activeMenuBarTint")
        } else {
            removeAnimation(forKey: "activeMenuBarTint")
        }
    }

    func updateScale(_ scale: CGFloat) {
        guard let runner, self.scale != scale else { return }
        self.scale = scale
        let frames = MenuBarRunnerFrames.templates[runner]!.map { template in
            template.representations.compactMap { $0 as? NSBitmapImageRep }
                .min { abs(CGFloat($0.pixelsHigh) / $0.size.height - scale)
                    < abs(CGFloat($1.pixelsHigh) / $1.size.height - scale) }!.cgImage!
        }
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.calculationMode = .discrete
        animation.keyTimes = (0...frames.count).map { NSNumber(value: Double($0) / Double(frames.count)) }
        animation.duration = Double(frames.count)
        animation.repeatCount = .infinity
        // 明确以图层本地时间为起点，切换屏幕缩放时也沿用当前相位。
        animation.beginTime = .leastNonzeroMagnitude
        frameLayer.contentsScale = scale
        frameLayer.contents = frames[0]
        frameLayer.add(animation, forKey: "runnerFrames")
    }

    private func updatePlayback(speed: Float, showFirstFrame: Bool) {
        let now = CACurrentMediaTime()
        let phase = (now - frameLayer.beginTime) * Double(frameLayer.speed) + frameLayer.timeOffset
        if showFirstFrame {
            guard parkedPhase == nil else { return }
            parkedPhase = phase
            frameLayer.speed = 0
            frameLayer.timeOffset = 0
            return
        }

        guard frameLayer.speed != speed || parkedPhase != nil else { return }
        frameLayer.beginTime = now
        frameLayer.timeOffset = parkedPhase ?? phase
        frameLayer.speed = speed
        parkedPhase = nil
    }
}
