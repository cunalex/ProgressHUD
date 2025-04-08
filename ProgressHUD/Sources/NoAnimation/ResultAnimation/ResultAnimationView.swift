

import UIKit
import Lottie
import AudioToolbox

protocol InstanceFromNibProtocol {
    associatedtype InstanceFromNibType: UIView
    static func instanceFromNib() -> InstanceFromNibType
}

extension InstanceFromNibProtocol {
    static func instanceFromNib() -> InstanceFromNibType {
        let loadedNib = Bundle.module.loadNibNamed(InstanceFromNibType.className, owner: self, options: nil)

        return loadedNib?.first as! InstanceFromNibType
    }
}

extension UIView {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}

class ResultAnimationView: UIView, InstanceFromNibProtocol {
    typealias InstanceFromNibType = ResultAnimationView
    
    private let isSmallDevice = UIScreen.main.nativeBounds.height <= 1334
    private let isVerySmallDevice = UIScreen.main.nativeBounds.height <= 1136
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var animationView: LottieAnimationView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var animationTitle: UILabel!
    @IBOutlet weak var animationSubtitle: UILabel!
    @IBOutlet weak var bannerContainer: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var topConst: NSLayoutConstraint!
    @IBOutlet weak var inactiveImageView: UIImageView!
    
    @IBOutlet weak var lhConst: NSLayoutConstraint!
    @IBOutlet weak var lwConst: NSLayoutConstraint!
    @IBOutlet weak var subTop: NSLayoutConstraint!
    @IBOutlet weak var animTop: NSLayoutConstraint!
    @IBOutlet weak var bannerTop: NSLayoutConstraint!
    @IBOutlet weak var stackheigt: NSLayoutConstraint!
    @IBOutlet weak var stackWidth: NSLayoutConstraint!
    @IBOutlet weak var circularLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var circularTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var circularBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var circularTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bannerHeight: NSLayoutConstraint!
    private let bannerView = SpinnerView.instanceFromNib()
    private var model: AuthorizationOfferModel?
    private var isTarifPaidAndActive: Bool?
    private var couter = 0
    private var progress: Float = 0
    @IBOutlet weak var circularProgress: CircularProgressView!
    private let statsViewButton = CustomStatsButton()

    private var timer: Timer?
    var timerBzz: Timer?
    
    var tariffButtonTapped: (() -> Void)?
    var openSheetVCTapped: (() -> Void)?
    var sendEvent: ((EventsName) -> Void)?
    var showStatistView: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            subtitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            animationTitle.font = UIFont.systemFont(ofSize: 30, weight: .bold)
            lhConst.constant = 420
            lwConst.constant = 420
            bannerHeight.constant = 421
            inactiveImageView.contentMode = .scaleToFill
            stackheigt.constant = 215
            stackWidth.constant = 192
            topConst.constant = 10
            bannerTop.constant = 0
            
