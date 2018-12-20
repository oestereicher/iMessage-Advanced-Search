//
//  SearchResults.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/16/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa

class SearchResults: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var messagesView: NSTableView!
    public var results = [MessageStruct]()
    public var currentPerson = [MessageStruct]()
    private var offset: Int = 0
    private var messagesToShow = [Int]()
    private var selected: Int = -1
    var tableViewCellForSizing: NSTableCellView?
    let cellIdentifier2: String = "MessageID"
    private var cellHeights = [Int]()
    @IBAction func testButton(_ sender: Any) {
        print("da button did the press")
        print(results.count)
        for (idx, result) in self.results.enumerated() {
            print("self_row: \(result.idx); ", terminator: "")
            print("idx: \(idx); ", terminator: "")
            print("text: \(result.text)")
        }
    }
    func loadMore(amt: Int) {
        if selected >= 0 && selected < results.count {
            messagesToShow[selected] += amt
        }
    }
    @IBAction func loadMessagesUp(_ sender: Any) {
        if offset > 10 {
            loadMore(amt: 10)
            offset -= 10
        }
        else {
            loadMore(amt: offset)
            offset = 0
        }
        messagesView.reloadData()
    }
    @IBAction func loadMessagesDown(_ sender: Any) {
        if selected >= 0 && selected < results.count {
            if offset + messagesToShow[selected] + 10 < currentPerson.count {
                loadMore(amt: 10)
            }
            else {
                loadMore(amt: currentPerson.count - offset - messagesToShow[selected])
            }
        }
        messagesView.reloadData()
    }
    
    func heightForCell(str: String) -> Int {
        let width = messagesView.frame.size.width
        print("width: \(width)")
        let charsInWidth = width / 8
        print("charsInWidth: \(charsInWidth)")
        print(str)
        let length = str.count
        print("length: \(String(describing: length))")
        let roundedLength = length + (Int(charsInWidth) - (length % Int(charsInWidth)))
        print("roundedLength: \(roundedLength)")
        let height = (roundedLength / Int(charsInWidth)) * 16 + 4
        print("height: \(height)")
        return height
    }
    
    func updateStatus() {
        let prevSelected = selected
        selected = tableView.selectedRow
        if selected != -1 {
            offset = Int(results[selected].idx)
            print("OFFSET: \(offset)")
            messagesView.reloadData()
            let changedIndexes = IndexSet(integersIn: 0..<messagesView.numberOfRows)
            messagesView.noteHeightOfRows(withIndexesChanged: changedIndexes)
            print("oh boiiiiii")
        }
        else {
            selected = prevSelected
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        messagesToShow = [Int](repeating: 20, count: results.count)
//        if cellHeights.count < 1 {
//            cellHeights = [Int](repeating: 20, count: currentPerson.count)
//        }
        cellHeights = [Int](repeating: 20, count: currentPerson.count)
        print(results.count)
        tableView.reloadData()
        //maybe:
        messagesView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if cellHeights.count < 1 {
            cellHeights = [Int](repeating: 20, count: currentPerson.count)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        messagesView.delegate = self
        messagesView.dataSource = self
    }
    
}

extension SearchResults: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        //TODO: find a less jank way to check which table we're looking at
        if (tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MatchID"), owner: nil) != nil) {
            return results.count
        }
        else {
            if selected < 0 || selected >= results.count {
                return 20
            }
            else {
                print(selected)
                return messagesToShow[selected]
            }
        }
    }
}
extension SearchResults: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //var text: String = ""
        let cellIdentifier1: String = "MatchID"
        let cellIdentifier2: String = "MessageID"
//        if row >= results.count {
//            return nil
//        }
        //text = results[row][1]
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier1), owner: nil) as? NSTableCellView {
            if row < results.count {
                cell.textField?.stringValue = results[row].text
                cell.toolTip = results[row].date
            }
            //cell.textField?.maximumNumberOfLines = 2
            return cell
        }
        else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier2), owner: nil) as? NSTableCellView {
            let currIdx = row + offset
            if currIdx < currentPerson.count {
                let cellText = currentPerson[currIdx].text
                cell.textField?.stringValue = cellText
                print("CURRENT INDEX: \(currIdx)")
                cellHeights[currIdx] = heightForCell(str: cellText)
                cell.toolTip = currentPerson[currIdx].date
                if !currentPerson[currIdx].is_from_me! {
                    cell.textField?.textColor = NSColor.red
//                    cell.textField?.backgroundColor = NSColor.blue
//                    cell.textField?.isBezeled = false
//                    cell.textField?.isEditable = false
//                    cell.textField?.drawsBackground = false
                }
                else {
                    cell.textField?.textColor = NSColor.controlTextColor
                }
            }
            tableViewCellForSizing = cell
            return cell
        }
        return nil
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateStatus()
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier2), owner: nil) != nil {
            guard tableViewCellForSizing != nil else {
                print("sad sad sda")
                return 17
                
            }
//            if row + offset < currentPerson.count {
//                tableCellView.textField?.stringValue = currentPerson[row + offset][1]
//            }
//            let width = messagesView.frame.size.width
//            let charsInWidth = width / 8
//            print("charsInWidth: \(charsInWidth)")
//            print(tableViewCellForSizing?.textField?.stringValue)
//            let length = tableViewCellForSizing?.textField?.stringValue.count
//            print("length: \(String(describing: length))")
//            let roundedLength = length! + (Int(charsInWidth) - (length! % Int(charsInWidth)))
//            print(width)
//            let height = (Int(charsInWidth) * 20) / roundedLength
            var height = 0
            if row + offset < currentPerson.count {
                height = cellHeights[row + offset]
                print("**LOOKING AT** \(currentPerson[row + offset])")
                print("for the height: row + offset \(row + offset)")
                print("for the height: height \(height)")
            }
            if height > 0 {
                print("height: \(height)")
                return CGFloat(height)
            }
        }
        
        return 44
    }
    func tableViewColumnDidResize(_ notification: Notification) {
        let allIndexes = IndexSet(integersIn: 0..<messagesView.numberOfRows)
        messagesView.noteHeightOfRows(withIndexesChanged: allIndexes)
        messagesView.reloadData()
    }
}
