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
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let tabViewController = segue.destinationController
            as? NSTabViewController else { return }
        for controller in tabViewController.children {
            if let controller = controller as? SearchUI {
                searchUI = controller
                searchUI?.fullPath = self.fullPath
                searchUI?.contacts = self.contacts
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
