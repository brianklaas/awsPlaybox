/*
Rekognition Utility Functions

This component contains functions to make requests to AWS Rekognition.

Author: Brian Klaas (brian.klaas@gmail.com)
(c) 2018, Brian Klaas

*/

component output="false" hint="A utility for making requests to AWS Rekognition." {

	/**
	*	@description Component initialization
	*/
	public any function init() {
		variables.rekognitionService = application.awsServiceFactory.createServiceObject('rekognition');
		return this;
	}

	/**
	*	@description Generates a compare faces request and returns a compare faces result
	*	@requiredArguments
	*		- awsBucketName = Name of the bucket where the images reside
	*		- face1Path = Path to the first (source) face image in the provided bucket
	*		- face2Path = Path to the second (target) face image in the provided bucket
	*/
	public any function compareFaces(required string awsBucketName, required string face1Path, required string face2Path) {
		var compareFacesRequest = CreateObject('java', 'com.amazonaws.services.rekognition.model.CompareFacesRequest').init();
				
		var faceImage1 = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		var faceImage1S3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		faceImage1S3Object.setBucket(arguments.awsBucketName);
		faceImage1S3Object.setName(arguments.face1Path);
		faceImage1.setS3Object(faceImage1S3Object);

		var faceImage2 = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		var faceImage2S3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		faceImage2S3Object.setBucket(arguments.awsBucketName);
		faceImage2S3Object.setName(arguments.face2Path);
		faceImage2.setS3Object(faceImage2S3Object);

		compareFacesRequest.setSourceImage(faceImage1);
		compareFacesRequest.setTargetImage(faceImage2);

		return variables.rekognitionService.compareFaces(compareFacesRequest);
	}

	/**
	*	@description Returns an array of structures of sentiment labels for the faces in the image
	*	@requiredArguments
	*		- awsBucketName = Name of the bucket where the images reside
	*		- pathToImage = Path to the image in the provided bucket
	*/
	public array function detectSentiment(required string awsBucketName, required string pathToImage) {
		var returnArray = arrayNew(1);
		var thisFaceObj = 0;
		var faceCounter = 0;
		var detectFacesRequest = CreateObject('java', 'com.amazonaws.services.rekognition.model.DetectFacesRequest').init();
		var imageToAnalyze = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		var imageOnS3 = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		imageOnS3.setBucket(arguments.awsBucketName);
		imageOnS3.setName(arguments.pathToImage);
		imageToAnalyze.setS3Object(imageOnS3);
		detectFacesRequest.setImage(imageToAnalyze);
		var attributesArray = ["ALL"];
		detectFacesRequest.setAttributes(attributesArray);
		var detectFacesResult = variables.rekognitionService.detectFaces(detectFacesRequest);
		var facesArray = detectFacesResult.getFaceDetails();

		facesArray.each(function(thisFaceObj, index) {
			faceCounter++;
			returnArray[faceCounter] = structNew();
			// For all the properties of the FaceDetail object, see https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/rekognition/model/FaceDetail.html
			returnArray[faceCounter]['Age Range'] = thisFaceObj.getAgeRange().getLow() & "-" & thisFaceObj.getAgeRange().getHigh();
			returnArray[faceCounter]['Gender'] = thisFaceObj.getGender().getValue();
			returnArray[faceCounter]['Eyeglasses'] = thisFaceObj.getEyeglasses().getValue();
			returnArray[faceCounter]['Sunglasses'] = thisFaceObj.getSunglasses().getValue();
			returnArray[faceCounter]['Smiling'] = thisFaceObj.getSmile().getValue();
			returnArray[faceCounter]['Eyes Open'] = thisFaceObj.getEyesOpen().getValue();
			returnArray[faceCounter]['Mouth Open'] = thisFaceObj.getMouthOpen().getValue();
			returnArray[faceCounter]['Has Beard'] = thisFaceObj.getBeard().getValue();
			var emotionsForFace = thisFaceObj.getEmotions();
			var thisEmotionObj = 0;
			var emotionCounter = 0;
			emotionsForFace.each(function(thisEmotionObj, index) {
				emotionCounter++;
				returnArray[faceCounter]['emotions'][emotionCounter] = structNew();
				returnArray[faceCounter]['emotions'][emotionCounter]['Type'] = thisEmotionObj.getType();
				returnArray[faceCounter]['emotions'][emotionCounter]['Confidence'] = Int(thisEmotionObj.getConfidence());
			});
		});
		return returnArray;
	}

	/**
	*	@description Returns an structure of both the lines of text found in the image and the individual words
	*	@requiredArguments
	*		- awsBucketName = Name of the bucket where the images reside
	*		- pathToImage = Path to the image in the provided bucket
	*/
	public struct function detectText(required string awsBucketName, required string pathToImage) {
		var returnStruct = structNew();
		var thisDetectionObj = 0;
		var linesCounter = 0;
		var wordsCounter = 0;
		var detectTextRequest = CreateObject('java', 'com.amazonaws.services.rekognition.model.DetectTextRequest').init();
		var imageToScan = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		var imageS3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		imageS3Object.setBucket(arguments.awsBucketName);
		imageS3Object.setName(arguments.pathToImage);
		imageToScan.setS3Object(imageS3Object);
		detectTextRequest.setImage(imageToScan);

		var detectTextResult = variables.rekognitionService.detectText(detectTextRequest);
		var detectionsArray = detectTextResult.getTextDetections();

		returnStruct.lines = arrayNew(1);
		returnStruct.words = arrayNew(1);

		detectionsArray.each(function(thisDetectionObj, index) {
			if (thisDetectionObj.getType() is "LINE") {
				linesCounter++;
				returnStruct.lines[linesCounter] = structNew();
				returnStruct.lines[linesCounter]['label'] = thisDetectionObj.getDetectedText();
				returnStruct.lines[linesCounter]['confidence'] = Int(thisDetectionObj.getConfidence());
				returnStruct.lines[linesCounter]['id'] = thisDetectionObj.getID();
				returnStruct.lines[linesCounter]['geometry'] = thisDetectionObj.getGeometry().toString();
			} else {
				wordsCounter++;
				returnStruct.words[wordsCounter] = structNew();
				returnStruct.words[wordsCounter]['label'] = thisDetectionObj.getDetectedText();
				returnStruct.words[wordsCounter]['confidence'] = Int(thisDetectionObj.getConfidence());
				returnStruct.words[wordsCounter]['id'] = thisDetectionObj.getID();
				returnStruct.words[wordsCounter]['parentID'] = thisDetectionObj.getParentID();
				returnStruct.words[wordsCounter]['geometry'] = thisDetectionObj.getGeometry().toString();
			}
		});
		return returnStruct;
	}

	/**
	*	@description Returns an array of labels for the image as structures, with the label as the key and the confidence level as the value
	*	@requiredArguments
	*		- awsBucketName = Name of the bucket where the images reside
	*		- pathToImage = Path to the image in the provided bucket
	*/
	public array function getImageLabels(required string awsBucketName, required string pathToImage) {
		var returnArray = arrayNew(1);
		var thisLabelObj = 0;
		var counter = 0;
		var labelsRequest = CreateObject('java', 'com.amazonaws.services.rekognition.model.DetectLabelsRequest').init();
		var imageToLabel = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		var imageS3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		imageS3Object.setBucket(arguments.awsBucketName);
		imageS3Object.setName(arguments.pathToImage);
		imageToLabel.setS3Object(imageS3Object);
		labelsRequest.setImage(imageToLabel);

		var labelsRequestResult = variables.rekognitionService.detectLabels(labelsRequest);
		var labelsArray = labelsRequestResult.getLabels();

		labelsArray.each(function(thisLabelObj, index) {
			counter++;
			returnArray[counter] = structNew();
			returnArray[counter]['label'] = thisLabelObj.getName();
			returnArray[counter]['confidence'] = Int(thisLabelObj.getConfidence());
		});
		return returnArray;
	}

	/**
	*	@description Returns the similarity value for the provided faces, or a -1 if there was no match
	*	@requiredArguments
	*		- compareFacesResult = Result from AWS CompareFacesRequest, of type com.amazonaws.services.rekognition.model.CompareFacesResult
	*/
	public numeric function getSimilarityValue(required any compareFacesResult) {
		var similarityValue = -1;
		var faceMatchesArray = arguments.compareFacesResult.getFaceMatches();
		if (arrayLen(faceMatchesArray) gt 0) {
			similarityValue = faceMatchesArray[1].getSimilarity();
		}
		return similarityValue;
	}
}