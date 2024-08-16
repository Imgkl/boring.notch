//
//  SensorError.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 16/08/24.
//

import Foundation

enum SensorError: Error {
    enum Display: Error {
        case notFound
        case notSilicon
        case notStandard
    }
    enum Keyboard: Error {
        case notFound
        case notSilicon
        case notStandard
    }
}
