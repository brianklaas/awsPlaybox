component {
	
	this.name = 'awsPlaybox';
	this.applicationTimeout = CreateTimeSpan(0, 0, 0, 5);
	this.sessionManagement = false;

    function onApplicationStart(){
        application.awsServiceFactory = createObject("component", "model.awsServiceFactory").init();

        // Put your ARNs for Lambda, and your DynamoDB table name here
        application.awsResources = structNew();
        application.awsResources.lambdaFunctionARN = "ARN OF THE LAMBDA FUNCTION IN lambda.cfm GOES HERE";
        application.awsResources.stepFunctionARN = "ARN OF THE STEP FUNCTION STATE MACHINE IN stepFunctions.cfm GOES HERE";
        application.awsResources.snsTopicARN = "ARN OF THE SNS TOPIC IN sns.cfm GOES HERE";
        application.awsResources.dynamoDBTableName = "TABLE NAME OF THE TABLE IN DYNAMODB GOES HERE";

        return true;
    }

}