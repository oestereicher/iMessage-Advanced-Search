//
//  SearchResults.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/16/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
import Contacts

class SearchResults: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var messagesView: NSTableView!
    public var results = [MessageIDPair]()
    public var currentPerson = Messages()
    public var people = [Messages]()
    public var searchAllHandles = false
    public var searchByContact = false
    //TODO: array of offsets to keep track for each result
    private var offset = [Int]()
    private var messagesToShow = [Int]()
    private var selected: Int = -1
    var tableViewCellForSizing: NSTableCellView?
    let cellIdentifier2: String = "MessageID"
    private var cellHeights = [Int]()
    private var cellHeightsAll = [[Int]]()
    public var handleIDs = [String]()
    public var handleIDDict = [String: Int]()
    public var contactsDict = [String: CNContact]()
    public var haveSearchedAll = false
    func loadMore(amt: Int) {
        if selected >= 0 && selected < results.count {
            messagesToShow[selected] += amt
        }
    }
    @IBAction func loadMessagesUp(_ sender: Any) {
        if offset[selected] > 10 {
            loadMore(amt: 10)
            offset[selected] -= 10
        }
        else {
            loadMore(amt: offset[selected])
            offset[selected] = 0
        }
        messagesView.reloadData()
    }
    @IBAction func loadMessagesDown(_ sender: Any) {
        if selected >= 0 && selected < results.count {
            if offset[selected] + messagesToShow[selected] + 10 < currentPerson.messages.count {
                loadMore(amt: 10)
            }
            else {
                loadMore(amt: currentPerson.messages.count - offset[selected] - messagesToShow[selected])
            }
        }
        messagesView.reloadData()
    }
    
    func heightForCell(str: String) -> Int {
        let width = messagesView.frame.size.width
//        print("width: \(width)")
        //TODO: emojis require about 20 pixels... somehow take this into account
        let charsInWidth = width / 8
//        print("charsInWidth: \(charsInWidth)")
//        print(str)
        let length = str.count
//        print("length: \(String(describing: length))")
        let roundedLength = length + (Int(charsInWidth) - (length % Int(charsInWidth)))
//        print("roundedLength: \(roundedLength)")
        let height = (roundedLength / Int(charsInWidth)) * 16 + 4
//        print("height: \(height)")
        return height
    }
    
    func updateStatus() {
        //print(offset)
        let prevSelected = selected
        selected = tableView.selectedRow
        if selected != -1 {
            if offset[selected] == -1 {
                offset[selected] = Int(results[selected].message.idx)
            }
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
        if searchAllHandles {
            currentPerson = people[0]
        }
        if searchAllHandles {
            if cellHeightsAll.count < 1 { //search all and no cell heights recorded
                for person in people {
                    cellHeightsAll.append([Int](repeating: 20, count: person.messages.count))
                }
            }
            else if cellHeightsAll.count == 1 { //search all and one set of cell heights recorded
                cellHeightsAll = [[Int]]()
                for person in people {
                    cellHeightsAll.append([Int](repeating: 20, count: person.messages.count))
                }
            }
        }
        offset = [Int](repeating: -1, count: results.count)
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
    func makeMessageView(cell: NSTableCellView, row: Int) -> NSTableCellView {
        var currIdx: Int
        if selected != -1 && selected < offset.count {
            currIdx = row + offset[selected]
        }
        else {
            currIdx = row
        }
        if currIdx < currentPerson.messages.count && currIdx != -1 {
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
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIDMatch: String = "MatchID"
        let cellIDMatchAll: String = "MatchInAllID"
        let cellIDMessage: String = "MessageID"
        if searchAllHandles {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIDMatchAll), owner: nil) as? NSTableCellView {
                if row < results.count {
                    cell.textField?.stringValue = results[row].message.text
                    cell.toolTip = results[row].message.date
                    let contact = contactsDict[results[row].id]
                    if contact != nil && (contact?.imageDataAvailable)! {
                        cell.imageView?.image = NSImage(data: (contact?.imageData!)!)
                    }
                }
                return cell
            }
            else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIDMessage), owner: nil) as? NSTableCellView {
                return makeMessageView(cell: cell, row: row)
            }
        }
        else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIDMatch), owner: nil) as? NSTableCellView {
                if row < results.count {
                    cell.textField?.stringValue = results[row].message.text
                    cell.toolTip = results[row].message.date
                }
                return cell
            }
            else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIDMessage), owner: nil) as? NSTableCellView {
                return makeMessageView(cell: cell, row: row)
            }
        }
        return nil
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        if (tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MessageID"), owner: nil) != nil) {
            return
        }
        updateStatus()
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier2), owner: nil) != nil {
            guard tableViewCellForSizing != nil else {
                print("sad sad sda")
                return 17
                
            }
            var height = 0
            
            var currRow : Int
            if selected != -1 {
                if selected < offset.count {
                    currRow = row + offset[selected]
                }
                else {
                    currRow = row
                }
                if currRow < currentPerson.messages.count && currRow != -1 {
                    if cellHeightsAll.count > 1 && (!searchByContact || searchAllHandles) {
                        height = cellHeightsAll[handleIDDict[currentPerson.id]!][currRow]
                    }
                    else {
                        height = cellHeights[currRow]
                    }
    //                print("**LOOKING AT** \(currentPerson[row + offset])")
    //                print("for the height: row + offset \(row + offset)")
    //                print("for the height: height \(height)")
                }
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
