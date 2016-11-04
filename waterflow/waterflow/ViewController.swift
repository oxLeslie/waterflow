//
//  ViewController.swift
//  waterflow
//
//  Created by Ama on 11/4/16.
//  Copyright © 2016 Ama. All rights reserved.
//

import UIKit

class ViewController: UIViewController,WaterflowDelegate,WaterflowDataSource {

    var wf: WaterflowView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        wf = WaterflowView(frame: view.bounds)
        wf?.dataSource = self
        wf?.wfDelegate = self
        
        wf?.autoresizingMask = .flexibleWidth
        
        view.addSubview(wf!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - datasource
    func numberOfCellsInWaterflow(waterflow: WaterflowView) -> Int {
        return 100
    }
    
    func waterflow(waterflow: WaterflowView, cellAtIndex index: Int) -> WaterflowViewCell {
        var cell = waterflow.dequeueReusableCellWithIdentifier(identifier: "wfCell") as? WaterflowViewCell
        if cell == nil {
            cell = WaterflowViewCell()
            cell?.identifier = "wfCell"
        }
        cell?.backgroundColor = randomColor()
        return cell!
    }
    
    func numberOfColumnsInWaterflow(waterflow: WaterflowView) -> Int {
        if UIInterfaceOrientationIsPortrait(preferredInterfaceOrientationForPresentation) {
            return 3
        } else {
            return 5
        }
    }
    
    // MARK: - wfdelegate
    func waterflow(waterflow: WaterflowView, didSelectAtIndex index: Int) {
        print(index)
    }
    
    func waterflow(waterflow: WaterflowView, heightAtIndex index: Int) -> CGFloat {
        return (index % 2 == 0) ? 100 : 70
    }
    
    func waterflow(waterflow: WaterflowView, marginForType type: WaterflowMarginType) -> CGFloat {
        return 2
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        wf?.reloadData()
    }
    
    func randomColor() -> UIColor {
        let red: CGFloat   = CGFloat(arc4random_uniform(256))/255
        let green: CGFloat = CGFloat(arc4random_uniform(256))/255
        let blue: CGFloat  = CGFloat(arc4random_uniform(256))/255
        let alpha: CGFloat = 1.0
        return UIColor.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

