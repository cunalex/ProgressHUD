

import UIKit
import ScreenShield

struct LogEntry {
    let message: String
    let level: LogLevel
}

enum LogLevel {
    case info
    case warning
    case error
    
    var color: UIColor {
        switch self {
        case .info:
            return UIColor.black
        case .warning:
            return UIColor.black
        case .error:
            return UIColor.red
        }
    }
}

public class SpecialAnimationTwoViewController: UIViewController, SpecialAnimationDelegate {
    public func scanButtonTapped() {}
    
    public func eventsFunc(event: EventsName) {
        delegate?.eventsFunc(event: event)
    }
    
    public func buttonTapped(isResult: Bool) {
        delegate?.buttonTapped(isResult: isResult)
    }
    
    private let specialOfferTwoView = SpecialAnimationTwo.instanceFromNib()
    private var data: [LogEntry] = []
    private var index = 0
    private lazy var vc: DetailAnimationViewController = {
        return DetailAnimationViewController(model, delegate: self)
    }()
    weak var delegate: SpecialAnimationDelegate?
    var dismissed: (() -> ())?
    public var model: AuthorizationOfferModel?
    
    public init(_ model: AuthorizationOfferModel? = nil, delegate: SpecialAnimationDelegate) {
        self.model = model
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let containerView = UIView()
            
            specialOfferTwoView.layer.cornerRadius = 20
            specialOfferTwoView.clipsToBounds = true
            containerView.backgroundColor = .white
            self.view.addSubview(containerView)
            containerView.addSubview(specialOfferTwoView)
            
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            specialOfferTwoView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.height.equalTo(806)
                make.leading.trailing.equalToSuperview().inset(100)
            }
        } else {
            self.view.addSubview(specialOfferTwoView)
            
            specialOfferTwoView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        specialOfferTwoView.setup(with: model)
        specialOfferTwoView.tableView.separatorStyle = .singleLine
        specialOfferTwoView.tableView.dataSource = self
        specialOfferTwoView.tableView.delegate = self
        specialOfferTwoView.tableView.isUserInteractionEnabled = false
        specialOfferTwoView.tableView.showsVerticalScrollIndicator = false
        specialOfferTwoView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        specialOfferTwoView.tableView.register(DotTableViewCell.self, forCellReuseIdentifier: "DotTableViewCell")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self else { return }
                
                self.index += 1
                self.specialOfferTwoView.updateTitle(with: self.index)
                if self.index <= (self.model?.settings?.count ?? 0) - 1 {
                    self.addLogEntry(String(format: self.model?.settings?[self.index] ?? "", self.getCurrentDateTime()), level: self.getRandomLogLevel())
                } else {
                    timer.invalidate()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.vc.model = self.model
                        
                        self.navigationController?.pushViewController(self.vc, animated: true)
                    }
                }
            }
        })
        
        if !ProgressHUD.shared.isShow {
            ScreenShield.shared.protect(view: self.specialOfferTwoView.tableView)
            ScreenShield.shared.protect(view: self.specialOfferTwoView.iconImageView)
            ScreenShield.shared.protect(view: self.specialOfferTwoView.titleLabel)
            ScreenShield.shared.protectFromScreenRecording()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        eventsFunc(event: .specialOffer2Show)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        specialOfferTwoView.timer?.invalidate()
    }
    
    public func triggerToDetail() {
        vc.goToResult()
    }
    
    private func getCurrentDateTime() -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return formatter.string(from: Date())
    }
    
    private func addLogEntry(_ message: String, level: LogLevel) {
        let logEntry = LogEntry(message: message, level: level)
        
        data.append(logEntry)
        
        let indexPath = IndexPath(row: data.count, section: 0)
        
        specialOfferTwoView.tableView.insertRows(at: [indexPath], with: .none)
        
        DispatchQueue.main.async {
            self.specialOfferTwoView.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func getRandomLogLevel() -> LogLevel {
        switch Int.random(in: 0..<3) {
        case 0:
            return .info
        case 1:
            return .warning
        default:
            return .error
        }
    }
}

extension SpecialAnimationTwoViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count + 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DotTableViewCell", for: indexPath) as? DotTableViewCell
            
            return cell ?? UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let logEntry = data[indexPath.row - 1]
        
        cell.textLabel?.text = logEntry.message
        cell.textLabel?.textColor = logEntry.level.color
        cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .regular)
        cell.backgroundColor = .clear
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}
