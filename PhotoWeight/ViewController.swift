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

class ViewController: UIViewController, TesseractDelegate {
	
	@IBOutlet var cameraView: GPUImageView!
	@IBOutlet weak var zoomSlider: UISlider!
	@IBOutlet weak var thresholdSlider: UISlider!
	@IBOutlet weak var capturePictureButton: UIButton!
	
	@IBOutlet weak var capturedPictureView: UIImageView!
	
	//var videoCamera: GPUImageVideoCamera?
	var videoCamera: GPUImageStillCamera?
	var dataForJPEGFile: NSData?
	var imageFromCamera: UIImage?
	
	var luminaceFilter: GPUImageLuminanceThresholdFilter?
	//var luminaceFilter: GPUImageAdaptiveThresholdFilter?
	
	var cropFilter: GPUImageCropFilter?
	var upsizeFilter: GPUImageLanczosResamplingFilter?
	
// TODO: Fix sliderMinValue to be 0.0 for all other filters. Lowerbound for zoom should be nonzero. TB
	let sliderMinValue: Float = 0.1
	let sliderMaxValue: Float = 1.0
	let sliderInitialValue: Float = 0.5
	//var sliderValue: Float?
	
	var currentFilterOperation: FilterOperationInterface?
		
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
	
	// MARK: Setup
	required init(coder aDecoder: NSCoder) {
		//videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
		videoCamera = GPUImageStillCamera()
		
		videoCamera!.outputImageOrientation = .Portrait;
		super.init(coder: aDecoder)
	}
	
	func setupUI() {
		setupSliders()
		setupCameraView()
	}
	
	func setupSliders() {
		zoomSlider.minimumValue = self.sliderMinValue
		zoomSlider.maximumValue = self.sliderMaxValue
		zoomSlider.value = self.sliderInitialValue

		thresholdSlider.minimumValue = self.sliderMinValue
		thresholdSlider.maximumValue = self.sliderMaxValue
		thresholdSlider.value = self.sliderInitialValue
		
//		thresholdSlider.minimumValue = 1.0
//		thresholdSlider.maximumValue = 20.0
//		thresholdSlider.value = 1.0
	}
	
	@IBAction func updateLuminanceThreshold(sender: UISlider) {
		luminaceFilter?.threshold = CGFloat(sender.value)
		//luminaceFilter?.blurRadiusInPixels = CGFloat(sender.value)
	}
	
	@IBAction func updateZoomValue(sender: UISlider) {
		let val = CGFloat(sender.value)
		cropFilter?.cropRegion = CGRectMake(0.5-val/2, 0.5-val/2, val, val)
	}
	
	func setupCameraView() {
		luminaceFilter = GPUImageLuminanceThresholdFilter()
		luminaceFilter?.threshold = CGFloat(sliderInitialValue)
		
		//luminaceFilter = GPUImageAdaptiveThresholdFilter()
		//luminaceFilter?.blurRadiusInPixels = 1.0
		
		let initialValue = CGFloat(sliderInitialValue)
		cropFilter = GPUImageCropFilter(cropRegion: CGRectMake(0.5-initialValue/2, 0.5-initialValue/2, initialValue, initialValue))
		
		upsizeFilter = GPUImageLanczosResamplingFilter()
		upsizeFilter?.forceProcessingAtSize(CGSizeMake(1280.0, 960.0))
		
		// Configure the filter chain, ending with the view
		if let view = self.cameraView {
			videoCamera?.addTarget(upsizeFilter?)
			upsizeFilter?.addTarget(cropFilter?)
			cropFilter?.addTarget(luminaceFilter?)
			luminaceFilter?.addTarget(view)
		}
		videoCamera?.startCameraCapture()
		cameraView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
		cameraView.layer.cornerRadius = 10.0
	}
	
	
	// MARK: DATA Setup
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
	
	
	func setupData() {
		
		if !HKHealthStore.isHealthDataAvailable() {
// TODO: Handle the fact that HealthKit is not on iPad. TB
			println("Error: HealthKit is not availible on this device")
		} else {
			
			self.healthStore = HKHealthStore()
			requestAuthorisationForHealthStore()
		}
		
	}
	
	@IBAction func didPressCaptureButton(sender: UIButton) {
		if sender.titleLabel?.text? == "CAPTURE" {
			
			videoCamera?.capturePhotoAsImageProcessedUpToFilter(luminaceFilter!, withCompletionHandler: { (processedImage: UIImage?, error: NSError?) -> Void in
			 	//self.dataForJPEGFile = UIImageJPEGRepresentation(processedImage, 0.8)
				//self.imageFromCamera = processedImage
				//self.capturedImageView.image = processedImage
				self.capturedPictureView.image = processedImage
				self.capturedPictureView.hidden = false
				}
			)
// TODO: Figure out why text on button does not change. TB
			sender.titleLabel!.text = "GO"
		} else {
			sender.titleLabel!.text = "CAPTURE"
		}
		updateData()
	}
	
	func updateData() {
		var tesseract:Tesseract = Tesseract();
//		tesseract.language = "eng+ita";
//		tesseract.delegate = self;
//		tesseract.setVariableValue("01234567890", forKey: "tessedit_char_whitelist");
//		tesseract.image = imageFromCamera;
//		tesseract.recognize();
//		println(tesseract.recognizedText);
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
				// first technical test: write to HealhKit
				println("Weight saved successfully ")
			} else {
				println("Error: \(error)")
				
			}
		})
	}

}

