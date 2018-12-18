//
//  SearchContainer.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/15/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa

class SearchContainer: NSViewController {
    
    private var searchUI: SearchUI?
    private var searchResults: SearchResults?
    public var fullPath = ""
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let tabViewController = segue.destinationController
            as? NSTabViewController else { return }
        for controller in tabViewController.children {
            if let controller = controller as? SearchUI {
                searchUI = controller
                searchUI?.fullPath = self.fullPath
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
