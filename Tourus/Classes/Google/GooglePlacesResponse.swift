//
//  GooglePlacesResponse.swift
//  Tourus
//
//  Created by admin on 30/03/2019.
//  Copyright © 2019 Tourus. All rights reserved.
//

import Foundation

class GooglePlacesResponse : Decodable {
    let next_page_token: String?
    let status: String
    let results: [GooglePlace]
}

class GooglePlacePhotosResponse : Decodable {
    let status: String
    let result: GooglePlacePhotos
}
