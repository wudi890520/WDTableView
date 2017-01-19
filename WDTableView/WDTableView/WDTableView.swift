//
//  WDTableView.swift
//  WDTableView
//
//  Created by 吴頔 on 17/1/19.
//  Copyright © 2017年 WD. All rights reserved.
//

////////////////////////////////////    重要提示    ///////////////////////////////////////

//依赖：
//    1. YYModel (https://github.com/ibireme/YYModel)
//    2. MJRefresh (https://github.com/CoderMJLee/MJRefresh)

//////////////////////////////////////////////////////////////////////////////////////////

import UIKit
import MJRefresh
import YYModel

typealias WDSelected = (WDTableView!, NSIndexPath!) -> Void
typealias WDEditAction = (WDTableView!, Int, NSIndexPath!) -> Void
typealias WDRefresh = (WDTableView!) -> Void
typealias WDFechMore = (WDTableView!) -> Void

/// 缓存策略
///
/// - always: 始终缓存
/// - noNetwork: 无网络状态下展示缓存数据
/// - badRequest: 服务器请求出错时展示缓存数据
enum WDDataSourceArraySaveStrategy: Int {
    case none = 0
    case noNetwork = 1
    case badRequest = 2
    case always = 3
}

class WDTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    /// 数据源
    private var dataSourceArray: [AnyObject] = []
    
    /// 点击命令
    private var selectedCommand: WDSelected?
    
    /// 编辑命令
    private var editCommand: WDEditAction?
    
    /// 编辑按钮标题数组
    private var editButtonTitles: [WDEditButtonTitle] = []
    
    /// 缓存路径
    private var savePath: String = ""
    private var saveModel: NSObject.Type?
    /// 缓存策略
    private var saveStrategy: WDDataSourceArraySaveStrategy = .none
    
    /// 默认行高
    private var WDRowHeight: CGFloat = 44
    
    /// cell标识符
    private var identifierString: String = ""
    
    class func withNib(nibName: String) -> WDTableView {
        
        let tableView = WDTableView()
        tableView.identifierString = nibName
        tableView.registerNib(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: nibName)
        
        tableView.delegate = tableView
        tableView.dataSource = tableView
        
        return tableView
    }

}

// MARK: - blocks
extension WDTableView {
    
    /// 点击cell的事件
    ///
    /// - Parameter action: block回调
    /// - Returns: tableView
    func selected(action: WDSelected) -> WDTableView {
        selectedCommand = action
        return self
    }
    
    /// 编辑列表的事件
    ///
    /// - Parameters:
    ///   - buttonTitles: 滑动cell展示的按钮标题数组
    ///   - action: 点击事件
    /// - Returns: tableView
    func edit(buttonTitles: [WDEditButtonTitle], action: WDEditAction) -> WDTableView {
        editButtonTitles = buttonTitles
        editCommand = action
        return self
    }
    
    /// 下拉刷新
    ///
    /// - Parameter callBack: 刷新回调
    /// - Returns: tableView
    func refresh(callBack: WDRefresh) -> WDTableView {
        let refreshHeader = MJRefreshNormalHeader { [weak self] in
            if self?.mj_footer != nil {
                self?.mj_footer.resetNoMoreData()
            }
            callBack(self)
        }
        
        refreshHeader.lastUpdatedTimeLabel.hidden = true
        refreshHeader.setTitle("下拉刷新", forState: .Idle)
        refreshHeader.setTitle("松开刷新", forState: .Pulling)
        refreshHeader.setTitle("正在刷新...", forState: .Refreshing)
        refreshHeader.stateLabel.font = UIFont.boldSystemFontOfSize(14)
        refreshHeader.stateLabel.textColor = UIColor.lightGrayColor()
        mj_header = refreshHeader
        callBack(self) /// 第一次自动刷新
        return self
    }
    
