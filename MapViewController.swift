//
//  MapViewController.swift
//  VirtualTouristV.1
//
//  Created by salma on 25/12/1441 AH.
//  Copyright © 1441 salma. All rights reserved.
//


import UIKit
import MapKit
import CoreData
import CoreLocation
class MapViewController: UIViewController ,NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate,MKMapViewDelegate{
    

    @IBOutlet weak var mapView: MKMapView!
    
    
    var datacontroller: DataController!
    var pins : [Pin]!
    var passPin: Pin?
    var fetchResultViewController: NSFetchedResultsController<Pin>!
    var locationManger = CLLocationManager.init()
   

    
  override func viewDidLoad() {
        super.viewDidLoad()
        
       setupFrtchResult()
       setupFetchPin()
        mapView.delegate = self
        
    }
    
    
    func setupFrtchResult(){
        
        let fetchresult: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchresult.sortDescriptors = [sortDescriptor]
        fetchResultViewController = NSFetchedResultsController(fetchRequest: fetchresult, managedObjectContext: datacontroller.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultViewController.delegate = self
        do{
            try fetchResultViewController.performFetch()
            
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {return}
        let location: CGPoint = sender.location(in: self.mapView)
        let locationCoordinate: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        addAnnotationOnLocation(pointedCoordinate: locationCoordinate)
        
        let pin = Pin(context: datacontroller.viewContext)
        pin.latitude = locationCoordinate.latitude
        pin.longitude = locationCoordinate.longitude
        print("Save: ", pin)
        pins.append(pin)
        passPin = pin
        try? datacontroller.viewContext.save()

    }
    
    
    func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = pointedCoordinate
        mapView.addAnnotation(annotation)
        
    }
    
    
   func setupFetchPin(){
        pins = datacontroller.fetchPins(viewContext: datacontroller.viewContext)
        for pin in pins{
            
            let addPin = MKPointAnnotation()
            addPin.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            
            
                       mapView.addAnnotation(addPin)
                       pins.append(pin)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if let vc = segue.destination as? PhotoCollection{
            vc.pin = self.passPin!
            print("Passed")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else
        {
            return
        }
        
        let menu = UIAlertController(title: " Click one ", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete pin", style: .default){(action) in
            let deletePin = self.pins.first(where: {$0.latitude == view.annotation?.coordinate.latitude &&
                $0.longitude == view.annotation?.coordinate.longitude
            })
            self.mapView.removeAnnotation(annotation)
            self.datacontroller.viewContext.delete(deletePin!)
            try? self.datacontroller.viewContext.save()
        }
        let editAction = UIAlertAction(title: "view photos", style: .default) { (action) in
//                  Go to Album
            if self.pins.isEmpty{
                self.performSegue(withIdentifier: "photoCollection", sender: self)
                return
            }
            self.passPin = self.pins.first(where: {$0.latitude == view.annotation?.coordinate.latitude &&
                $0.longitude == view.annotation?.coordinate.longitude})
            self.performSegue(withIdentifier: "photoCollection", sender: self)
    }
        
        let backAction = UIAlertAction(title: "Back", style: .cancel)
        menu.addAction(editAction)
        menu.addAction(deleteAction)
        menu.addAction(backAction)
        self.present(menu, animated: true, completion: nil)
        
        mapView.deselectAnnotation(annotation, animated: true)
        print("\(#function) lat \(annotation.coordinate.latitude) lon \(annotation.coordinate.longitude)")
    
    }
    
    
    
    
    
    
    
}
    
 
