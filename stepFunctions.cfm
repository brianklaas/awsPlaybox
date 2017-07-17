<cfset stepFunctionResult = StructNew() />

<cfif structKeyExists(URL, "invokeStepFunction")>
	<cfscript>
		stepFunctionService = application.awsServiceFactory.createServiceObject('stepFunctions');

		executionRequest = CreateObject('java', 'com.amazonaws.services.stepfunctions.model.StartExecutionRequest').init();
		executionRequest.setStateMachineArn(application.awsResources.stepFunctionARN);
		tempName = "AWSPlayboxExecution" & DateDiff("s", DateConvert("utc2Local", "January 1 1970 00:00"), now());
		executionRequest.setName(tempName);

		// executionResult is of type com.amazonaws.services.stepfunctions.model.StartExecutionResult
		executionResult = stepFunctionService.StartExecution(executionRequest);
		executionARN = executionResult.getExecutionARN();

		// Wait until the step function invocation is done. Promises (futures) sure would be nice here.
		sleep(7000);
		describeExecutionRequest = CreateObject('java', 'com.amazonaws.services.stepfunctions.model.DescribeExecutionRequest').init();
		describeExecutionRequest.setExecutionArn(executionARN);
		
		// describeActivityResult is of type com.amazonaws.services.stepfunctions.model.DescribeActivityResult
		describeActivityResult = stepFunctionService.describeExecution(describeExecutionRequest);

		stepFunctionResult.status = describeActivityResult.getStatus();
		stepFunctionResult.finishedOn = describeActivityResult.getStopDate();
		stepFunctionResult.output = DeserializeJSON(describeActivityResult.getOutput());
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

				<cfif structKeyExists(stepFunctionResult, "status")>
					<p>Result of Step Function invocation:</p>
					<div>
						<div style="width:50%; float:left;">
							<cfoutput>
								<p>Status: #stepFunctionResult.status#</p>
								<p>Finished On: #DateTimeFormat(stepFunctionResult.finishedOn, "long")#</p>
							</cfoutput>
							<p><cfdump var="#stepFunctionResult.output#"></p>
						</div>
						<div style="width:50%; float:right;">
							<p>Here is the image used:</p>
							<p>
								<cfoutput><img src="http://#stepFunctionResult.output.s3Bucket#.s3.amazonaws.com/#stepFunctionResult.output.s3Key#" width="450" height="375" border="1" /></cfoutput>
							</p>
						</div>
					</div>
					<br clear="all">
				</cfif>

				<p><a href="stepFunctions.cfm?invokeStepFunction=1">Invoke Demo Step Function Workflow</a></p>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>
	</body>
</html>