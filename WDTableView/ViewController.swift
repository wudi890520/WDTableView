//
//  ViewController.swift
//  WDTableView
//
//  Created by 吴頔 on 17/1/19.
//  Copyright © 2017年 WD. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let tableView = WDTableView.withNib("TestTableViewCell")
    let titles: [String] = ["1","水电费水电费","地方","改好","3434收到","的点点滴滴"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = UIScreen.mainScreen().bounds
       
        tableView
        .savePath("list", modelClass: Contrast.self, strategy: .always)
        .selected {
            (tableView, indexPath) in
            print(indexPath)
        }.edit([WDEditButtonTitle(title: "删除"),
                WDEditButtonTitle(title: "编辑", style: .Normal)]) {
                    (tableView, titleIndex, indexPath) in
            print(titleIndex)
            print(indexPath)
        }.refresh {
            (tableView) in
            tableView.endRefresh([
                Contrast.creat("1", e: "one"),
                Contrast.creat("2", e: "two"),
                Contrast.creat("3", e: "three"),
                Contrast.creat("4", e: "four")])
        }.fetchMore {
            (tableView) in
            tableView.endFetchMore([
                Contrast.creat("5", e: "five"),
                Contrast.creat("6", e: "six"),
                Contrast.creat("7", e: "seven"),
                Contrast.creat("8", e: "eight")])
        }
        
        view.addSubview(tableView)
        // Do any additional setup after loading the view, typically from a nib.
    }

}

class Contrast: NSObject {
    var chinese = ""
    var english = ""
    
    class func creat(c: String, e: String) -> Contrast{
        let con = Contrast()
        con.chinese = c
        con.english = e
        return con
    }
    
}
