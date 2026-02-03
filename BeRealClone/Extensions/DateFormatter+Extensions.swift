//
//  DateFormatter+Extensions.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/3/22.
//

import Foundation

extension DateFormatter {
    static var beRealPostFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
