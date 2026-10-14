import SwiftUI
import TeleprompterCore
import UIKit

/// O painel de leitura: texto grande que rola sozinho.
///
/// - Modo Automático: velocidade fixa em palavras por minuto. Pixels por segundo =
///   altura do texto × ppm ÷ (palavras × 60), então a velocidade não muda com o tamanho da letra.
/// - Modo Voz: a próxima palavra a ler é puxada para a linha de leitura, com correção suave
///   (sem saltos). Se o que ele fala não bate com o roteiro, o texto fica parado.
/// - Modo Manual: só o dedo.
///
/// Toque pausa e retoma; arrastar reposiciona (e o modo Voz recomeça dali); pinça muda a letra.
final class PrompterTextView: UIView, UITextViewDelegate {
    let textView: UITextView
    private(set) var document: PrompterDocument?
    private let controller: PrompterController
    private let fadeMask = CAGradientLayer()
    private let marker = UIView()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var currentSpeed: CGFloat = 0
    private var exactOffset: CGFloat = 0
    private var dimmedUpTo = 0
    private var dimEnabled = true
    private var lastReport: CFTimeInterval = 0
    private var animatingJump = false
    private var pinchStartSize: CGFloat = 0
    /// Lugar a mostrar assim que o painel tiver tamanho (o SwiftUI monta o texto antes do layout).
    private var pendingAnchor: Int?
    private var lastLayoutSize: CGSize = .zero

    /// Onde fica a linha de leitura, em fração da altura do painel.
    static let readingLineFraction: CGFloat = 0.3

    var onFontSizeChange: ((CGFloat) -> Void)?

