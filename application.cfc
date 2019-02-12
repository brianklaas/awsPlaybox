component {
	
	this.name = 'awsPlaybox';
	this.applicationTimeout = CreateTimeSpan(0, 0, 15, 0);
	this.sessionManagement = false;

    function onApplicationStart(){
        application.awsServiceFactory = createObject("component", "model.awsServiceFactory").init();
        
        application.currentStepFunctionExecutions = arrayNew(1);
        application.currentTranscribeJobs = arrayNew(1);

        // Put your ARNs for Lambda, and your DynamoDB table name here
        application.awsResources = structNew();
        application.awsResources.lambdaFunctionARN = "ARN OF THE LAMBDA FUNCTION IN lambda.cfm GOES HERE";
        application.awsResources.stepFunctionRandomImageARN = "ARN OF THE RANDOM IMAGE STEP FUNCTION STATE MACHINE GOES HERE";
        application.awsResources.stepFunctionTranscribeTranslateARN = "ARN OF THE TRANSCRIBE, TRANSLATE, SPEAK STEP FUNCTION STATE MACHINE GOES HERE";
        application.awsResources.dynamoDBTableName = "TABLE NAME OF THE TABLE IN DYNAMODB IN dynamodb.cfm GOES HERE";
        application.awsResources.currentSNSTopicARN = "";
        application.awsResources.iam = {};

        return true;
    }

}