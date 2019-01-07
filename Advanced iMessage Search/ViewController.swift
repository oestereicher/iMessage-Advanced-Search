//
//  ViewController.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/9/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
import SQLite3
import Contacts

class ViewController: NSViewController {

    public var fullPath = ""
    private var searchUI: SearchUI?
    public var store: CNContactStore!
    public var contacts = [CNContact]()
    public var gcIDHandlesDict = [String: [String]]() //chat* id --> handles in the chat
    public var handleGCsDict = [String: [String]]() //handle --> chat* ids its part of
    public var gcDisplayNames = [String]()
    public var displayNameGCDict = [String: String]()
    //need to pass below items down to the searchcontainer
    public var contactsDict = [String: CNContact]()
    public var contactNames = [String]()
    public var gcIDs = [String]()
    public var gcIDDict = [String: Int]()
    
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    @IBOutlet weak var pathName: NSTextField!
    @IBOutlet weak var message: NSTextField!
    @IBAction func pathEnter(_ sender: Any) {
        sayButtonClicked(self)
    }
    private func formatPhoneNumber(num: String, hasCountryCode: Bool) -> String {
        if hasCountryCode {
            return num.replacingOccurrences( of:"[^0-9+]", with: "", options: .regularExpression)
        }
        else {
            //TODO: this assumes that phone numbers not including country code are in the US. probably add an option somewhere so this can be chosen
            return ("+1" + num).replacingOccurrences( of:"[^0-9+]", with: "", options: .regularExpression)
        }
    }
    private func formatAnyPhoneNumber(phoneNum: CNLabeledValue<CNPhoneNumber>) -> String {
        let phoneStr = phoneNum.value.stringValue
        var formattedNum = ""
        //assumes that there is a country code in the number if there are more than 10 digits or if it begins with a +
        if phoneStr.replacingOccurrences( of:"[^0-9]", with: "", options: .regularExpression).count > 10 || phoneStr[phoneStr.startIndex] == "+" {
            formattedNum = formatPhoneNumber(num: phoneStr, hasCountryCode: true)
        }
        else {
            formattedNum = formatPhoneNumber(num: phoneStr, hasCountryCode: false)
        }
        return formattedNum
    }
    @IBAction func browseFile(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.title = "Select the directory containing a copy of chat.db"
        panel.showsResizeIndicator    = true
        panel.showsHiddenFiles        = false
        panel.canChooseDirectories    = true
        panel.canCreateDirectories    = true
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        
        if panel.runModal() == NSApplication.ModalResponse.OK {
            let result = panel.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                pathName.stringValue = path
                sayButtonClicked(self)
            }
        }
        else {
            //User clicked on "Cancel"
            return
        }
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
                CNContactThumbnailImageDataKey,
                CNContactImageDataKey] as [Any]
            
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
        
        for contact in self.contacts {
            if !(contact.givenName.isEmpty && contact.familyName.isEmpty) {
                let fullName = contact.givenName + " " + contact.familyName
                contactNames.append(fullName)
                contactsDict[fullName] = contact
            }
            for email in contact.emailAddresses {
                let emailStr = email.value as String
                if contactsDict[emailStr] == nil {
                    contactsDict[email.value as String] = contact
                }
            }
            for phoneNum in contact.phoneNumbers {
                let phoneStr = formatAnyPhoneNumber(phoneNum: phoneNum)
                if contactsDict[phoneStr] == nil {
                    contactsDict[phoneStr] = contact
                }
            }
        }
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
            var db: OpaquePointer?
            if sqlite3_open(self.fullPath, &db) != SQLITE_OK {
                print("error opening database")
            }
            var statement: OpaquePointer?
            var numGCs = 0
            if sqlite3_prepare_v2(db, "select distinct chat_identifier from chat where chat_identifier like 'chat%'", -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing select: \(errmsg)")
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                var gcID = ""
                if let cGCID = sqlite3_column_text(statement, 0) {
                    gcID = String(cString: cGCID)
                }
                gcIDs.append(gcID)
                gcIDDict[gcID] = numGCs
                numGCs += 1
                print("is there a gcID here? \(gcID)")
            }
            for gcID in gcIDs {
                print("here we have a group chat: \(gcID)")
                if sqlite3_prepare_v2(db, "select distinct display_name, id from (select handle.id, chat.guid, chat.room_name, chat.display_name, message.text, message.date, message.is_from_me, message.handle_id, message.ROWID as msg_row, handle.ROWID as handle_row from chat_message_join inner join chat on chat.ROWID = chat_message_join.chat_id inner join message on message.ROWID = chat_message_join.message_id and message.date = chat_message_join.message_date inner join chat_handle_join on chat.ROWID = chat_handle_join.chat_id inner join handle on handle.ROWID = chat_handle_join.handle_id where chat.chat_identifier != handle.id and chat.room_name = ? order by message.date)", -1, &statement, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("error preparing select: \(errmsg)")
                }
                if sqlite3_bind_text(statement, 1, gcID, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding group chat id: \(errmsg)")
                }
                var handlesInGroup = Set<String>()
                var displayName = ""
                var firstRow = true
                while sqlite3_step(statement) == SQLITE_ROW {
                    if firstRow {
                        if let cDisplayName = sqlite3_column_text(statement, 0) {
                            displayName = String(cString: cDisplayName)
                        }
                        firstRow = false
                    }
                    var handle = ""
                    if let cHandle = sqlite3_column_text(statement, 1) {
                        handle = String(cString: cHandle)
                    }
                    if !handle.isEmpty{
                        if !handlesInGroup.contains(handle) {
                            print("handle inserted: \(handle)")
                            handlesInGroup.insert(handle)
                            if handleGCsDict[handle] == nil {
                                handleGCsDict[handle] = [gcID]
                            }
                            else {
                                handleGCsDict[handle]?.append(gcID)
                            }
                        }
                    }
                }
                if handlesInGroup.count > 0 {
                    var gcName = ""
                    if !displayName.isEmpty {
                        gcName = displayName
                    }
                    else {
                        for handle in handlesInGroup {
                            let contact = contactsDict[handle]
                            if contact == nil {
                                gcName += (handle + ", ")
                            }
                            else {
                                gcName += (determineContactName(contact: contact!) + ", ")
                            }
                        }
                        gcName.removeLast(2)
                    }
                    gcDisplayNames.append(gcName)
                    displayNameGCDict[gcName] = gcID
                    gcIDHandlesDict[gcID] = Array(handlesInGroup)
                }
            }
            gcDisplayNames.sort()
//            print(gcDisplayNames)
            
            let storyBoard : NSStoryboard = NSStoryboard(name: "Main", bundle:nil)
            
            let searchContainer = storyBoard.instantiateController(withIdentifier: "SearchContainer") as! SearchContainer
            searchContainer.fullPath = self.fullPath
            searchContainer.contacts = self.contacts
            searchContainer.gcIDHandlesDict = self.gcIDHandlesDict
            searchContainer.handleGCsDict = self.handleGCsDict
            searchContainer.gcDisplayNames = self.gcDisplayNames
            searchContainer.displayNameGCDict = self.displayNameGCDict
            searchContainer.contactsDict = self.contactsDict
            searchContainer.contactNames = self.contactNames
            searchContainer.gcIDs = self.gcIDs
            searchContainer.gcIDDict = self.gcIDDict
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

