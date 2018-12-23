//
//  SearchContainer.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/15/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
import Contacts

class SearchContainer: NSViewController {
    
    private var searchUI: SearchUI?
    private var searchResults: SearchResults?
    public var fullPath = ""
    public var contacts = [CNContact]()
    public var gcIDHandlesDict = [String: [String]]() //chat* id --> handles in the chat
    public var handleGCsDict = [String: [String]]() //handle --> chat* ids its part of
    public var gcDisplayNames = [String]()
    public var displayNameGCDict = [String: String]()
    public var contactsDict = [String: CNContact]()
    public var contactNames = [String]()
    public var gcIDs = [String]()
    public var gcIDDict = [String: Int]()
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let tabViewController = segue.destinationController
            as? NSTabViewController else { return }
        for controller in tabViewController.children {
            if let controller = controller as? SearchUI {
                searchUI = controller
                searchUI?.fullPath = self.fullPath
                searchUI?.contacts = self.contacts
                searchUI?.gcIDHandlesDict = self.gcIDHandlesDict
                searchUI?.handleGCsDict = self.handleGCsDict
                searchUI?.gcDisplayNames = self.gcDisplayNames
                searchUI?.displayNameGCDict = self.displayNameGCDict
                searchUI?.contactsDict = self.contactsDict
                searchUI?.contactNames = self.contactNames
                searchUI?.handleIDs = self.gcIDs
                searchUI?.handleIDDict = self.gcIDDict
            }
            if let controller = controller as? SearchResults {
                searchResults = controller
                searchResults?.results = (searchUI?.results)!
            }
        }
        searchUI?.resultsTab = searchResults
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
}

struct Message {
    var idx: Int64
    var text: String
    var is_from_me: Bool?
    var date: String
    var handle: String?
    var displayName: String?
    
    init(idx: Int64, text: String, is_from_me: Int64, date: String, handle: String, displayName: String) {
        self.idx = idx
        self.text = text
        self.is_from_me = (is_from_me == 1)
        self.date = date
        self.handle = handle
        if !displayName.isEmpty {
            self.displayName = displayName
        }
        else {
            self.displayName = "Group chat"
        }
    }
    init(idx: Int64, text: String, is_from_me: Int64, date: String) {
        self.idx = idx
        self.text = text
        self.is_from_me = (is_from_me == 1)
        self.date = date
    }
    init(idx: Int64, text: String, date: String) {
        self.idx = idx
        self.text = text
        self.date = date
    }
}

struct Messages {
    var messages: [Message]
    var id: String
    
    init() {
        self.messages = [Message]()
        self.id = ""
    }
    init(messages: [Message], id: String) {
        self.messages = messages
        self.id = id
    }
}

struct MessageIDPair {
    var message: Message
    var id: String
}
