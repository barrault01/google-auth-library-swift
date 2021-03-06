// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import OAuth2

let USE_SERVICE_ACCOUNT = false
let SERVICE_ACCOUNT_CREDENTIALS = ".credentials/service_account.json"

let CLIENT_CREDENTIALS = "google.json"
let TOKEN = "google.json"

fileprivate enum CommandLineOption {
    case login
    case me
    case people
    case data
    case translate(text: String)
    init?(arguments: [String]) {
        if arguments.count > 1 {
            let command = arguments[1]
            switch command {
            case "login": self = .login
            case "me": self = .me
            case "people": self = .people
            case "data": self = .data
            case "translate":
                if arguments.count < 2 { return nil }
                self = .translate(text: arguments[2])
            default: return nil
            }
        } else {
            return nil
        }
    }
    func stringValue() -> String {
        switch self {
        case .login: return "login"
        case .me: return "me"
        case .people: return "people"
        case .data: return "data"
        case .translate(_): return "translate"
        }
    }

    static func all() -> [String] {
        return [CommandLineOption.login,
                CommandLineOption.me,
                CommandLineOption.people,
                CommandLineOption.data,
                CommandLineOption.translate(text: "")].map({$0.stringValue()})
    }
}

func main() throws {

    let arguments = CommandLine.arguments
    guard  let option = CommandLineOption(arguments: arguments) else {
        print("Usage: \(arguments[0]) [options]")
        print("Options list: \(CommandLineOption.all())")
        return
    }

    let scopes = ["profile",
                  "https://www.googleapis.com/auth/contacts.readonly",
                  "https://www.googleapis.com/auth/cloud-platform"]

    var tokenProvider : TokenProvider
    #if os(OSX)
    tokenProvider = BrowserTokenProvider(credentials:CLIENT_CREDENTIALS, token:TOKEN)!
    #else
    tokenProvider = DefaultTokenProvider(scopes:scopes)!
    #endif

    if USE_SERVICE_ACCOUNT {
        if #available(OSX 10.12, *) {
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            let credentialsURL = homeURL.appendingPathComponent(SERVICE_ACCOUNT_CREDENTIALS)
            tokenProvider = ServiceAccountTokenProvider(credentialsURL:credentialsURL,
                                                        scopes:scopes)!
        } else {
            print("This sample requires OSX 10.12 or later.")
        }
    }

    let google = try GoogleSession(tokenProvider:tokenProvider)

    switch option {
    case .login:
        #if os(OSX)
        let browserTokenProvider = tokenProvider as! BrowserTokenProvider
        try browserTokenProvider.signIn(scopes:scopes)
        try browserTokenProvider.saveToken(TOKEN)
        #endif
    case .me:
        try google.getMe()
    case .people:
        try google.getPeople()
    case .data:
        try google.getData()
    case .translate(let text):
        try google.translate(text)
    }

}

do {
    try main()
} catch (let error) {
    print("ERROR: \(error)")
}


