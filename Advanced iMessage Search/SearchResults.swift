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
    public var results = [[String]]()
    public var currentPerson = [[String]]()
    private var offset: Int = 0
    private var messagesToShow = [Int]()
    private var selected: Int = -1
    @IBAction func testButton(_ sender: Any) {
        print("da button did the press")
        print(results.count)
        for (idx, result) in self.results.enumerated() {
            print("self_row: \(result[0]); ", terminator: "")
            print("idx: \(idx); ", terminator: "")
            print("text: \(result[1])")
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
        if offset + messagesToShow[selected] + 10 < currentPerson.count {
            loadMore(amt: 10)
        }
        else {
            loadMore(amt: currentPerson.count - offset - messagesToShow[selected])
        }
        messagesView.reloadData()
    }
    
    func updateStatus() {
        let prevSelected = selected
        selected = tableView.selectedRow
        if selected != -1 {
            offset = Int(results[selected][0])!
            print(offset)
            messagesView.reloadData()
        }
        else {
            selected = prevSelected
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        messagesToShow = [Int](repeating: 20, count: results.count)
        print(results.count)
        tableView.reloadData()
        //maybe:
        messagesView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
                cell.textField?.stringValue = results[row][1]
            }
            //cell.textField?.maximumNumberOfLines = 2
            return cell
        }
        else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier2), owner: nil) as? NSTableCellView {
            if row + offset < currentPerson.count {
                cell.textField?.stringValue = currentPerson[row + offset][1]
                if Int(currentPerson[row + offset][2]) == 0 {
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
            return cell
        }
        return nil
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateStatus()
    }
}
