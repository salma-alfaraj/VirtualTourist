//
//  FlickerAPI.swift
//  VirtualTouristV.1
//
//  Created by salma on 25/12/1441 AH.
//  Copyright © 1441 salma. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class FlikerAPI{
    
    
    static func serachLatLon(latitude: Double? , logtitude: Double?, pin: Pin?, onComplete:@escaping(_ error: String? , _ exit:Bool)-> Void){
        
        
        
        var boxString = "0,0,0,0"
               
               // get lat,lang
               if let latitude = latitude, let longitude = logtitude {
                   let minimumLon = max(longitude - API.Flickr.SearchBBoxHalfWidth, API.Flickr.SearchLonRange.0)
                   let minimumLat = max(latitude - API.Flickr.SearchBBoxHalfHeight, API.Flickr.SearchLatRange.0)
                   let maximumLon = min(longitude + API.Flickr.SearchBBoxHalfWidth, API.Flickr.SearchLonRange.1)
                   let maximumLat = min(latitude + API.Flickr.SearchBBoxHalfHeight, API.Flickr.SearchLatRange.1)
                   boxString = "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
               }
        
        
        let ParameterMethod = [
                   API.FlickrParameterKeys.Method: API.FlickrParameterValues.SearchMethod,
                   API.FlickrParameterKeys.APIKey: API.FlickrParameterValues.APIKey,
                   API.FlickrParameterKeys.BoundingBox: boxString,
                   API.FlickrParameterKeys.SafeSearch: API.FlickrParameterValues.UseSafeSearch,
                   API.FlickrParameterKeys.Extras: API.FlickrParameterValues.MediumURL,
                   API.FlickrParameterKeys.Format: API.FlickrParameterValues.ResponseFormat,
                   API.FlickrParameterKeys.NoJSONCallback: API.FlickrParameterValues.DisableJSONCallback,
                   API.FlickrParameterKeys.PerPage: "20",
                   ]
        
        
        
        // create URL
        var components = URLComponents()
        components.scheme = API.Flickr.APIScheme
        components.host = API.Flickr.APIHost
        components.path = API.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in ParameterMethod {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        // create session and request
               let session = URLSession.shared
               let request = URLRequest(url: components.url!)
               // create network request
               let task = session.dataTask(with: request) { (data, response, error) in
                   guard (error == nil) else {
                       onComplete(error.debugDescription, false)
                       return
                }
              
    
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                onComplete(error.debugDescription, false)
                  return }
                
                
                guard let data = data else {
                onComplete(error.debugDescription, false)
                 return
               }
        
        
             let parsedResult: Fliker!
                do {
                  parsedResult = try JSONDecoder().decode(Fliker.self, from: data)
                     } catch {
                           onComplete("Error when parse data", false)
                          return
                          
                           }
                guard let photosDictionary = parsedResult.photos else {return}
                           guard let totalPages = photosDictionary.pages else {
                               return
                           }
                
                print("We have pages = ", totalPages)
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                print("We use page number = ", randomPage)
                self.displayImageFromFlickrBySearch(ParameterMethod as [String : AnyObject], withPageNumber: randomPage, pin: pin, onComplete: { (error, done) in
                    if done {
                        onComplete(nil, true)
                    }
                    else {
                        onComplete(error, false)
                    }
                })
        
        }
        task.resume()

    }
    
    
    
    
   private static func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = API.Flickr.APIScheme
        components.host = API.Flickr.APIHost
        components.path = API.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
  private static func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int, pin:Pin?,onComplete: @escaping (_ error: String?, _ done: Bool)
           -> Void) {
           
        var dataController = (UIApplication.shared.delegate as! AppDelegate).dataController

           // add the page to the method's parameters
           var methodParametersWithPageNumber = methodParameters
           methodParametersWithPageNumber[API.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
           
           // create session and request
           let session = URLSession.shared
           let request = URLRequest(url: flickrURLFromParameters(methodParametersWithPageNumber))
           
           
           // create network request
           let task = session.dataTask(with: request) { (data, response, error) in
               
               // if an error occurs, print it and re-enable the UI
               func displayError(_ error: String) {
                   print(error)
                   
               }
               
               /* GUARD: Was there an error? */
               guard (error == nil) else {
                   onComplete("error: \(error)", false)
                   return
               }
            

            guard let satutCode = ( response as? HTTPURLResponse)?.statusCode,
                satutCode >= 200 && satutCode <= 300 else{
                    onComplete("statusCode is file", false)
                    return
            }
            let presedresult: [String:AnyObject]!
            do{
                presedresult = try?
                    JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
            }catch{
                onComplete("Error!", false)
                return
            }
            
            guard let stat = presedresult[API.FlickrResponseKeys.Status] as?
                String, stat == API.FlickrResponseValues.OKStatus else{
                    onComplete("Flickr API returned an error. \(String(describing: presedresult))", false)
                    return
            }
            guard let photoDictionary = presedresult[API.FlickrResponseKeys.Photos] as? [String:AnyObject]
                else{
                    onComplete("can't Find the key '\(API.FlickrResponseKeys.Photo)' in \(presedresult)",false)
                    return
            }
//
            guard let photoArrary = photoDictionary[API.FlickrResponseKeys.Photo] as? [[String:AnyObject]]
                else{
                    onComplete("can't find key '\(API.FlickrResponseKeys.Photo)'in \(photoDictionary)", false)
                    return
            }
            if photoArrary.count == 0 {
                onComplete(" Photos not found",false)
                return
            }else{
                
                let photoIndex =
                    Int(arc4random_uniform(UInt32(photoArrary.count)))
                let photoDecitory = photoArrary[photoIndex] as [String:AnyObject]
                for photoo in photoArrary{
                    guard let urlImageSreing = photoo[API.FlickrResponseKeys.MediumURL] as? String
                        else{
                            displayError("can't Find key '\(API.FlickrResponseKeys.MediumURL)' in \(photoDecitory)")
                            return
                    }
                    
                                       
                

            let img = Photo(context: dataController.viewContext)
                    img.url = urlImageSreing
                    img.pin = pin
            }
                onComplete(nil , true)
                try? dataController.viewContext.save()
            }

      }
        task.resume()
    }
 
    static func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        
        task.resume()
    
    }
    
    static func loadImage(photo: Photo, onComplete: @escaping (_ error: String?, _ done: Bool, _ data: NSData?)
        -> Void)
    {
        guard (photo.url != nil) else {
            return
        }
        
        do {
            let imgData = try NSData(contentsOf: URL.init(string: photo.url!)!, options: NSData.ReadingOptions())
            onComplete(nil, true, imgData)
        } catch {
            
        }
        
    }

    
    
    
    
    
}
