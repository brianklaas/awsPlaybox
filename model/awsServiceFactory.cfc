/*
AWS Service Factory

This component creates AWS service objects based on the parameter passed in.

Author: Brian Klaas (brian.klaas@gmail.com)
(c) 2018, Brian Klaas

*/

component output="false" hint="A utility for creating AWS Service objects." {

	/**
	*	@description Component initialization
	*/
	public any function init() {
		var credentialsConfig = CreateObject('component','awsCredentials').init();
		// AWS Docs for Working with Credentials: http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html
		var awsCredentials = CreateObject('java','com.amazonaws.auth.BasicAWSCredentials').init(credentialsConfig.accessKey, credentialsConfig.secretKey);
		variables.awsStaticCredentialsProvider = CreateObject('java','com.amazonaws.auth.AWSStaticCredentialsProvider').init(awsCredentials);
		variables.awsRegion = "us-east-1";
		return this;
	}

	/**
	*	@description Creates a service object based on the service name provided
	*	@requiredArguments
	*		- serviceName = Name of the service we want to use. Currently supports SNS, Lambda, and DynamoDB.
	*/
	public any function createServiceObject(required string serviceName) {
		var serviceObject = 0;
		switch(lcase(arguments.serviceName)){
			case 'dynamodb':
				serviceObject = CreateObject('java', 'com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			case 'lambda':
				serviceObject = CreateObject('java', 'com.amazonaws.services.lambda.AWSLambdaClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			case 'rekognition':
				serviceObject = CreateObject('java', 'com.amazonaws.services.rekognition.AmazonRekognitionClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			case 'sns':
				serviceObject = CreateObject('java', 'com.amazonaws.services.sns.AmazonSNSClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			case 'stepFunctions':
				serviceObject = CreateObject('java', 'com.amazonaws.services.stepfunctions.AWSStepFunctionsClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			case 'transcribe':
				serviceObject = CreateObject('java', 'com.amazonaws.services.transcribe.AmazonTranscribeClientBuilder').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
				break;
			default:
				throw(message="Unsupported service requested", detail="You have requested an AWS service (#arguments.serviceName#) which is not supported at this time.");
				break;
		}
		return serviceObject;
	}

}