            layoutIfNeeded()
        } else {
            if isVerySmallDevice {
//                bannerHeight.constant = 445
                bannerHeight.constant = 500
                stackheigt.constant = 130
                stackWidth.constant = 130
                topConst.constant = 15
                subTop.constant = 5
                animTop.constant = 0
                bannerTop.constant = 0
                lhConst.constant = 250
                lwConst.constant = 250
                circularLeadingConstraint.constant = 42
                circularTopConstraint.constant = 42
                circularBottomConstraint.constant = -42
                circularTrailingConstraint.constant = -42
                inactiveImageView.contentMode = .scaleAspectFit
                titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
                subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                animationTitle.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                
                layoutIfNeeded()
            } else if isSmallDevice {
                stackheigt.constant = 130
                stackWidth.constant = 130
                topConst.constant = 10
                subTop.constant = -2
                animTop.constant = -6
                bannerTop.constant = -8
                lhConst.constant = 248
                lwConst.constant = 248
                circularLeadingConstraint.constant = 41
                circularTopConstraint.constant = 41
                circularBottomConstraint.constant = -41
                circularTrailingConstraint.constant = -41
                inactiveImageView.contentMode = .scaleAspectFit
                
                titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
                subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                bringSubviewToFront(subtitleLabel)
                animationTitle.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                
                layoutIfNeeded()
            }
        }
        
        circularProgress.configureProgressViewToBeCircular()
        
        circularProgress.setProgressColor = UIColor().hexStringToUIColor(hex: "#65D65C")
        circularProgress.setTrackColor = UIColor(displayP3Red: 205.0/255.0, green: 247.0/255.0, blue: 212.0/255.0, alpha: 1.0)
        
        bannerContainer.addSubview(statsViewButton)
        bannerContainer.addSubview(bannerView)
        
        statsViewButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(50)
        }
        
        bannerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(statsViewButton.snp.top).offset(-5)
        }
        
        bannerView.tariffButtonTapped = { [weak self] in
            self?.tariffButtonTapped?()
        }
        
        bannerView.progressSwitchTapped = { [weak self] isOn in
            self?.setup(with: self?.model, isTarifPaidAndActive: self?.isTarifPaidAndActive ?? false)
        }
        
        bannerView.goEvent = { [weak self] event in
            self?.sendEvent?(event)
        }
        
        bannerView.openSheetVCTapped = { [weak self] in
            self?.openSheetVCTapped?()
        }
    }
    
    func setup(with model: AuthorizationOfferModel?, isTarifPaidAndActive: Bool) {
        self.isTarifPaidAndActive = isTarifPaidAndActive
        self.model = model
        bannerView.setup(with: model, isPaid: isTarifPaidAndActive)
        backgroundColor = .white
        animationView.backgroundColor = .white
        
        statsViewButton.setup(with: model) { [weak self] in
            self?.showStatistView?()
        }
        
        if isTarifPaidAndActive {
            if Storage.isAllFeaturesEnabled, Storage.featuresStates.count == 6 {
                let attributedStrOne = NSMutableAttributedString(string: String(model?.scn?.subtitle_anim_compl?.dropLast(2) ?? ""), attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#000000"),
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 18 : (isSmallDevice ? (isVerySmallDevice ? 8 : 9) : 12), weight: .medium)
                ])
                let attributedStrTwo = NSMutableAttributedString(string: localizeText(forKey: .subsActive).uppercased(), attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#65D65C"),
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 21 : (isSmallDevice ? (isVerySmallDevice ? 10 : 11) : 14), weight: .bold)
                ])
                attributedStrOne.append(attributedStrTwo)
                
                inactiveImageView.isHidden = true
                subtitleLabel.text = model?.scn?.subtitle_compl
                iconImageView.image = UIImage(resource: .vector)
                titleLabel.text = String(format: model?.scn?.title_compl ?? "", localizeText(forKey: .subsOn))
                animationSubtitle.attributedText = attributedStrOne
                animationTitle.text = model?.scn?.title_anim_compl
                
                guard let url = URL(string: model?.scn?.anim_done ?? "") else { return }
                
                animationView.isHidden = false
                LottieAnimation.loadedFrom(url: url, closure: { [weak self] animation in
                    self?.animationView.animation = animation
                    self?.animationView.play()
                }, animationCache: DefaultAnimationCache.sharedCache)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    
                } else {
                    if isVerySmallDevice {
                        circularLeadingConstraint.constant = 38
                        circularTopConstraint.constant = 38
                        circularBottomConstraint.constant = -38
                        circularTrailingConstraint.constant = -38
                        layoutIfNeeded()
                    } else if isSmallDevice {
                        circularLeadingConstraint.constant = 35
                        circularTopConstraint.constant = 35
                        circularBottomConstraint.constant = -34
                        circularTrailingConstraint.constant = -34
//                        circularProgress.configureProgressViewToBeCircular()
                        layoutIfNeeded()
                        
                    }
                }
                    
                
            } else {
                let attributedStrOne = NSMutableAttributedString(string: String(model?.scn?.subtitle_anim_compl?.dropLast(2) ?? ""), attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#000000"),
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 18 : (isSmallDevice ? (isVerySmallDevice ? 10 : 11) : 12), weight: .medium)
                ])
                let attributedStrTwo = NSMutableAttributedString(string: localizeText(forKey: .subsOff).uppercased(), attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#E74444"),
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 21 : (isSmallDevice ? (isVerySmallDevice ? 12 : 13) : 14), weight: .bold)
                ])
                attributedStrOne.append(attributedStrTwo)
                
                animationView.isHidden = true
                inactiveImageView.isHidden = false
                animationTitle.text = model?.scn?.title_anim_unp
                subtitleLabel.text = model?.scn?.subtitle_unp
                iconImageView.image = UIImage(resource: .inVector)
                titleLabel.text = String(format: model?.scn?.title_compl ?? "", localizeText(forKey: .subsDis))
                animationSubtitle.attributedText = attributedStrOne
                
