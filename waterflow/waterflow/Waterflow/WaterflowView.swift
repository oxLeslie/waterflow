//
//  WaterflowView.swift
//  AZB
//
//  Created by Ama on 11/1/16.
//  Copyright © 2016 Ama. All rights reserved.
//

import UIKit

@objc enum WaterflowMarginType: Int {
    
    case top
    case bottom
    case left
    case right
    case column
    case row
}

@objc protocol WaterflowDataSource: NSObjectProtocol {
    
    func numberOfCellsInWaterflow(waterflow: WaterflowView) -> Int
    
    func waterflow(waterflow: WaterflowView, cellAtIndex index: Int) -> WaterflowViewCell
    
    @objc optional func numberOfColumnsInWaterflow(waterflow: WaterflowView) -> Int
}

@objc protocol WaterflowDelegate: NSObjectProtocol {
    
    @objc optional func waterflow(waterflow: WaterflowView, heightAtIndex index: Int) -> CGFloat
    
    @objc optional func waterflow(waterflow: WaterflowView, didSelectAtIndex index: Int)
    
    @objc optional func waterflow(waterflow: WaterflowView, marginForType type: WaterflowMarginType) -> CGFloat
}

class WaterflowView: UIScrollView {

    // delegate
    var dataSource: WaterflowDataSource?
    var wfDelegate: WaterflowDelegate?
    
    fileprivate lazy var cellFrames = NSMutableArray()
    fileprivate lazy var displayingCells = NSMutableDictionary()
    fileprivate lazy var reusableCells = NSMutableSet()
    
    //  默认值
    fileprivate let WaterflowDefaultCellH: CGFloat = 44
    fileprivate let WaterflowDefaultMargin: CGFloat = 1
    fileprivate let WaterflowDefaultNumberOfColumns: Int = 3
    
    // 遮罩层
    fileprivate lazy var matteView: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        return view
    }()
    
    // 用于记录 cell
    fileprivate var cTupe: (NSNumber?, WaterflowViewCell?)
    
    override func willMove(toSuperview newSuperview: UIView?) {
        reloadData()
    }
}

// MARK: - public method
extension WaterflowView {
    func cellWidth() -> CGFloat {
        let columns = numberOfColumns()
        let leftM = marginForType(type: .left)
        let rightM = marginForType(type: .right)
        let columnM = marginForType(type: .column)
        
        return (bounds.width - leftM - rightM - (CGFloat(columns) - 1) * columnM) / CGFloat(columns)
    }
    
    func reloadData() {
        /*!
         displayingCells为当前屏幕显示的 cell，是一个字典，
         因此通过 allValues 可获取到字典中所有的 cell 对象，
         forEach方法属于 for 循环的特殊用法（在forEach闭包中，
         $0表示 字典中的 value，当然也可用闭包通用形式中 {value in method} 来编写），
         这里需要移除所有的 cell。
         */
        displayingCells.allValues.forEach {
            ($0 as AnyObject).removeFromSuperview()
        }
        
        // 清空数组、字典、集合
        displayingCells.removeAllObjects()
        cellFrames.removeAllObjects()
        reusableCells.removeAllObjects()
        
        // 获取 cell 的总数
        let cells = dataSource?.numberOfCellsInWaterflow(waterflow: self)
        
        // waterflow 的列数
        let columns = numberOfColumns()
        
        // cell 间的间隙
        let topM = marginForType(type: .top)
        let bottomM = marginForType(type: .bottom)
        let leftM = marginForType(type: .left)
        let columnM = marginForType(type: .column)
        let rowM = marginForType(type: .row)
        
        let cellW = cellWidth()
        
        // 创建一个空的数组，大小为columns
        var maxYOfColumns: Array<CGFloat> = Array(repeating: 0.0, count: columns)
        // 循环初始化所有列的最大 y 值，瀑布流中每一行的 cell 所在位置是上一行中 y 值最小的 cell
        for i in 0..<columns {
            maxYOfColumns[i] = 0.0
        }
        
        // cells == nil return
        guard let _cells = cells else {
            return
        }
        
        for i in 0..<_cells {
            // 找出 y 值最小的 cell
            var cellColumn = 0
            var maxYOfCellColumn = maxYOfColumns[cellColumn]
            for j in 1..<columns {
                if maxYOfColumns[j] < maxYOfCellColumn {
                    cellColumn = j
                    maxYOfCellColumn = maxYOfColumns[j]
                }
            }
            
            let cellH = heightAtIndex(index: i)
            
            let cellX: CGFloat = leftM + CGFloat(cellColumn) * (cellW + columnM)
            var cellY: CGFloat = 0.0
            
            if maxYOfCellColumn == 0.0 {
                cellY = topM
            } else {
                cellY = maxYOfCellColumn + rowM
            }
            
            // 把 cell 的 frame 添加到 cellFrame 数组中，并记录当前列的最大 y 值
            let cellFrame = CGRect(x: cellX, y: cellY, width: cellW, height: cellH)
            cellFrames.add(NSValue(cgRect: cellFrame))
            maxYOfColumns[cellColumn] = cellFrame.maxY
        }
        
        var contentH = maxYOfColumns[0]
        for j in 0..<columns {
            if maxYOfColumns[j] > contentH {
                contentH = maxYOfColumns[j]
            }
        }
        
        contentH += bottomM
        // 设置 scrollView 的 contentSize
        contentSize = CGSize(width: 0, height: contentH)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 索要对应位置的 cell
        let cells = cellFrames.count
        for i in 0..<cells {
            // 取出 i index 中的 frame
            let cellFrame = (cellFrames[i] as AnyObject).cgRectValue
            // 优先从字典中取出 cell
            var cell: WaterflowViewCell? = displayingCells[i] as? WaterflowViewCell
            
            // 判断对应的 frame 在不在屏幕上
            if isInScreen(frame: cellFrame!) {
                
                // 如果 frame 在屏幕上，但是 cell 并没有被创建，
                // 则创建 cell，并且存放进 displayingCells字典中
                guard cell != nil else {
                    cell = dataSource?.waterflow(waterflow: self, cellAtIndex: i)
                    cell!.frame = cellFrame!
                    addSubview(cell!)
                    displayingCells[i] = cell
                    
                    continue
                }
                
                continue
                
            } else {
                
                // 如果不在，则把 cell 从当前屏幕中移除，并添加到缓存中
                guard let cell = cell else {
                    continue
                }
                
                cell.removeFromSuperview()
                displayingCells.removeObject(forKey: i)
                reusableCells.add(cell)
            }
        }
    }
    
