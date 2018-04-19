<cfset stepFunctionResult = StructNew() />

<cfif structKeyExists(URL, "invokeStepFunction")>
	<cfscript>
		// The AWS Service Factory, created at application startup, handles the building of the object that will speak to
		// the Step Functions service, and handles authentication to AWS.
		stepFunctionService = application.awsServiceFactory.createServiceObject('stepFunctions');

		// Each execution request in step functions must have a unique name
		executionRequest = CreateObject('java', 'com.amazonaws.services.stepfunctions.model.StartExecutionRequest').init();
		jobName = "AWSPlayboxExecution" & DateDiff("s", DateConvert("utc2Local", "January 1 1970 00:00"), now());
		executionRequest.setName(jobName);

		if (URL.invokeStepFunction IS "image") {
			stepFunctionARN = application.awsResources.stepFunctionRandomImageARN;
			executionType = "Image Description";
		} else if (URL.invokeStepFunction IS "videoWorkflow") {
			stepFunctionARN = application.awsResources.stepFunctionTranscribeTranslateARN;
			executionType = "Video Workflow";
			// The video workflow requires the following input: urlOfFileOnS3, mediaType
			// JavaScript (running in the Lambda function) is case-sensitive. As such, we can't use implicit struct notation because Adobe CF will serialize the JSON using keys in all caps.
			inputStruct = StructNew();
			inputStruct['urlOfFileOnS3']="HTTPS PATH TO YOUR SOURCE VIDEO FILE ON S3";
			inputStruct['mediaType']="mp4";
			// If your CF server is configured to add a double slash at the start of serialized JSON, and is CF11+, you need to strip that out by setting the third parameter of serializeJSON -- useSecureJSONPrefix -- to false
			// If you're running CF10, use: executionRequest.setInput(right(serializeJSON(inputStruct), (Len(serializeJSON(inputStruct))-2)));
			executionRequest.setInput(serializeJSON(inputStruct, false, false));
		}
		executionRequest.setStateMachineArn(stepFunctionARN);

		// When we start an execution of a Step Function workflow, we get an executionResult object back.
		// The execution result will have the unique ARN of the execution in AWS.
		// executionResult is of type com.amazonaws.services.stepfunctions.model.StartExecutionResult
		executionResult = stepFunctionService.StartExecution(executionRequest);
		executionARN = executionResult.getExecutionARN();

		executionInfo = { 
			executionType=executionType, 
			executionARN=executionARN,
			timeStarted=Now() 
		};

		// Here we add the information about current executions to memory so we can retrieve them as needed. In a real app, you'd want to save this to database.
		arrayAppend(application.currentStepFunctionExecutions, executionInfo);
	</cfscript>
</cfif>

<cfif structKeyExists(URL, "checkStepFunctionARN")>
	<cfscript>
		stepFunctionService = application.awsServiceFactory.createServiceObject('stepFunctions');

		// The describe execution request object is what we use to check the status of a current Step Function workflow execution
		describeExecutionRequest = CreateObject('java', 'com.amazonaws.services.stepfunctions.model.DescribeExecutionRequest').init();
		describeExecutionRequest.setExecutionArn(URL.checkStepFunctionARN);
		
		// describeActivityResult is of type com.amazonaws.services.stepfunctions.model.DescribeActivityResult
		describeActivityResult = stepFunctionService.describeExecution(describeExecutionRequest);

		stepFunctionResult.status = describeActivityResult.getStatus();
		// We only care about success results here. A production application would would handle error results and schedule in progress tasks for checking again at a later time.
		if (stepFunctionResult.status IS "SUCCEEDED") {
			stepFunctionResult.finishedOn = describeActivityResult.getStopDate();
			stepFunctionResult.output = DeserializeJSON(describeActivityResult.getOutput());
			application.currentStepFunctionExecutions.each(function(element, index) {
				if (element.executionARN IS checkStepFunctionARN) {
					stepFunctionResult.invocationType = element.executionType;
					arrayDeleteAt(application.currentStepFunctionExecutions, index);
					break;
				}
			});
		}
	</cfscript>
</cfif>

<cfcontent reset="true" />

<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>AWS Playbox: AWS Service Demos</title>
		<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700,800' rel='stylesheet' type='text/css'>
		<link rel="stylesheet" href="assets/styles.css?v=1.0">
	</head>

	<body>
		<div align="center">
			<div id="mainBox">
				<h3>AWS Service Demos:</h3>
				<h1>Step Function Invocation</h1>

				<cfif structKeyExists(URL, "checkStepFunctionARN")>
					<p>Result of Step Function invocation:</p>
					<cfoutput>
						<cfif (stepFunctionResult.status IS "SUCCEEDED")>
							<cfif stepFunctionResult.invocationType IS "Image Description">
								<div>
									<div style="width:50%; float:left;">
										<p>Status: #stepFunctionResult.status#</p>
										<p>Finished On: #DateTimeFormat(stepFunctionResult.finishedOn, "long")#</p>
										<p><cfdump var="#stepFunctionResult.output#"></p>
									</div>
									<div style="width:50%; float:right;">
										<p>Here is the image used:</p>
										<p>
											<img src="http://#stepFunctionResult.output.s3Bucket#.s3.amazonaws.com/#stepFunctionResult.output.s3Key#" width="450" height="375" border="1" />
										</p>
									</div>
								</div>
								<br clear="all">
							<cfelseif stepFunctionResult.invocationType IS "Video Workflow">
								<p>Status: #stepFunctionResult.status#</p>
								<p>Finished On: #DateTimeFormat(stepFunctionResult.finishedOn, "long")#</p>
								<p><cfdump var="#stepFunctionResult.output#"></p>
							</cfif>
						<cfelse>
							<p><strong>#stepFunctionResult.status#</strong></p>
						</cfif> <!--- If status is succeeded --->
					</cfoutput>
				</cfif> <!--- If an executionARN was passed in to the URL request --->

				<hr>
				<h3>Launch Step Function Workflow:</h3>
				<p><a href="stepFunctions.cfm?invokeStepFunction=image">Describe a Random Image</a></p>
				<p><a href="stepFunctions.cfm?invokeStepFunction=videoWorkflow">Transcribe, Translate, and Speak a Video</a></p>
				<cfif arrayLen(application.currentStepFunctionExecutions)>
				<hr>
				<h3>Current Step Function Executions:</h3>
					<cfoutput>
						<ul>
							<cfloop array="#application.currentStepFunctionExecutions#" index="item">
								<li>#item.executionType#  &mdash; <a href="stepFunctions.cfm?checkStepFunctionARN=#item.executionARN#">Started #DateTimeFormat(item.timeStarted, "long")#</a></li>
							</cfloop>
						</ul>
					</cfoutput>
				</cfif>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>
	</body>
</html>