//                if UIDevice.current.userInterfaceIdiom == .pad {
//                    
//                } else {
//                    if isVerySmallDevice {
//                        circularLeadingConstraint.constant = 42
//                        circularTopConstraint.constant = 42
//                        circularBottomConstraint.constant = -42
//                        circularTrailingConstraint.constant = -42
//                        layoutIfNeeded()
//                    } else if isSmallDevice {
//                        circularLeadingConstraint.constant = 41
//                        circularTopConstraint.constant = 41
//                        circularBottomConstraint.constant = -41
//                        circularTrailingConstraint.constant = -41
//                        circularProgress.configureProgressViewToBeCircular()
//                        circularProgress.layoutIfNeeded()
//                        layoutIfNeeded()
//                        circularProgress.layoutIfNeeded()
//                        circularProgress.configureProgressViewToBeCircular()
//                    }
//                }
                
            }
            
            circularProgress.isHidden = false
            progress = 0
            
            Storage.featuresStates.forEach { state in
                if state.value {
                    progress += 1 / 6
                    
                    circularProgress.setProgressWithAnimation(duration: 1.0, value: progress)
                }
            }
        } else {
            let attributedStrOne = NSMutableAttributedString(string: String(model?.scn?.subtitle_anim_compl?.dropLast(2) ?? ""), attributes: [
                NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#000000"),
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: (isSmallDevice ? (isVerySmallDevice ? 10 : 11) : 12), weight: .medium)
            ])
            let attributedStrTwo = NSMutableAttributedString(string: localizeText(forKey: .subsOff).uppercased(), attributes: [
                NSAttributedString.Key.foregroundColor: UIColor().hexStringToUIColor(hex: "#E74444"),
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: (isSmallDevice ? (isVerySmallDevice ? 12 : 13) : 14), weight: .bold)
            ])
            attributedStrOne.append(attributedStrTwo)
            
            circularProgress.isHidden = true
            titleLabel.text = String(format: model?.scn?.title_compl ?? "", localizeText(forKey: .subsDis))
            subtitleLabel.text = model?.scn?.subtitle_unp
            animationTitle.text = model?.scn?.title_anim_unp
            animationSubtitle.attributedText = attributedStrOne
            animationView.isHidden = true
            inactiveImageView.isHidden = false
            iconImageView.image = UIImage(resource: .inVector)
        }
    }
    
    @objc func bzzz() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

final class Storage {
    static var featuresStates: [Int: Bool] {
        get {
            if let data = UserDefaults.standard.object(forKey: "featuresStates") as? Data,
               let value = try? JSONDecoder().decode([Int: Bool].self, from: data) {
                
                return value
            }
            
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "featuresStates")
            }
        }
    }
    
    static var isAllFeaturesEnabled: Bool {
        featuresStates.values.allSatisfy { $0 == true }
    }
}