    /// 上拉加载更新
    ///
    /// - Parameter callBack: 加载回调
    /// - Returns: tableView
    func fetchMore(isBadRequest: Bool = false, callBack: WDFechMore) -> WDTableView {
        let footer = MJRefreshAutoStateFooter { callBack(self) }
        footer.automaticallyHidden = true
        footer.setTitle("", forState: .Idle)
        footer.setTitle("正在加载", forState: .Refreshing)
        footer.setTitle("——— 我也是有底线的 ———", forState: .NoMoreData)
        footer.stateLabel.font = UIFont.boldSystemFontOfSize(13)
        footer.stateLabel.textColor = UIColor.lightGrayColor()
        mj_footer = footer
        
        return self
    }
    
    /// 缓存数据
    ///
    /// - Parameter path: 缓存路径
    /// - modelClass: 要转换的模型
    /// - Returns: tableView
    func savePath(path: String, modelClass: NSObject.Type?, strategy: WDDataSourceArraySaveStrategy) -> WDTableView {

        if modelClass != nil {
            savePath = path
            saveModel = modelClass
            saveStrategy = strategy
            
            if saveStrategy == .always {
                reloadDataWithStrategy()
            }
            
        }
        
        return self
    }
}

// MARK: - targets
extension WDTableView {
    /// 下拉刷新结束
    func endRefresh(array: [AnyObject], isBadRequest: Bool = false) {
        if array.count == 0 || isBadRequest == true {
            reloadDataWithStrategy()
            return
        }
        WDEndRefreshing()
        dataSourceArray = array
        reloadData()
        saveData()
    }
    
    /// 加载结束
    func endFetchMore(array: [AnyObject], isBadRequest: Bool = false) {
        if array.count == 0 || isBadRequest == true {
            return
        }
        WDEndRefreshing()
        dataSourceArray.appendContentsOf(array)
        reloadData()
        saveData()
    }
    
    /// 结束MJRefresh
    private func WDEndRefreshing() {
        if mj_header != nil {
            mj_header.endRefreshing()
        }
        
        if mj_footer != nil {
            mj_footer.endRefreshing()
            (mj_footer as! MJRefreshAutoStateFooter).refreshingTitleHidden = self.numberOfSections == 0
        }
    }
    
    /// 缓存数据
    private func saveData() {
        if savePath.isEmpty == false {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            let json = (dataSourceArray as NSArray).yy_modelToJSONObject()
            userDefaults.setObject(json, forKey: identifierString+savePath)
        }
    }
    
    /// 展示缓存数据
    private func reloadDataWithStrategy() {
        if savePath.isEmpty == false {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            guard
                let json = userDefaults.objectForKey(identifierString+savePath)
            else {
                return
            }
            
            dataSourceArray = NSArray.yy_modelArrayWithClass(saveModel!, json: json)!
            reloadData()
        }
    }
}

// MARK: - tableView delegate & dataSource
extension WDTableView {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return WDRowHeight
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return WDRowHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifierString, forIndexPath: indexPath)
        if dataSourceArray.count > 0 {
            cell.bind(dataSourceArray[indexPath.row])
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if selectedCommand != nil {
            selectedCommand!(self,indexPath)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return editCommand != nil
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        
        for title in editButtonTitles {
            let action = UITableViewRowAction(style: title.style,
                                              title: title.title,
                                              handler: {[weak self] (action, indexPath) in
                let index = (self!.editButtonTitles as NSArray).indexOfObject(title)
                self!.editCommand!(self!, index ,indexPath)
                self?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            })
            actions.append(action)
        }
        
        return actions
    }
}

extension UITableViewCell {
    func bind(model: AnyObject) {
        /// override
    }
}

/// 编辑tableview的model
class WDEditButtonTitle: NSObject {
    var title: String = ""
    var style: UITableViewRowActionStyle = UITableViewRowActionStyle.Default
    
    init(title: String, style: UITableViewRowActionStyle? = .Default) {
        self.title = title
        if style != nil {
            self.style = style!
        }
    }
}
