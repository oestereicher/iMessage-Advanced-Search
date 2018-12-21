//
//  SearchUI.swift
//  Advanced iMessage Search
//
//  Created by Brandon Oestereicher on 12/9/18.
//  Copyright © 2018 Brandon Oestereicher. All rights reserved.
//

import Cocoa
import Contacts
import SQLite3

class SearchUI: NSViewController {
    
    public var fullPath = ""
    private let opts = ["Contains", "Starts With", "Ends With", "Exactly"]
    public var results = [MessageIDPair]()
    public var resultsTab: SearchResults?
    public var people = [Messages]()
    public var contactOrPhonePerson = Messages()
    private var fromDateStr = ""
    private var toDateStr = ""
    public var contacts = [CNContact]()
    private var contactsDict = [String: CNContact]()
    let dateFormatter = DateFormatter()
    public var handleIDs = [String]()
    public var handleIDDict = [String: Int]()
    private var searchByContact = true
    public var searchAllHandles = false
    
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    
    @IBOutlet weak var searchAll: NSButton!
    @IBOutlet weak var searchBy: NSPopUpButtonCell!
    @IBOutlet weak var contactName: NSPopUpButton!
    @IBOutlet weak var fromDate: NSDatePicker!
    @IBOutlet weak var toDate: NSDatePicker!
    @IBOutlet weak var anyDate: NSButton!
    @IBOutlet weak var countries: NSPopUpButton!
    @IBAction func idPressEnter(_ sender: Any) {
        sayButtonClicked(self)
    }
    @IBAction func searchTextPressEnter(_ sender: Any) {
        sayButtonClicked(self)
    }
    @IBOutlet weak var searchMessage: NSTextField!
    @IBOutlet weak var searchOpts: NSPopUpButton!
    @IBOutlet weak var contactID: NSTextField!
    @IBOutlet weak var searchText: NSTextField!
//    private func contactsGranted() {
//        print("heyo in the contacts granted function")
//        let contacts = try! store.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: contactID.stringValue), keysToFetch:[CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
//        // Checking if phone number is available for the given contact.
//        if (contacts[0].isKeyAvailable(CNContactPhoneNumbersKey)) {
//            print("\(contacts[0].phoneNumbers)")
//        } else {
//            //Refetch the keys
//            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
//            let refetchedContact = try! store.unifiedContact(withIdentifier: contacts[0].identifier, keysToFetch: keysToFetch as [CNKeyDescriptor])
//            print("\(refetchedContact.phoneNumbers)")
//        }
//    }
    private func isPhoneNumber(num: String) -> Bool {
        return true
    }
    private func formatPhoneNumber(num: String, hasCountryCode: Bool) -> String {
        if hasCountryCode {
            return num.replacingOccurrences( of:"[^0-9+]", with: "", options: .regularExpression)
        }
        else {
            return (countries.titleOfSelectedItem! + num).replacingOccurrences( of:"[^0-9+]", with: "", options: .regularExpression)
        }
    }
    private func formatDate(date: Int64) -> String {
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.dateFormat = "MM/dd/yy, h:mm:ss a"
        return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(date/1000000000 + 978307200)))
    }
    private func searchDB(phone: String, search: String) -> Int {
        searchAllHandles = searchAll.state == .on
        //Search must include some restriction (date or text)
        if search.isEmpty && anyDate.state == .on {
            return -1
        }
        //open connection to database
        var db: OpaquePointer?
        if sqlite3_open(self.fullPath, &db) != SQLITE_OK {
            print("error opening database")
        }
        var statement: OpaquePointer?
        var numHandles = 0
        people = [Messages]()
        if searchAllHandles { //searching through all messages
            if sqlite3_prepare_v2(db, "select distinct id from handle", -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing select: \(errmsg)")
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                var handleID = ""
                if let cHandleID = sqlite3_column_text(statement, 0) {
                    handleID = String(cString: cHandleID)
                }
                handleIDs.append(handleID)
                handleIDDict[handleID] = numHandles
                numHandles += 1
            }
        }
        if !searchAllHandles {
            numHandles = 1
        }
        var resultsIdx = 0
        //drop table if exists and create table of one_person with entries numbered
        for handleIdx in 0..<numHandles {
            //clear currentPerson
            var currentPerson = [Message]()
            if sqlite3_exec(db, "drop table if exists numbered_person", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error dropping table: \(errmsg)")
            }
            if sqlite3_exec(db, "create table numbered_person (guid TEXT, text TEXT, date INTEGER, is_from_me INTEGER, idx INTEGER)", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error creating numbered_person table: \(errmsg)")
            }
            var onePersQuery = "select chat.guid, message.text, message.date, message.is_from_me, message.ROWID as row from chat_message_join inner join chat on chat.ROWID = chat_message_join.chat_id inner join message on message.ROWID = chat_message_join.message_id and message.date = chat_message_join.message_date where chat.ROWID in ( select chat.ROWID from chat_handle_join inner join chat on chat.ROWID = chat_handle_join.chat_id inner join handle on handle.ROWID = chat_handle_join.handle_id where chat.chat_identifier = handle.id and handle.id in (?"
            if searchByContact && !searchAllHandles { //search by contact
                let contact = contactsDict[contactName.titleOfSelectedItem!]
                var numPossibleChatIDs = 0
                //TODO: make sure there aren't duplicate phone numbers or emails
                numPossibleChatIDs += (contact?.emailAddresses.count)!
                numPossibleChatIDs += (contact?.phoneNumbers.count)!
                if numPossibleChatIDs == 0 {
                    return 0
                }
                else {
                    for _ in 0..<numPossibleChatIDs {
                        onePersQuery += ",?"
                    }
                }
            }
            onePersQuery += ")) order by message.date"
            if sqlite3_prepare_v2(db, onePersQuery, -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing select: \(errmsg)")
            }
            var idForSearch = ""
            if searchByContact && !searchAllHandles { //search by contact
                var paramNum = 1
                let contact = contactsDict[contactName.titleOfSelectedItem!]
                for phoneNum in (contact?.phoneNumbers)! {
                    print(formatPhoneNumber(num: phoneNum.value.stringValue, hasCountryCode: true))
                    let phoneStr = phoneNum.value.stringValue
                    var formattedNum = ""
                    //assumes that there is a country code in the number if there are more than 10 digits
                    if phoneStr.replacingOccurrences( of:"[^0-9]", with: "", options: .regularExpression).count > 10 {
                        formattedNum = formatPhoneNumber(num: phoneStr, hasCountryCode: true)
                    }
                    else {
                        formattedNum = formatPhoneNumber(num: phoneStr, hasCountryCode: false)
                    }
                    idForSearch += (formattedNum + ",")
                    if sqlite3_bind_text(statement, Int32(paramNum), formattedNum, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                        let errmsg = String(cString: sqlite3_errmsg(db)!)
                        print("failure binding phone number: \(errmsg)")
                    }
                    paramNum += 1
                }
                for email in (contact?.emailAddresses)! {
                    print(email.value as String)
                    idForSearch += (email.value as String + ",")
                    if sqlite3_bind_text(statement, Int32(paramNum), email.value as String, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                        let errmsg = String(cString: sqlite3_errmsg(db)!)
                        print("failure binding email: \(errmsg)")
                    }
                    paramNum += 1
                }
                if paramNum > 1 { //remove trailing comma
                    idForSearch.remove(at: idForSearch.index(before: idForSearch.endIndex))
                }
            }
            else { //search by phone number
                var thisPhone = ""
                if searchAllHandles {
                    thisPhone = handleIDs[handleIdx]
                }
                else {
                    thisPhone = phone
                }
                idForSearch = thisPhone
                if sqlite3_bind_text(statement, 1, thisPhone, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding phone number: \(errmsg)")
                }
            }
            var idx = 0
            while sqlite3_step(statement) == SQLITE_ROW {
                var statement2: OpaquePointer?
                var guid = ""
                if let cGuid = sqlite3_column_text(statement, 0) {
                    guid = String(cString: cGuid)
                }
                var text = ""
                if let cText = sqlite3_column_text(statement, 1) {
                    text = String(cString: cText)
                }
                let date = sqlite3_column_int64(statement, 2)
                let strDate = formatDate(date: date)
                let is_from_me = sqlite3_column_int64(statement, 3)
                //let self_row = sqlite3_column_int64(statement, 4)
                currentPerson.append(Message(idx: Int64(idx), text: text, is_from_me: is_from_me, date: strDate))
                //print("guid: \(guid); text: \(text); date: \(date); is_from_me: \(is_from_me); self_row: \(self_row); idx: \(idx)")
                if sqlite3_prepare_v2(db, "insert into numbered_person values (?, ?, ?, ?, ?)", -1, &statement2, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("error inserting into numbered_person: \(errmsg)")
                }
                if sqlite3_bind_text(statement2, 1, guid, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding guid: \(errmsg)")
                }
                if sqlite3_bind_text(statement2, 2, text, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding text: \(errmsg)")
                }
                if sqlite3_bind_int64(statement2, 3, date) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding date: \(errmsg)")
                }
                if sqlite3_bind_int64(statement2, 4, is_from_me) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding is_from_me: \(errmsg)")
                }
                if sqlite3_bind_int64(statement2, 5, Int64(idx)) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding idx: \(errmsg)")
                }
                if sqlite3_step(statement2) != SQLITE_DONE {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure inserting into numbered_person: \(errmsg)")
                }
                if sqlite3_finalize(statement2) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("error finalizing prepared statement: \(errmsg)")
                }
                statement2 = nil
                idx += 1
            }
            if searchByContact {
                contactOrPhonePerson = Messages(messages: currentPerson, id: idForSearch)
            }
            people.append(Messages(messages: currentPerson, id: idForSearch))
            var sqlSearch = ""
            var numPersQuery = ""
                //print("HEYO THIS IS THE SEARCHOPTS" + String(searchOpts.titleOfSelectedItem))
            switch(searchOpts.titleOfSelectedItem) {
            case self.opts[0]:
                sqlSearch = "%" + search + "%"
                break
            case self.opts[1]:
                sqlSearch = search + "%"
                break
            case self.opts[2]:
                sqlSearch = "%" + search
                break
            case self.opts[3]:
                sqlSearch = search
                break
            default:
                break
            }
            if anyDate.state == .off {
                dateFormatter.timeStyle = DateFormatter.Style.none
                dateFormatter.dateFormat = "YYYY-MM-dd"
                fromDateStr = dateFormatter.string(from: fromDate.dateValue)
                //add one day to the end date to make it inclusive
                toDateStr = dateFormatter.string(from: toDate.dateValue.addingTimeInterval(60 * 60 * 24))
                let dateConversion = "datetime(date/1000000000 + 978307200, 'unixepoch', 'localtime')"
                //print("THE DATE IS \(dateConversion)")
                if !search.isEmpty {
                    numPersQuery = "select idx, text, date from numbered_person where text like ? and \(dateConversion) > \"\(fromDateStr)\" and \(dateConversion) < \"\(toDateStr)\" order by date"
                }
                else {
                    numPersQuery = "select idx, text, date from numbered_person where \(dateConversion) > \"\(fromDateStr)\" and \(dateConversion) < \"\(toDateStr)\" order by date limit 1"
                }
                //reset to selected date and reformat for display message purposes
                dateFormatter.dateFormat = "MM/dd/YYYY"
                fromDateStr = dateFormatter.string(from: fromDate.dateValue)
                toDateStr = dateFormatter.string(from: toDate.dateValue)
            }
            else {
                numPersQuery = "select idx, text, date from numbered_person where text like ? order by date"
            }
            if sqlite3_prepare_v2(db, numPersQuery, -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error selecting from numbered_person: \(errmsg)")
            }
            if !(anyDate.state == .off && search.isEmpty){
                if sqlite3_bind_text(statement, 1, sqlSearch, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    print("failure binding sqlSearch: \(errmsg)")
                }
            }
            if handleIdx == 0 { //only reset results if we're on the first handle
                self.results = [MessageIDPair]()
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                let self_row = sqlite3_column_int64(statement, 0) //the idx of numbered_person
                var text = ""
                if let cText = sqlite3_column_text(statement, 1) {
                    text = String(cString: cText)
                }
                let date = formatDate(date: sqlite3_column_int64(statement, 2))
                self.results.append(MessageIDPair(message: Message(idx: self_row, text: text, date: date), id: idForSearch))
                resultsIdx += 1
            }
        }
        print("everything up to here worked")
        //close database connection
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }
        db = nil
        self.results.sort {
            dateFormatter.dateFormat = "MM/dd/yy, h:mm:ss a"
            let date0 = dateFormatter.date(from: $0.message.date)!
            let date1 = dateFormatter.date(from: $1.message.date)!
            return date0 < date1
        }
        return resultsIdx
    }
    //var store: CNContactStore!
    @IBAction func sayButtonClicked(_ sender: Any) {
        var id = contactID.stringValue
        let search = searchText.stringValue
        searchByContact = searchBy.titleOfSelectedItem == "Contact"// && searchAll.state == .off
        if !self.fullPath.isEmpty {
            print(self.fullPath)
            if !id.isEmpty || searchByContact {
                if isPhoneNumber(num: id) {
                    id = formatPhoneNumber(num: id, hasCountryCode: false)
                }
                let numMatches = searchDB(phone: id, search: search)
                if numMatches == -1 {
                    searchMessage.stringValue = "You must enter some search parameter"
                }
                else {
                    var dateMessage = ""
                    if anyDate.state == .off {
                        if fromDateStr == toDateStr {
                            dateMessage = "on \(fromDateStr) "
                        }
                        else {
                            dateMessage = "between \(fromDateStr) and \(toDateStr) "
                        }
                    }
                    if searchByContact {
                        id = contactName.titleOfSelectedItem!
                    }
                    if searchAllHandles {
                        id = "all messages"
                    }
                    var searchDescription = "messages"
                    if !search.isEmpty {
                        searchDescription = "\(searchOpts.title): \"\(search)\""
                    }
                    searchMessage.stringValue = "Search for \(searchDescription) in conversation with \(id) \(dateMessage)completed, returned \(numMatches) results"
                }
                resultsTab?.results = self.results
                resultsTab?.people = self.people
                resultsTab?.searchAllHandles = self.searchAllHandles
                resultsTab?.handleIDDict = self.handleIDDict
                resultsTab?.handleIDs = self.handleIDs
                resultsTab?.searchByContact = self.searchByContact
                if searchByContact {
                    resultsTab?.currentPerson = contactOrPhonePerson
                }
            }
        }
        else {
            print("terrible, no path")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        searchOpts.removeAllItems()
        for opt in self.opts {
            searchOpts.addItem(withTitle: opt)
        }
        countries.removeAllItems()
        countries.addItems(withTitles: countryToCode)
        contactName.removeAllItems()
        for contact in self.contacts {
            if !(contact.givenName.isEmpty && contact.familyName.isEmpty) {
                let fullName = contact.givenName + " " + contact.familyName
                contactName.addItem(withTitle: fullName)
                contactsDict[fullName] = contact
            }
        }
    }
    
    var countryToCode = [
        "United States +1",
        "Abkhazia +7840",
        "Abkhazia +7940",
        "Afghanistan +93",
        "Albania +355",
        "Algeria +213",
        "American Samoa +1684",
        "Andorra +376",
        "Angola +244",
        "Anguilla +1264",
        "Antigua and Barbuda +1268",
        "Argentina +54",
        "Armenia +374",
        "Aruba +297",
        "Ascension +247",
        "Australia +61",
        "Australian External Territories +672",
        "Austria +43",
        "Azerbaijan +994",
        "Bahamas +1242",
        "Bahrain +973",
        "Bangladesh +880",
        "Barbados +1246",
        "Barbuda +1268",
        "Belarus +375",
        "Belgium +32",
        "Belize +501",
        "Benin +229",
        "Bermuda +1441",
        "Bhutan +975",
        "Bolivia +591",
        "Bosnia and Herzegovina +387",
        "Botswana +267",
        "Brazil +55",
        "British Indian Ocean Territory +246",
        "British Virgin Islands +1284",
        "Brunei +673",
        "Bulgaria +359",
        "Burkina Faso +226",
        "Burundi +257",
        "Cambodia +855",
        "Cameroon +237",
        "Canada +1",
        "CapeVerde +238",
        "Cayman Islands +345",
        "Central African Republic +236",
        "Chad +235",
        "Chile +56",
        "China +86",
        "Christmas Island +61",
        "Cocos-Keeling Islands +61",
        "Colombia +57",
        "Comoros +269",
        "Congo +242",
        "Congo, Dem. Rep. of (Zaire) +243",
        "Cook Islands +682",
        "Costa Rica +506",
        "Ivory Coast +225",
        "Croatia +385",
        "Cuba +53",
        "Curacao +599",
        "Cyprus +537",
        "Czech Republic +420",
        "Denmark +45",
        "Diego Garcia +246",
        "Djibouti +253",
        "Dominica +1767",
        "Dominican Republic +1809",
        "Dominican Republic +1829",
        "Dominican Republic +1849",
        "EastTimor +670",
        "EasterIsland +56",
        "Ecuador +593",
        "Egypt +20",
        "El Salvador +503",
        "Equatorial Guinea +240",
        "Eritrea +291",
        "Estonia +372",
        "Ethiopia +251",
        "FalklandI slands +500",
        "Faroe Islands +298",
        "Fiji +679",
        "Finland +358",
        "France +33",
        "French Antilles +596",
        "French Guiana +594",
        "French Polynesia +689",
        "Gabon +241",
        "Gambia +220",
        "Georgia +995",
        "Germany +49",
        "Ghana +233",
        "Gibraltar +350",
        "Greece +30",
        "Greenland +299",
        "Grenada +1473",
        "Guadeloupe +590",
        "Guam +1671",
        "Guatemala +502",
        "Guinea +224",
        "Guinea-Bissau +245",
        "Guyana +595",
        "Haiti +509",
        "Honduras +504",
        "Hong Kong SAR China +852",
        "Hungary +36",
        "Iceland +354",
        "India +91",
        "Indonesia +62",
        "Iran +98",
        "Iraq +964",
        "Ireland +353",
        "Israel +972",
        "Italy +39",
        "Jamaica +1876",
        "Japan +81",
        "Jordan +962",
        "Kazakhstan +77",
        "Kenya +254",
        "Kiribati +686",
        "North Korea +850",
        "South Korea +82",
        "Kuwait +965",
        "Kyrgyzstan +996",
        "Laos +856",
        "Latvia +371",
        "Lebanon +961",
        "Lesotho +266",
        "Liberia +231",
        "Libya +218",
        "Liechtenstein +423",
        "Lithuania +370",
        "Luxembourg +352",
        "MacauSARChina +853",
        "Macedonia +389",
        "Madagascar +261",
        "Malawi +265",
        "Malaysia +60",
        "Maldives +960",
        "Mali +223",
        "Malta +356",
        "MarshallIslands +692",
        "Martinique +596",
        "Mauritania +222",
        "Mauritius +230",
        "Mayotte +262",
        "Mexico +52",
        "Micronesia +691",
        "MidwayIsland +1808",
        "Moldova +373",
        "Monaco +377",
        "Mongolia +976",
        "Montenegro +382",
        "Montserrat +1664",
        "Morocco +212",
        "Myanmar +95",
        "Namibia +264",
        "Nauru +674",
        "Nepal +977",
        "Netherlands +31",
        "Netherlands Antilles +599",
        "Nevis +1869",
        "New Caledonia +687",
        "New Zealand +64",
        "Nicaragua +505",
        "Niger +227",
        "Nigeria +234",
        "Niue +683",
        "Norfolk Island +672",
        "Northern Mariana Islands +1670",
        "Norway +47",
        "Oman +968",
        "Pakistan +92",
        "Palau +680",
        "Palestinian Territory +970",
        "Panama +507",
        "Papua New Guinea +675",
        "Paraguay +595",
        "Peru +51",
        "Philippines +63",
        "Poland +48",
        "Portugal +351",
        "Puerto Rico +1787",
        "Puerto Rico +1939",
        "Qatar +974",
        "Reunion +262",
        "Romania +40",
        "Russia +7",
        "Rwanda +250",
        "Samoa +685",
        "San Marino +378",
        "Saudi Arabia +966",
        "Senegal +221",
        "Serbia +381",
        "Seychelles +248",
        "Sierra Leone +232",
        "Singapore +65",
        "Slovakia +421",
        "Slovenia +386",
        "Solomon Islands +677",
        "South Africa +27",
        "South Georgia and the South Sandwich Islands +500",
        "Spain +34",
        "Sri Lanka +94",
        "Sudan +249",
        "Suriname +597",
        "Swaziland +268",
        "Sweden +46",
        "Switzerland +41",
        "Syria +963",
        "Taiwan +886",
        "Tajikistan +992",
        "Tanzania +255",
        "Thailand +66",
        "TimorLeste +670",
        "Togo +228",
        "Tokelau +690",
        "Tonga +676",
        "Trinidad and Tobago +1868",
        "Tunisia +216",
        "Turkey +90",
        "Turkmenistan +993",
        "Turks and Caicos Islands +1649",
        "Tuvalu +688",
        "Uganda +256",
        "Ukraine +380",
        "United Arab Emirates +971",
        "United Kingdom +44",
        "Uruguay +598",
        "U.S. Virgin Islands +1340",
        "Uzbekistan +998",
        "Vanuatu +678",
        "Venezuela +58",
        "Vietnam +84",
        "Wake Island +1808",
        "Wallis and Futuna +681",
        "Yemen +967",
        "Zambia +260",
        "Zanzibar +255",
        "Zimbabwe +263"
    ];
    
}
