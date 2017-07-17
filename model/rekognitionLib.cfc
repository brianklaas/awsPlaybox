/*
Rekognition Utility Functions

This component contains functions to make requests to AWS Rekognition.

Author: Brian Klaas (bklaas@jhu.edu)
(c) 2017, The Johns Hopkins Bloomberg School of Public Health Center for Teaching and Learning

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
		faceImage1S3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		faceImage1S3Object.setBucket(arguments.awsBucketName);
		faceImage1S3Object.setName(arguments.face1Path);
		faceImage1.setS3Object(faceImage1S3Object);

		var faceImage2 = CreateObject('java', 'com.amazonaws.services.rekognition.model.Image').init();
		faceImage2S3Object = CreateObject('java', 'com.amazonaws.services.rekognition.model.S3Object').init();
		faceImage2S3Object.setBucket(arguments.awsBucketName);
		faceImage2S3Object.setName(arguments.face2Path);
		faceImage2.setS3Object(faceImage2S3Object);

		compareFacesRequest.setSourceImage(faceImage1);
		compareFacesRequest.setTargetImage(faceImage2);

		return variables.rekognitionService.compareFaces(compareFacesRequest);
	}

	/**
	*	@description Returns a structure of labels for the image, with the label as the key and the confidence level as the value
	*	@requiredArguments
	*		- awsBucketName = Name of the bucket where the images reside
	*		- pathToImage = Path to the first (source) face image in the provided bucket
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