    init(controller: PrompterController) {
        self.controller = controller
        textView = UITextView(usingTextLayoutManager: false)
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true

        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = false
        textView.showsVerticalScrollIndicator = false
        textView.alwaysBounceVertical = true
        textView.contentInsetAdjustmentBehavior = .never
        textView.textContainer.lineFragmentPadding = 0
        textView.decelerationRate = .normal
        textView.delegate = self
        textView.layoutManager.allowsNonContiguousLayout = false
        addSubview(textView)

        marker.backgroundColor = UIColor(white: 1, alpha: 0.9)
        marker.layer.cornerRadius = 2
        marker.isUserInteractionEnabled = false
        addSubview(marker)

        fadeMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        layer.mask = fadeMask

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        textView.addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        textView.addGestureRecognizer(pinch)

        controller.view = self
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        displayLink?.invalidate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else if displayLink == nil {
            let link = CADisplayLink(target: WeakTarget(self), selector: #selector(WeakTarget.tick(_:)))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    // MARK: Conteúdo

    struct Appearance: Equatable {
        var fontSize: CGFloat
        var lineSpacing: CGFloat
        var alignment: NSTextAlignment
        var textWidth: CGFloat
        var mirror: Bool
        var dimReadText: Bool
    }

    private var appearance: Appearance?
    private var scriptKey: String?

    /// Monta o texto. Mantém o lugar da leitura quando só muda a aparência.
    func apply(script: ParsedScript, key: String, appearance: Appearance) {
        // O SwiftUI chama isto a cada redesenho da tela (relógio, medidor de áudio): sem mudança, sai já.
        if key == scriptKey, appearance == self.appearance { return }
        let changedText = key != scriptKey
        let changedLayout = appearance.fontSize != self.appearance?.fontSize
            || appearance.lineSpacing != self.appearance?.lineSpacing
            || appearance.alignment != self.appearance?.alignment
            || appearance.textWidth != self.appearance?.textWidth
        textView.transform = appearance.mirror ? CGAffineTransform(scaleX: -1, y: 1) : .identity
        dimEnabled = appearance.dimReadText
        self.appearance = appearance
        guard changedText || changedLayout else {
            refreshDimming(force: true)
            return
        }

        let anchor = changedText ? 0 : characterAtReadingLine() ?? 0
        let style = PrompterDocument.Style(
            fontSize: appearance.fontSize, lineSpacing: appearance.lineSpacing, alignment: appearance.alignment
        )
        let document = PrompterDocument(script: script, style: style)
        self.document = document
        scriptKey = key
        textView.attributedText = document.text
        dimmedUpTo = 0
        controller.documentLoaded(document)
        if bounds.height > 0 {
            setNeedsLayout()
            layoutIfNeeded()
            scroll(toCharacter: anchor, animated: false)
        } else {
            pendingAnchor = anchor
        }
        refreshDimming(force: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Só reposiciona quando o painel muda de tamanho; senão a rolagem voltaria ao começo da linha.
        let sizeChanged = bounds.size != lastLayoutSize
        lastLayoutSize = bounds.size
        let previousCharacter = sizeChanged && textView.bounds.width > 0 ? characterAtReadingLine() : nil
        let width = bounds.width
        textView.frame = bounds
        let textWidth = (appearance?.textWidth ?? 0.9) * width
        let side = max(16, (width - textWidth) / 2)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: side, bottom: 0, right: side)
        let readingY = readingLineY
        textView.contentInset = UIEdgeInsets(top: readingY, left: 0, bottom: max(0, bounds.height - readingY - lineHeight), right: 0)

        let lh = lineHeight
        marker.frame = CGRect(x: max(4, side - 12), y: readingY + lh * 0.2, width: 4, height: lh * 0.6)

        fadeMask.frame = bounds
        let h = max(1, bounds.height)
        fadeMask.locations = [0, NSNumber(value: Double(min(0.25, 28 / h))), NSNumber(value: Double(1 - min(0.3, 44 / h))), 1]
        if let anchor = pendingAnchor, bounds.height > 0, document != nil {
            pendingAnchor = nil
            textView.layoutManager.ensureLayout(for: textView.textContainer)
            scroll(toCharacter: anchor, animated: false)
            refreshDimming(force: true)
        } else if let previousCharacter, !animatingJump {
            scroll(toCharacter: previousCharacter, animated: false)
        }
    }

    var readingLineY: CGFloat { (bounds.height * Self.readingLineFraction).rounded() }

    private var lineHeight: CGFloat {
        let size = appearance?.fontSize ?? 34
        return size * (appearance?.lineSpacing ?? 1.25) * 1.2
    }

    // MARK: Geometria

    private func rect(forCharacterRange range: NSRange) -> CGRect {
        let layout = textView.layoutManager
        let glyphs = layout.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = layout.boundingRect(forGlyphRange: glyphs, in: textView.textContainer)
        rect.origin.y += textView.textContainerInset.top
        rect.origin.x += textView.textContainerInset.left
        return rect
    }

    private var minOffset: CGFloat { -textView.contentInset.top }
    private var maxOffset: CGFloat {
        max(minOffset, textView.contentSize.height + textView.contentInset.bottom - textView.bounds.height)
    }

    private func offset(forCharacter location: Int) -> CGFloat {
        guard let length = document?.text.length, length > 0 else { return minOffset }
        let clamped = min(max(0, location), length - 1)
        let r = rect(forCharacterRange: NSRange(location: clamped, length: 1))
        return min(maxOffset, max(minOffset, r.minY - readingLineY))
    }

    /// O caractere que está na linha de leitura agora.
    func characterAtReadingLine() -> Int? {
        guard let length = document?.text.length, length > 0 else { return nil }
        let y = textView.contentOffset.y + readingLineY + lineHeight * 0.4 - textView.textContainerInset.top
        let point = CGPoint(x: textView.textContainer.size.width / 2, y: max(0, y))
        let layout = textView.layoutManager
        let glyph = layout.glyphIndex(for: point, in: textView.textContainer)
        let lineRange = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        let lineStart = layout.glyphIndex(for: CGPoint(x: 0, y: lineRange.midY), in: textView.textContainer)
        return min(length - 1, layout.characterIndexForGlyph(at: lineStart))
    }

    func tokenAtReadingLine() -> Int? {
        guard let document, let character = characterAtReadingLine() else { return nil }
        return document.tokenIndex(atOrAfter: character)
    }

    // MARK: Rolagem

    func scroll(toCharacter location: Int, animated: Bool) {
        let target = offset(forCharacter: location)
        setOffset(target, animated: animated)
    }

    func scroll(toSection index: Int, animated: Bool) {
        guard let document, document.sections.indices.contains(index) else { return }
        scroll(toCharacter: document.sections[index].location, animated: animated)
    }

    func nudge(lines: Int) {
        setOffset(min(maxOffset, max(minOffset, textView.contentOffset.y + CGFloat(lines) * lineHeight)), animated: true)
    }

    private func setOffset(_ y: CGFloat, animated: Bool) {
        exactOffset = y
        if animated {
            animatingJump = true
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.textView.contentOffset = CGPoint(x: 0, y: y)
            } completion: { _ in
                self.animatingJump = false
                self.exactOffset = self.textView.contentOffset.y
                self.refreshDimming(force: false)
                self.reportPosition(force: true)
            }
        } else {
            textView.contentOffset = CGPoint(x: 0, y: y)
            reportPosition(force: true)
        }
    }

    func playbackChanged() {
        exactOffset = textView.contentOffset.y
        if !controller.isPlaying { currentSpeed = 0 }
    }

    func modeChanged() {
        currentSpeed = 0
        exactOffset = textView.contentOffset.y
        refreshDimming(force: true)
    }

    func voicePositionChanged() {
        refreshDimming(force: false)
    }

    /// Velocidade do modo Automático, em pontos por segundo.
    private var autoSpeed: CGFloat {
        guard let document else { return 0 }
        let used = textView.layoutManager.usedRect(for: textView.textContainer).height
        return used * CGFloat(controller.wordsPerMinute) / (CGFloat(document.wordCount) * 60)
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 1 / 60 : min(0.1, now - lastTimestamp)
        lastTimestamp = now
        defer { reportPosition(force: false) }

        guard document != nil, !animatingJump, !textView.isTracking, !textView.isDecelerating else {
            exactOffset = textView.contentOffset.y
            return
        }
        guard controller.isPlaying else { return }

        switch controller.mode {
        case .auto:
            // Arranque suave (0,4 s) em vez de pulo de velocidade.
            let target = autoSpeed
            currentSpeed += (target - currentSpeed) * CGFloat(1 - exp(-dt * 8))
            exactOffset += currentSpeed * CGFloat(dt)
            if exactOffset >= maxOffset {
                exactOffset = maxOffset
                textView.contentOffset.y = exactOffset
                controller.didReachEnd()
                return
            }
            textView.contentOffset.y = exactOffset
            refreshDimming(force: false)
        case .voice:
            guard let document, let matcher = controller.matcher else { return }
            let position = min(matcher.position, max(0, document.trackableRanges.count - 1))
            guard !document.trackableRanges.isEmpty else { return }
            let target = offset(forCharacter: document.trackableRanges[position].location)
            let delta = target - exactOffset
            guard abs(delta) > 0.5 else { return }
            exactOffset += delta * CGFloat(1 - exp(-dt * 5))
            textView.contentOffset.y = exactOffset
        case .manual:
            break
        }
    }

    // MARK: Esmaecer o que já foi lido

    private func refreshDimming(force: Bool) {
        guard let document else { return }
        var target = 0
        if dimEnabled {
            switch controller.mode {
            case .voice:
                let position = controller.matcher?.position ?? 0
                if position > 0, position - 1 < document.trackableRanges.count {
                    target = NSMaxRange(document.trackableRanges[position - 1])
                }
            case .auto, .manual:
                target = characterAtReadingLine() ?? 0
            }
        }
        guard force || target != dimmedUpTo else { return }
        let storage = textView.textStorage
        let original = document.text
        storage.beginEditing()
        if force {
            storage.setAttributedString(original)
            if target > 0 { dim(storage, NSRange(location: 0, length: min(target, storage.length))) }
        } else if target > dimmedUpTo {
            dim(storage, NSRange(location: dimmedUpTo, length: min(target, storage.length) - dimmedUpTo))
        } else {
            let range = NSRange(location: target, length: dimmedUpTo - target)
            original.enumerateAttribute(.foregroundColor, in: range) { value, sub, _ in
                if let value { storage.addAttribute(.foregroundColor, value: value, range: sub) }
            }
        }
        storage.endEditing()
        dimmedUpTo = target
    }

    private func dim(_ storage: NSTextStorage, _ range: NSRange) {
        guard range.length > 0 else { return }
        storage.addAttribute(.foregroundColor, value: PrompterDocument.readColor, range: range)
    }

    // MARK: Avisos

    private func reportPosition(force: Bool) {
        guard let document else { return }
        let now = CACurrentMediaTime()
        guard force || now - lastReport > 0.15 else { return }
        lastReport = now
        let range = maxOffset - minOffset
        let progress = range > 0 ? Double((textView.contentOffset.y - minOffset) / range) : 0
        let section = document.sectionIndex(containing: characterAtReadingLine() ?? 0)
        controller.report(section: section, progress: min(1, max(0, progress)))
    }

    // MARK: Gestos

    @objc private func tapped() {
        guard controller.mode != .manual else { return }
        Haptics.tap()
        controller.toggle()
    }

    @objc private func pinched(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            pinchStartSize = appearance?.fontSize ?? 34
        case .changed:
            let size = min(72, max(18, (pinchStartSize * gesture.scale).rounded()))
            if size != appearance?.fontSize { onFontSizeChange?(size) }
        default:
            break
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { userFinishedScrolling() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        userFinishedScrolling()
    }

    private func userFinishedScrolling() {
        exactOffset = textView.contentOffset.y
        controller.userDidScroll()
        refreshDimming(force: false)
        reportPosition(force: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking || scrollView.isDecelerating {
            refreshDimming(force: false)
        }
    }
}

/// O CADisplayLink segura o alvo com força; este intermediário evita o ciclo.
private final class WeakTarget: NSObject {
    weak var view: PrompterTextView?
    init(_ view: PrompterTextView) { self.view = view }
    @objc func tick(_ link: CADisplayLink) {
        guard let view else { link.invalidate(); return }
        view.tick(link)
    }
}

/// O painel de leitura em SwiftUI.
struct PrompterPanel: UIViewRepresentable {
    let controller: PrompterController
    let script: ParsedScript
    let scriptKey: String
    let appearance: PrompterTextView.Appearance
    var onFontSizeChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> PrompterTextView {
        let view = PrompterTextView(controller: controller)
        view.onFontSizeChange = onFontSizeChange
        return view
    }

    func updateUIView(_ view: PrompterTextView, context: Context) {
        view.onFontSizeChange = onFontSizeChange
        view.apply(script: script, key: scriptKey, appearance: appearance)
    }
}
