//
//  ViewController.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/9/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
import SQLite3

class ViewController: NSViewController {

    public var fullPath = ""
    private var searchUI: SearchUI?
    

    @IBOutlet weak var pathName: NSTextField!
    @IBOutlet weak var message: NSTextField!
    @IBAction func pathEnter(_ sender: Any) {
        sayButtonClicked(self)
    }
    
    @IBAction func sayButtonClicked(_ sender: Any) {
        var pathStr = pathName.stringValue
        var success = true
        let fileManager = FileManager.default
        /*if pathStr.isEmpty {
            success = false
        }*/
        //else {
        if !pathStr.isEmpty {
            //TODO: if they put a ~ make this put their home directory
            if (pathStr.prefix(1) == "~") {
                pathStr.remove(at: pathStr.startIndex)
                pathStr = fileManager.homeDirectoryForCurrentUser.path + pathStr
            }
            while pathStr[pathStr.index(before: pathStr.endIndex)] == "/" {
                pathStr.remove(at: pathStr.index(before: pathStr.endIndex))
            }
        }
        print(pathStr)
        if fileManager.fileExists(atPath: pathStr + "/chat.db") {
            print("lit the file is there")
        }
        else {
            success = false
            print("terrible the file isn't there ")
        }
        
        //}
        if success {
            fullPath = pathStr + "/chat.db"
            message.stringValue = "guud you entered path: \(pathStr) and chat.db is there"
            //let fileURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chat.db")
            var db: OpaquePointer?
            //print(fileURL.path)
            if sqlite3_open(fullPath, &db) != SQLITE_OK {
                print("error opening database")
            }
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, "select ROWID from chat limit 5", -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing select: \(errmsg)")
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                print("id = \(id); ", terminator: "")
            }
            if sqlite3_finalize(statement) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error finalizing prepared statement: \(errmsg)")
            }
            
            statement = nil
            if sqlite3_close(db) != SQLITE_OK {
                print("error closing database")
            }
            
            let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
            
            let searchContainer = storyBoard.instantiateController(withIdentifier: "SearchContainer") as! SearchContainer
            searchContainer.fullPath = self.fullPath
            self.presentAsModalWindow(searchContainer)
        }
        else {
            message.stringValue = "something went wrong :("
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let tabViewController = segue.destinationController
            as? NSTabViewController else { return }
        for controller in tabViewController.children {
            if let controller = controller as? SearchUI {
                searchUI = controller
                searchUI?.fullPath = self.fullPath
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

