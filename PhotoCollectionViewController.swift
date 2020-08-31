//
//  PhotoCollectionViewController.swift
//  VirtualTouristV.1
//
//  Created by salma on 25/12/1441 AH.
//  Copyright © 1441 salma. All rights reserved.
//

import Foundation
import UIKit
 import CoreData
import MapKit
class PhotoCollection: UIViewController, MKMapViewDelegate ,UICollectionViewDelegate, UICollectionViewDataSource{
 
    
    
 
    
    @IBOutlet weak var mapvView: MKMapView!
    @IBOutlet weak var indcitorActivity: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var datacontroller: DataController!
    var pin: Pin!
    var fetchResultViewController: NSFetchedResultsController<Photo>!
    
    
    
    override func viewDidLoad() {
        setupMapView()
        setUP()
        getImage()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    
    fileprivate func setupMapView(){
        
        let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        let region = MKCoordinateRegion(center: location, span: span)
        mapvView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        mapvView.addAnnotation(annotation)
      
    }
    
    
    func setUP(){
        
        let fetchrequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "url", ascending: true)
        let pradicate = NSPredicate(format: "pin = %@", pin!)
        fetchrequest.predicate = pradicate
        fetchrequest.sortDescriptors = [sortDescriptor]
        datacontroller = (UIApplication.shared.delegate as! AppDelegate).dataController
        fetchResultViewController = NSFetchedResultsController(fetchRequest: fetchrequest, managedObjectContext: datacontroller.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultViewController.delegate = self
        do{
            try fetchResultViewController.performFetch()
        }catch{
            fatalError("The fetch could not performed: \(error.localizedDescription)")
        }
        print(" End fetch:", fetchResultViewController.fetchedObjects?.count)
    }
    
    func getImage(){
        
        guard (fetchResultViewController.fetchedObjects?.count) == 0 else{
            
            indcitorActivity.isHidden = true
            collectionView.reloadData()
            return
        }
        indcitorActivity.startAnimating()
        FlikerAPI.serachLatLon(latitude: pin.latitude, logtitude: pin.longitude, pin: pin){
            (error , done) in
            if done{
                DispatchQueue.main.async {
                    print("Done:",done)
                    self.indcitorActivity.stopAnimating()
                    self.indcitorActivity.isHidden = true
                }
            }
            else{
                DispatchQueue.main.async {
                    self.indcitorActivity.isHidden = true
                }
                let controller = UIAlertController()
                controller.title = "Error!"
                controller.message = "Failed load"
                let okPress = UIAlertAction(title: "OK", style: UIAlertAction.Style.default){action in self.dismiss(animated: true, completion: nil)}
                controller.addAction(okPress)
                self.present(controller, animated: true , completion: nil)
            }
        }
    }
    
    
    @IBAction func newCollection(_ sender: Any) {
        
        deleteAllData()
        self.indcitorActivity.isHidden = false
        self.indcitorActivity.startAnimating()
        FlikerAPI.serachLatLon(latitude: pin.latitude, logtitude: pin.longitude, pin: pin){
            
            (error,done) in
            if done{
                DispatchQueue.main.sync {
                    self.indcitorActivity.isHidden = true
                    self.indcitorActivity.stopAnimating()
                }
            } else {
                print("Erorr",error!)
            }
        }
        
        
    }
    
    func deleteAllData(){
        
        let fetchrequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchrequest.returnsObjectsAsFaults = false
        do{
            let result = try! datacontroller.viewContext.fetch(fetchrequest)
            for object in result{
                 guard let objectData = object as? NSManagedObject
                    else{
                        continue
                }
              datacontroller.viewContext.delete(objectData)
            }
             print("We delete all object in image")
        } catch{
             print("Detele all data in entity error :")
        }
        
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(fetchResultViewController.fetchedObjects?.count ?? 0)
        return self.fetchResultViewController.fetchedObjects?.count ?? 0
     }
     
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionPhotoCell", for: indexPath as IndexPath) as! CollectionCell
        let image = fetchResultViewController.object(at: indexPath)
        if let imageData = fetchResultViewController.object(at: indexPath).imageData{
            cell.imageView.image = UIImage(data: imageData)
        } else{
            cell.imageView.image = UIImage(named: "Image.png")
            FlikerAPI.downloadImage(imagePath: image.url!){
                (data, error) in
                if let dataImage = data{
                    DispatchQueue.main.sync {
                        cell.imageView.image = UIImage(data: dataImage)
                        image.imageData = dataImage
                        try? self.datacontroller.viewContext.save()
                    }
                }
            }
            
        }
        
        return cell
       }
     
      
  
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menu = UIAlertController(title: "Click One", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .default){
            (action)in
            let deleteImage = self.fetchResultViewController.object(at: indexPath)
            self.datacontroller.viewContext.delete(deleteImage)
            try? self.datacontroller.viewContext.save()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        menu.addAction(deleteAction)
        menu.addAction(cancelAction)
        self.present(menu,animated: true, completion: nil)
    }
    
 
    
    
    
}

extension PhotoCollection: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // TODO: finish updating the table view
        collectionView.reloadData()
        
    }


}


