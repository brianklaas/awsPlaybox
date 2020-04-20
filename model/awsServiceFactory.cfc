/*
AWS Service Factory

This component creates AWS service objects based on the parameter passed in.

Author: Brian Klaas (brian.klaas@gmail.com)
(c) 2020, Brian Klaas

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
		var javaObjectName = "";
		switch(lcase(arguments.serviceName)){
			case 'dynamodb':
				javaObjectName = "com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder";
				break;
			case 'iam':
				javaObjectName = "com.amazonaws.services.identitymanagement.AmazonIdentityManagementClientBuilder";
				break;
			case 'lambda':
				javaObjectName = "com.amazonaws.services.lambda.AWSLambdaClientBuilder";
				break;
			case 'rekognition':
				javaObjectName = "com.amazonaws.services.rekognition.AmazonRekognitionClientBuilder";
				break;
			case 's3':
				javaObjectName = "com.amazonaws.services.s3.AmazonS3ClientBuilder";
				break;
			case 'sns':
				javaObjectName = "com.amazonaws.services.sns.AmazonSNSClientBuilder";
				break;
			case 'stepFunctions':
				javaObjectName = "com.amazonaws.services.stepfunctions.AWSStepFunctionsClientBuilder";
				break;
			case 'transcribe':
				javaObjectName = "com.amazonaws.services.transcribe.AmazonTranscribeClientBuilder";
				break;
			case 'translate':
				javaObjectName = "com.amazonaws.services.translate.AmazonTranslateClientBuilder";
				break;
			default:
				throw(message="Unsupported service requested", detail="You have requested an AWS service (#arguments.serviceName#) which is not supported at this time.");
				break;
		}
		serviceObject = CreateObject('java', '#javaObjectName#').standard().withCredentials(variables.awsStaticCredentialsProvider).withRegion(#variables.awsRegion#).build();
		return serviceObject;
	}

}