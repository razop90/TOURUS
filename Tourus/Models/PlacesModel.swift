//
//  PlacesModel.swift
//  Tourus
//
//  Created by admin on 02/03/2019.
//  Copyright © 2019 Tourus. All rights reserved.
//

import Foundation
import GooglePlaces

class PlacesModel {
    var placesClient: GMSPlacesClient! = GMSPlacesClient.shared()
    var currPlace : Place? = nil
    let apiWebKey = "AIzaSyChHqn4cqme0MTgu6QRmaJHppcGs_NbeIc"
    let maxW = 200
    
    init() {

    }
    
    func fetchGoogleNearbyPlaces(location: CLLocation, radius: Int!, type:String? = nil, isOpen:Bool?=true, callback: @escaping ([Place]?, String?, String?) -> Void) {
        let latitude:String = String(format: "%f", location.coordinate.latitude)
        let longitude:String = String(format:"%f", location.coordinate.longitude)
        let loc:String = latitude + "," + longitude
        
        var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        urlString+="location="+loc
        urlString+="&radius="+String(radius)
        //urlString+="&fields=photos" //,formatted_address,name,rating,opening_hours"
        urlString+="&language=en"
        
        if isOpen! {
            urlString+="&opennow"
        }
        if let strType = type {
            urlString+="&type=\(strType)"
        }
        urlString+="&key="+apiWebKey
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {(data, response, error) in
                do {
                    if (error != nil) {
                        callback(nil, nil, error?.localizedDescription)
                        return
                    }
                    let googlePlacesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data!)
                    let status = googlePlacesResponse.status;
                    if status == "NOT_FOUND" || status == "REQUEST_DENIED" {
                        //callback(nil,status)
                        return
                    }
                    callback(googlePlacesResponse.results.map({ (place) -> Place in
                        return Place(googlePlace : place)}), googlePlacesResponse.next_page_token ,nil)
                } catch {
                    callback(nil, nil, error.localizedDescription)
                }
                }.resume()
        } else {
            print("could not open url, equals to nil")
            callback(nil, nil, "could not open url, equals to nil")
        }
    }
    
    func fetchMoreGoogleNearbyPlaces(nextPgeToken:String, callback: @escaping ([Place]?, String?, String?) -> Void) {
        var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        urlString+="pagetoken="+nextPgeToken
        urlString+="&key="+apiWebKey
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {(data, response, error) in
                do {
                    if (error != nil) {
                        callback(nil, nil, error?.localizedDescription)
                        return
                    }
                    let googlePlacesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data!)
                    let status = googlePlacesResponse.status;
                    if status == "NOT_FOUND" || status == "REQUEST_DENIED" {
                        //callback(nil,status)
                        return
                    }
                    callback(googlePlacesResponse.results.map({ (place) -> Place in
                        return Place(googlePlace : place)}), googlePlacesResponse.next_page_token, nil)
                } catch {
                    callback(nil, nil, error.localizedDescription)
                }
                }.resume()
        } else {
            print("could not open url, equals to nil")
            callback(nil, nil, "could not open url, equals to nil")
        }
    }
    
    func fetchGoogleNearbyPlacesPhoto(_ placeID :String, _ reference:String, _ maxwidth:Int, _ alpha:CGFloat, _ callback: @escaping (UIImage?, String) -> Void) {

        // Method 3
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxwidth)&photoreference=\(reference)&key=\(apiWebKey)"
        let url = URL(string: urlString)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        URLSession.shared.downloadTask(with: url!) { url, response, error in
            var downloadedPhoto: UIImage? = nil
            defer {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
            guard let url = url else {
                return
            }
            guard let imageData = try? Data(contentsOf: url) else {
                return
            }
            
            downloadedPhoto = UIImage(data: imageData)
            if(downloadedPhoto != nil) {
                downloadedPhoto = downloadedPhoto!.alpha(alpha)
            }
            callback(downloadedPhoto, placeID)
        }.resume()
    }
    
    func GetCurrentPlace(callback: @escaping (Place)-> Void) {
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }

            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    callback(Place(googlePlace: place))
                }
            }
        })
    }
    
    func navigate(_ latitude:String, _ longitude:String) {
        var navigationPath = consts.googleMaps.browserLink //initialize with the browser link

        if let UrlNavigation = URL.init(string: consts.googleMaps.applicationLink) {
            if UIApplication.shared.canOpenURL(UrlNavigation) {
                navigationPath = consts.googleMaps.applicationLink //google maps app link
            }
        }
        
        if let urlDestination = URL.init(string: navigationPath + "?saddr=&daddr=\(latitude),\(longitude)&&directionsmode=walking&zoom=17") {
            UIApplication.shared.open(urlDestination, options: [:], completionHandler: nil)
        }
    }
    
    func GetPlacePhotos(placeID:String, callback: @escaping ([Photo]?, String, String?)-> Void){
        var urlString = "https://maps.googleapis.com/maps/api/place/details/json?"
        urlString+="placeid="+placeID
        urlString+="&fields=photo"
        //urlString+="&fields=photos" //,formatted_address,name,rating,opening_hours"
        
        urlString+="&key="+apiWebKey
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {(data, response, error) in
                do {
                    if (error != nil) {
                        callback(nil, placeID, error?.localizedDescription)
                        return
                    }
                    let googlePlacePhotosResponse = try JSONDecoder().decode(GooglePlacePhotosResponse.self, from: data!)
                    let status = googlePlacePhotosResponse.status;
                    if status == "NOT_FOUND" || status == "REQUEST_DENIED" {
                        //callback(nil,status)
                        return
                    }
                    callback(googlePlacePhotosResponse.result.photos, placeID, nil)
                } catch {
                    callback(nil ,placeID ,error.localizedDescription)
                }
                }.resume()
        } else {
            print("could not open url, equals to nil")
            callback(nil ,placeID ,"could not open url, equals to nil")
        }
    }
}
