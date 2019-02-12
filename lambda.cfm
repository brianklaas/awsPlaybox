<cfset lambdaFunctionResult = "" />

<cfif structKeyExists(URL, "invokeFunction")>
	<cfscript>
		payload = {
			"firstName": "Brian",
			"lastName": "Klaas",
			"email": "brian.klaas@gmail.com",
			"classes": [
				{
					"courseNumber": "260.710.81",
					"role": "Faculty"
				},
				{
					"courseNumber": "120.641.01",
					"role": "Student"
				}
			]
		}

		jsonPayload = serializeJSON(payload);
		// You need uncomment the line below if you have the "Prefix serialized JSON with " option turned on in the ColdFusion administrator.
		// jsonPayload = replace(jsonPayload,"//","");

		lambda = application.awsServiceFactory.createServiceObject('lambda');
		invokeRequest = CreateObject('java', 'com.amazonaws.services.lambda.model.InvokeRequest').init();
		invokeRequest.setFunctionName(application.awsResources.lambdaFunctionARN);
		invokeRequest.setPayload(jsonPayload);

		result = variables.lambda.invoke(invokeRequest);

		sourcePayload = result.getPayload();
		// The payload returned from a Lambda function invocation in the Java SDK is always a Java binary stream. As such, it needs to be decoded into a string of characters.
		charset = CreateObject('java', 'java.nio.charset.Charset').forName("UTF-8");
		charsetDecoder = charset.newDecoder();
		lambdaFunctionResult = charsetDecoder.decode(sourcePayload).toString();
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
				<h1>Lambda Function Invocation</h1>

				<cfif Len(lambdaFunctionResult)>
					<p>Result of function invocation:</p>
					<p><cfoutput>#lambdaFunctionResult#</cfoutput></p>
				</cfif>

				<p><a href="lambda.cfm?invokeFunction=1">Invoke Demo Function</a></p>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>