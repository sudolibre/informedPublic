//
//  ViewController.swift
//  glassHouses
//
//  Created by Jonathon Day on 2/7/17.
//  Copyright © 2017 dayj. All rights reserved.
//

import UIKit
import MapKit

class OnboardingViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    @IBOutlet var viewsToRoundCorners: [UIView]!
    @IBOutlet var primaryTitle: UILabel!
    @IBOutlet var welcomeX: NSLayoutConstraint!
    @IBOutlet var identifyX: NSLayoutConstraint!
    @IBOutlet var overviewX: NSLayoutConstraint!
    var centerXConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var horizontalSpacingConstraints: [NSLayoutConstraint]!

    let titles = ["Welcome to Informed Public!", "Let's find your district.", "Meet your legislators!"]
    var currentLegislator: Legislator?
    var legislators: [Legislator]? {
        didSet {
            switch legislators {
            case .some:
                currentLegislator = legislators!.first!
                fetchPhotos()
                updateRepView()
            case .none:
                self.nextButton.isEnabled = false
            }
        }
    }
    
    func fetchPhotos() {
        for legislator in legislators! {
            if imageStore.getImage(forKey: legislator.photoKey) == nil {
                imageStore.fetchRemoteImage(forURL: legislator.photoURL, completion: { (image) in
                    self.imageStore.setImage(image, forKey: legislator.photoKey)
                    self.updateRepView()
                })
            }
        }
    }
    
    @IBAction func doneTapped(_ sender: UIButton) {
        rotateOnboardingCards(.forward)
    }
    
    enum Direction {
        case backward, forward
    }
    
    func rotateOnboardingCards(_ direction: Direction) {
        let constraintPairs: [(NSLayoutConstraint, NSLayoutConstraint)] = {
            let offsetConstraints = Array(centerXConstraints.dropFirst())

            switch direction {
            case .forward:
                return zip(centerXConstraints, offsetConstraints).reversed()
            case .backward:
                return Array(zip(centerXConstraints, offsetConstraints))
            }
        }()
        
        for (firstConstraint, secondConstraint ) in constraintPairs {
            swap(&firstConstraint.priority, &secondConstraint.priority)
        }
        
        let currentCardIndex = centerXConstraints.index(where: {$0.priority == 999})!
        pageControl.currentPage = currentCardIndex
        primaryTitle.text! = titles[currentCardIndex]
        
        UIView.animate(withDuration: 0.5) {
            self.view.setNeedsLayout()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centerXConstraints = [welcomeX, identifyX, overviewX]
        
        for i in horizontalSpacingConstraints {
            let windowWidth = UIScreen.main.bounds.width
            i.constant = windowWidth
        }
        
        for i in viewsToRoundCorners {
            i.layer.cornerRadius = i.frame.size.width / 8
        }
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navVC = segue.destination as! UINavigationController
        let activityVC = navVC.topViewController as! ActivityFeedController
        activityVC.legislators = self.legislators
        let dataSource: ActivityFeedDataSource = {
            let ds = ActivityFeedDataSource()
            ds.imageStore = imageStore
            return ds
        }()
        activityVC.dataSource = dataSource
    }
    


    
    //MARK: Welcome Card
    // there are no custom properties or methods for the welcome card
    
    //MARK: Identify Card
    
    let locationManager = CLLocationManager()
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var addressTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    @IBAction func nextTapped(_ sender: UIButton) {
        rotateOnboardingCards(.forward)
    }
    @IBAction func locationTapped(_ sender: UIButton) {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            let ac = UIAlertController(title: "Location Disabled", message: "The app is not currently allowed access to your locaiton. Please enable this in Settings to continue", preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            ac.addAction(settingsAction)
            ac.addAction(cancelAction)
            present(ac, animated: true)
        case .restricted:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.last!.coordinate
        updateMap(coordinates: coordinates)
        setLegislatorsWithCoordinates(coordinates)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = textField.text
        
        let search = MKLocalSearch(request: request)
        search.start { (_response, _error) in
            guard let response = _response else {
                if let error = _error {
                    print(error)
                }
                return
            }
            
            let firstResult = response.mapItems.first!
            print(firstResult.placemark.debugDescription)
            let coordinates = firstResult.placemark.location!.coordinate
            self.updateMap(coordinates: coordinates)
            self.setLegislatorsWithCoordinates(coordinates)
        }
        textField.resignFirstResponder()
        return true
    }
    
    func updateMap(coordinates: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinates, span: span)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        self.mapView.addAnnotation(annotation)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func setLegislatorsWithCoordinates(_ coordinates: CLLocationCoordinate2D) {
        OpenStatesAPI.request(.findDistrict(lat: coordinates.latitude, long: coordinates.longitude)) { (response) in
            switch response {
            case .success(let data):
                let legislators = OpenStatesAPI.parseDistrictResults(data)
                self.legislators = legislators
                UserDefaultsManager.setLegislatorIDs(legislators.map({$0.ID}))
            case .networkError(let response):
                let ac = UIAlertController(title: "Search Failed", message: "There seems to have been an error contacting the server. Code: \(response.statusCode)", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                ac.addAction(dismissAction)
                self.present(ac, animated: true)
            case .failure(let error):
                let ac = UIAlertController(title: "Search Failed", message: "There seems to have been a system error. Error: \(error.localizedDescription)", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                ac.addAction(dismissAction)
                self.present(ac, animated: true)
            }
        }
    }


    //MARK: Overview Card
    let imageStore = ImageStore()
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var legislatorNumber: UILabel!

    
    @IBAction func swipeDetected(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.left:
            rotateRep(.forward)
        case UISwipeGestureRecognizerDirection.right:
            rotateRep(.backward)
        default:
            fatalError("Unexpected swipe gesture recognizer direction")
        }
        
    }
    
    func updateRepView() {
        DispatchQueue.main.async {
            self.nextButton.isEnabled = true
            let currentPosition = self.legislators!.index(where: {$0 === self.currentLegislator!})! + 1
            self.legislatorNumber.text = "\(currentPosition) of \(self.legislators!.count)"
            self.subtitleLabel.text = "\(self.currentLegislator!.party.description) - \(self.currentLegislator!.title) - District \(self.currentLegislator!.district)"
            self.nameLabel.text = self.currentLegislator!.fullName
            if let image = self.imageStore.getImage(forKey: self.currentLegislator!.photoKey) {
                self.avatarImageView.image = image
            }
        }
    }
    

    
    func rotateRep(_ direction: Direction) {
        
        let currentIndex = legislators!.index(where: {$0 === currentLegislator!})
        let newIndex: Int!
        
        switch direction {
        case .forward:
            if currentIndex == legislators!.endIndex - 1 {
                newIndex = 0
            } else {
            newIndex = currentIndex! + 1
            }
        case .backward:
            if currentIndex == legislators!.startIndex {
                newIndex = legislators!.endIndex - 1
            } else {
                newIndex = currentIndex! - 1
            }
        }
        
        currentLegislator = legislators![newIndex]
        updateRepView()
    }

}
