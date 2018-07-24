//
//  CommandLineParser.swift
//  BuildTimeLogger
//
//  Created by Petar Mataic on 2018-07-17.
//  Copyright © 2018 Marcin Religa. All rights reserved.
//

import Foundation

protocol CommandLineOption {
    var short: String { get }
    var long: String { get }
    var description: String { get }
    var isSet: Bool { get }
    var argument: String? { get }
}

protocol FromStringConvertible {
    init?(string: String)
}

extension CommandLineOption {
    var isSet: Bool {
        return CommandLine.arguments.contains(short) || CommandLine.arguments.contains(long)
    }

    var argument: String? {
        if CommandLine.arguments.contains(short) {
            return short
        } else if CommandLine.arguments.contains(long) {
            return long
        } else {
            return nil
        }
    }

    var helpDescription: String {
        return "\(short), \(long)    \(description)"
    }
}

struct Option: CommandLineOption {
    let short: String
    let long: String
    let description: String
}

struct Parameter<T: FromStringConvertible>: CommandLineOption {
    let short: String
    let long: String
    let description: String

    var value: T? {
        guard let optionIndex = CommandLine.arguments.index(of: short) ?? CommandLine.arguments.index(of: long) else {
            return nil
        }

        let nextArgumentIndex = optionIndex.advanced(by: 1)
        guard nextArgumentIndex < CommandLine.arguments.count else { return nil }

        return T(string: CommandLine.arguments[nextArgumentIndex])
    }
}

extension URL: FromStringConvertible { }
extension String: FromStringConvertible {
    init?(string: String) {
        self.init(string)
    }
}

extension CommandLine {
    static let allOptions: [CommandLineOption] = [helpOption, pushOption, fetchOption, usernameOption, verboseOption]

    static let pushOption = Parameter<URL>(short: "-p", long: "--push", description: "The remote to push the results to")
    static let fetchOption = Parameter<URL>(short: "-f", long: "--fetch", description: "Fetch remote build history")
    static let usernameOption = Option(short: "-u", long: "--username", description: "Includes username in build history")
    static let verboseOption = Option(short: "-v", long: "--verbose", description: "Print additional data during execution")
    static let helpOption = Option(short: "-h", long: "--help", description: "Prints help description")
}
