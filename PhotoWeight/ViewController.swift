//
//  ViewController.swift
//  PhotoWeight
//
//  Created by Tim Bellay on 11/6/14.
//  Copyright (c) 2014 Mission Minds. All rights reserved.
//

import UIKit
import HealthKit
import GPUImage

class ViewController: UIViewController {
	
	@IBOutlet var cameraView: GPUImageView!
	var videoCamera:GPUImageVideoCamera?
	//var filter:GPUImagePixellateFilter?
	var filter:GPUImageLuminanceThresholdFilter?
	
	@IBOutlet weak var weightTextField: UITextField!
	@IBOutlet weak var enterWeightButton: UIButton!

	var healthStore: HKHealthStore?
	let date: NSDate = NSDate()
	let metadata = [ HKMetadataKeyWasUserEntered : true ]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		setupData()
		setupUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: UI Setup
	func setupUI() {
		videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
		videoCamera!.outputImageOrientation = .Portrait;
		
		filter = GPUImageLuminanceThresholdFilter()
		
		
		// Configure the filter chain, ending with the view
		if let view = self.cameraView {
				videoCamera?.addTarget((filter as GPUImageInput))
				filter?.addTarget(view)
				videoCamera?.startCameraCapture()
		}

		
		
	}

	func updateUI() {
		
	}
	
	// MARK: DATA Setup
	func setupData() {
		
		if !HKHealthStore.isHealthDataAvailable() {
// TODO: Handle the fact that HealthKit is not on iPad. TB
			println("Error: HealthKit is not availible on this device")
		} else {
			
			self.healthStore = HKHealthStore()
			requestAuthorisationForHealthStore()
		}
		
	}
	
	@IBAction func didPressUpdateWeightButton(sender: AnyObject) {
	
		var error: NSError?
		let dob = self.healthStore?.dateOfBirthWithError(&error)
		
		let weightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
		
		let weightNSSString = NSString(string: self.weightTextField.text)
		let weightValue = HKQuantity(unit: HKUnit(fromString: "lb"), doubleValue: weightNSSString.doubleValue)
		
		let sample = HKQuantitySample(type: weightType, quantity: weightValue,
			startDate: date, endDate: date, metadata: metadata)
		
		healthStore?.saveObject(sample, withCompletion: {(success, error) in
			if success {
				println("Weight saved successfully ")
				
			} else {
				println("Error: \(error)")
				
			}
		})
	}
	
	func updateData() {
		// first technical test: write to HealhKit
	}

	private func requestAuthorisationForHealthStore() {
		let dataTypesToWrite = [ HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) ]
		let dataTypesToRead = [
			HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
			//HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight),
			//HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex),
			HKCharacteristicType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)
		]
		
		self.healthStore?.requestAuthorizationToShareTypes(NSSet(array: dataTypesToWrite),
			readTypes: NSSet(array: dataTypesToRead), completion: { (success, error) in
				if success {
					println("User completed authorisation request.")
				} else {
					println("The user cancelled the authorisation request. \(error)")
				}
		})
	}
	
	
}

