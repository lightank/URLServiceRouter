//
//  ViewController.swift
//  URLServiceRouterDemo
//
//  Created by huanyu.li on 2021/8/4.
//

import UIKit
import URLServiceRouter

class ViewController: UIViewController {
    var cellItems: [TableViewCellItem] = []
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "URLServiceRouter"
        view.addSubview(tableView)
        
        addCellItems()
        registerCellClass()
        tableView.reloadData()
        
        URLServiceRouter.shared.unitTestRequest(url: "http://china.realword.io/owner/1/info") { (request, routerResult) in
            URLServiceRouter.shared.logInfo("\(String(describing: request.response?.data))")
        }
    }
    
    func addCellItems() {
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.text = "页面跳转"
            tableViewCell.selectionStyle = .none
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            
        }))
        
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.text = "push 页面，并接受回传的数据"
            tableViewCell.accessoryType = .disclosureIndicator
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            URLServiceRouter.shared.callService(name: "input_page", params: "请在此输入信息，以便回调回去") { (service, error) in
            } callback: { (result, error) in
                if result is String? {
                    self.showAlertMessge(title: "页面回传来的数据", message: result as! String?)
                }
            }
        }))
        
        addTitleCellItem()
        addTitleCellItem("服务调用")
        
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.numberOfLines = 0
            tableViewCell.textLabel?.text = "外部请求服务，获取业务数据。\n点击后3秒后将有数据回调"
            tableViewCell.accessoryType = .disclosureIndicator
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            if let url = URL(string: "http://china.realword.io/owner/1/info") {
                URLServiceRequest(url: url).start(callback: { (request) in
                    if let data = request.response?.data {
                        // 正确的数据
                        self.showAlertMessge(title: "回调的业务数据", message: String(describing: data) )
                    }
                    URLServiceRouter.shared.logInfo("\(String(describing: request.response?.data))")
                })
            }
        }))
        
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.numberOfLines = 0
            tableViewCell.textLabel?.text = "内部直接调用服务，获取业务数据。\n点击后3秒后将有数据回调"
            tableViewCell.accessoryType = .disclosureIndicator
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            URLServiceRouter.shared.callService(name: "user://info", params: "1") { (service, error) in
                
            } callback: { (result, error) in
                self.showAlertMessge(title: "回调的业务数据", message: String(describing: result) )
                URLServiceRouter.shared.logInfo("\(String(describing: result))")
            }
        }))
        
        addTitleCellItem()
        addTitleCellItem("业务相关")
        
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.numberOfLines = 0
            tableViewCell.textLabel?.text = "将测试环境替换为生产环境。 \n详情请查看这部分代码"
            tableViewCell.selectionStyle = .none
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            URLServiceRouter.shared.registerNode(from: "https", parsers:[URLServiceRedirectTestHostParser()]);
        }))
    }
    
    func registerCellClass() {
        cellItems.forEach { (cellItem) in
            tableView .register(cellItem.cellClass, forCellReuseIdentifier: cellItem.cellReuseIdentifier)
        }
    }
    
    func showAlertMessge(title:String? = nil, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func addTitleCellItem(_ title: String = "") {
        cellItems.append(TableViewCellItem(cellClass: UITableViewCell.classForCoder(), cellSettingBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            tableViewCell.textLabel?.text = title
            tableViewCell.selectionStyle = .none
        }, cellSelectedBlock: { (cellItem, tableView, tableViewCell, indexPath) in
            
        }))
    }
}

extension ViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellItem = cellItems[indexPath.row]
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: cellItem.cellReuseIdentifier, for: indexPath)
        cellItem.cellSettingBlock(cellItem, tableView, tableViewCell, indexPath)
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellItem = cellItems[indexPath.row]
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: cellItem.cellReuseIdentifier, for: indexPath)
        cellItem.cellSelectedBlock(cellItem, tableView, tableViewCell, indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

typealias TableViewCellItemBlock = (TableViewCellItem, UITableView, UITableViewCell, IndexPath) -> Void
class TableViewCellItem: NSObject {
    let cellClass: AnyClass
    let cellHeight: Double
    let cellSettingBlock: TableViewCellItemBlock
    let cellSelectedBlock: TableViewCellItemBlock
    
    var cellReuseIdentifier: String {
        NSStringFromClass(cellClass)
    }
    
    init(cellClass: AnyClass, cellHeight: Double = -1, cellSettingBlock: @escaping TableViewCellItemBlock, cellSelectedBlock: @escaping TableViewCellItemBlock) {
        self.cellClass = cellClass
        self.cellHeight = cellHeight
        self.cellSettingBlock = cellSettingBlock
        self.cellSelectedBlock = cellSelectedBlock
        super.init()
    }
}
