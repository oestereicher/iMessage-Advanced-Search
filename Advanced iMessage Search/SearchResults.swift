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
    public var results = [MessageIDPair]()
    public var currentPerson = Messages()
    public var people = [Messages]()
    public var searchAllHandles = false
    public var searchByContact = false
    private var offset: Int = 0
    private var messagesToShow = [Int]()
    private var selected: Int = -1
    var tableViewCellForSizing: NSTableCellView?
    let cellIdentifier2: String = "MessageID"
    private var cellHeights = [Int]()
    private var cellHeightsAll = [[Int]]()
    public var handleIDs = [String]()
    public var handleIDDict = [String: Int]()
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
            if offset + messagesToShow[selected] + 10 < currentPerson.messages.count {
                loadMore(amt: 10)
            }
            else {
                loadMore(amt: currentPerson.messages.count - offset - messagesToShow[selected])
            }
        }
        messagesView.reloadData()
    }
    
    func heightForCell(str: String) -> Int {
        let width = messagesView.frame.size.width
        print("width: \(width)")
        //TODO: emojis require about 20 pixels... somehow take this into account
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
            offset = Int(results[selected].message.idx)
            if searchAllHandles {
                currentPerson = people[handleIDDict[results[selected].id]!]
            }
//            print("OFFSET: \(offset)")
            messagesView.reloadData()
            let changedIndexes = IndexSet(integersIn: 0..<messagesView.numberOfRows)
            messagesView.noteHeightOfRows(withIndexesChanged: changedIndexes)
        }
        else {
            selected = prevSelected
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if !searchByContact {
            currentPerson = people[0]
        }
        if cellHeightsAll.count < 1 && searchAllHandles {
            for person in people {
                cellHeightsAll.append([Int](repeating: 20, count: person.messages.count))
            }
        }
        messagesToShow = [Int](repeating: 20, count: results.count)
        cellHeights = [Int](repeating: 20, count: currentPerson.messages.count)
        print(results.count)
        tableView.reloadData()
        //maybe:
        messagesView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if cellHeights.count < 1 {
            cellHeights = [Int](repeating: 20, count: currentPerson.messages.count)
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
        let cellIdentifier1: String = "MatchID"
        let cellIdentifier2: String = "MessageID"
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier1), owner: nil) as? NSTableCellView {
            if row < results.count {
                cell.textField?.stringValue = results[row].message.text
                cell.toolTip = results[row].message.date
            }
            return cell
        }
        else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier2), owner: nil) as? NSTableCellView {
            let currIdx = row + offset
            if currIdx < currentPerson.messages.count {
                let cellText = currentPerson.messages[currIdx].text
                cell.textField?.stringValue = cellText
//                print("CURRENT INDEX: \(currIdx)")
                if cellHeightsAll.count > 1 && (!searchByContact || searchAllHandles) {
                    cellHeightsAll[handleIDDict[currentPerson.id]!][currIdx] = heightForCell(str: cellText)
                }
                else {
                    cellHeights[currIdx] = heightForCell(str: cellText)
                }
                cell.toolTip = currentPerson.messages[currIdx].date
                if !currentPerson.messages[currIdx].is_from_me! {
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
            var height = 0
            if row + offset < currentPerson.messages.count {
                if cellHeightsAll.count > 1 && (!searchByContact || searchAllHandles) {
                    height = cellHeightsAll[handleIDDict[currentPerson.id]!][row + offset]
                }
                else {
                    height = cellHeights[row + offset]
                }
//                print("**LOOKING AT** \(currentPerson[row + offset])")
//                print("for the height: row + offset \(row + offset)")
//                print("for the height: height \(height)")
            }
            if height > 0 {
//                print("height: \(height)")
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
