//
//  ViewController.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/9/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
//import SQLite3
import Contacts

class ViewController: NSViewController {

    public var fullPath = ""
    private var searchUI: SearchUI?
    public var store: CNContactStore!
    public var contacts = [CNContact]()
    

    @IBOutlet weak var pathName: NSTextField!
    @IBOutlet weak var message: NSTextField!
    @IBAction func pathEnter(_ sender: Any) {
        sayButtonClicked(self)
    }
    
    @IBAction func sayButtonClicked(_ sender: Any) {
        //store = CNContactStore()
//        store.requestAccess(for: .contacts, completionHandler: {
//            (granted, error) -> Void in
//            print("imma request access to the contacts")
//            if granted {
//                print("lit lit lit i can see all ur private info ehehehe")
//                //self.contactsGranted()
//            }
//            else {
//                print("WHY YOU NOT GRANT")
//            }
//        })
        contacts = {
            let contactStore = CNContactStore()
            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey] as [Any]
            
            // Get all the containers
            var allContainers: [CNContainer] = []
            do {
                allContainers = try contactStore.containers(matching: nil)
            } catch {
                print("Error fetching containers")
            }
            
            var results: [CNContact] = []
            
            // Iterate all containers and append their contacts to our results array
            for container in allContainers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                do {
                    let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                    results.append(contentsOf: containerResults)
                } catch {
                    print("Error fetching results for container")
                }
            }
            
            return results
        }()
        contacts = contacts.sorted(by: {
            if $0.familyName.isEmpty && $1.familyName.isEmpty {
                return $0.givenName < $1.givenName
            }
            else if $0.familyName.isEmpty && !$1.familyName.isEmpty {
                return $0.givenName < $1.familyName
            }
            else if !$0.familyName.isEmpty && $1.familyName.isEmpty {
                return $0.familyName < $1.givenName
            }
            else if $0.familyName == $1.familyName {
                return $0.givenName < $1.givenName
            }
            else {
                return $0.familyName < $1.familyName
            }
        })
//        for contact in contacts {
//            print(contact.givenName)
//        }
        ////////////
//        do {
//            let contacts = try store.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: "Sarah Oestereicher"), keysToFetch:[CNContactNicknameKey as CNKeyDescriptor])
//            print("HI I'M HERE UM HELLO")
//            if contacts.count > 0 {
//                for contact in contacts {
//                    print(contact.nickname)
//                }
//            }
//        }
//        catch {print("cri cri cri")}
        var pathStr = pathName.stringValue
        var success = true
        let fileManager = FileManager.default
        if !pathStr.isEmpty {
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
        if success {
            fullPath = pathStr + "/chat.db"
            message.stringValue = "chat.db found at \(pathStr)"
            //let fileURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chat.db")
//            var db: OpaquePointer?
//            //print(fileURL.path)
//            if sqlite3_open(fullPath, &db) != SQLITE_OK {
//                print("error opening database")
//            }
//            var statement: OpaquePointer?
//            if sqlite3_prepare_v2(db, "select ROWID from chat limit 5", -1, &statement, nil) != SQLITE_OK {
//                let errmsg = String(cString: sqlite3_errmsg(db)!)
//                print("error preparing select: \(errmsg)")
//            }
//            while sqlite3_step(statement) == SQLITE_ROW {
//                let id = sqlite3_column_int64(statement, 0)
//                print("id = \(id); ", terminator: "")
//            }
//            if sqlite3_finalize(statement) != SQLITE_OK {
//                let errmsg = String(cString: sqlite3_errmsg(db)!)
//                print("error finalizing prepared statement: \(errmsg)")
//            }
//
//            statement = nil
//            if sqlite3_close(db) != SQLITE_OK {
//                print("error closing database")
//            }
            
            let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
            
            let searchContainer = storyBoard.instantiateController(withIdentifier: "SearchContainer") as! SearchContainer
            searchContainer.fullPath = self.fullPath
            searchContainer.contacts = self.contacts
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
                //searchUI?.fullPath = self.fullPath
                //searchUI?.contacts = self.contacts
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