    func dequeueReusableCellWithIdentifier(identifier: String) -> AnyObject? {
        var reusableCell: WaterflowViewCell?
        for cell in reusableCells {
            let cell = cell as! WaterflowViewCell
            if cell.identifier == identifier {
                reusableCell = cell
                break
            }
        }
        
        if reusableCell != nil {
            reusableCells.remove(reusableCell!)
        }
        return reusableCell
    }
}

// MARK: - private
extension WaterflowView {
    fileprivate func isInScreen(frame: CGRect) -> Bool {
        return (frame.maxY > contentOffset.y) &&
            (frame.maxY < contentOffset.y + bounds.height)
    }
    
    fileprivate func marginForType(type: WaterflowMarginType) -> CGFloat {

        return wfDelegate?.waterflow?(waterflow: self, marginForType: type) ?? WaterflowDefaultMargin
    }
    
    fileprivate func numberOfColumns() -> Int {
        return dataSource?.numberOfColumnsInWaterflow?(waterflow: self) ?? WaterflowDefaultNumberOfColumns
    }
    
    fileprivate func heightAtIndex(index: Int) -> CGFloat {

        return wfDelegate?.waterflow?(waterflow: self, heightAtIndex: index) ?? WaterflowDefaultCellH
    }
}

// MARK: - action
extension WaterflowView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard wfDelegate != nil else {
            return
        }
        
        let cellTupe = getCurrentTouchView(touches: touches)
        let cell = cellTupe.1
        
        guard let _cell = cell else {
            return
        }
        
        cTupe = cellTupe
        
        // 添加遮罩
        matteView.frame = _cell.bounds
        _cell.addSubview(matteView)
        _cell.bringSubview(toFront: matteView)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let wfDelegate = wfDelegate else {
            return
        }
        
        let cellTupe = getCurrentTouchView(touches: touches)
        let selectIdx = cellTupe.0
        
        if selectIdx == cTupe.0 {
            
            let cell = cellTupe.1
            
            // 移除遮罩
            let matteV = cell?.subviews.last
            matteV?.removeFromSuperview()
            
            if (selectIdx != nil) {
                wfDelegate.waterflow?(waterflow: self, didSelectAtIndex: selectIdx!.intValue)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let cellTupe = getCurrentTouchView(touches: touches)
        // 如果不在点击层 移除遮罩
        if cTupe.0 != cellTupe.0 {
            let matteV = cTupe.1!.subviews.last
            matteV?.removeFromSuperview()
        } else {
            // 如果在点击层且没有遮罩，添加遮罩
            if cellTupe.1!.subviews.last != matteView {
                matteView.frame = cellTupe.1!.bounds
                cellTupe.1!.addSubview(matteView)
                cellTupe.1!.bringSubview(toFront: matteView)
            }
        }
    }
    
    private func getCurrentTouchView(touches: Set<UITouch>) -> (NSNumber?, WaterflowViewCell?) {
        let touch: UITouch = (touches as NSSet).anyObject() as! UITouch
        let point = touch.location(in: self)
        
        var selectIdx: NSNumber?
        var selectCell: WaterflowViewCell?
        
        // 获取点击层对应的 cell
        for (key, value) in displayingCells {
            let cell = value as! WaterflowViewCell
            if cell.frame.contains(point) {
                selectIdx = (key as! NSNumber)
                selectCell = cell
                break
            }
        }
        return (selectIdx, selectCell)
    }
    
}

