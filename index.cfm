<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>AWS Service Playbox</title>
		<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700,800' rel='stylesheet' type='text/css'>
		<link rel="stylesheet" href="assets/styles.css?v=1.0">
	</head>

	<body>
		<div align="center">
			<div id="mainBox">
				<h1>AWS Service Playbox</h1>
				<h3>CFML</h3>
				<p><a href="lambda.cfm">Lambda Function Invocation</a></p>
				<p><a href="dynamodb.cfm">DynamoDB</a></p>
				<p><a href="sns.cfm">Simple Notification Service (SNS)</a></p>
				<p><a href="rekognition.cfm">Rekognition</a></p>
				<p><a href="stepFunctions.cfm">Step Functions</a></p>
				<p>&nbsp;</p>
				<h3>Python</h3>
				<p><a href="python/sns-python.cfm">Simple Notification Service (SNS)</a></p>
				<div class="spacer"></div>
				<p>&nbsp;</p>
				<div class="smallerText">
					<h3>Source Code</h3>
					<p>Lambda:</p>
					<p><a href="showSourceCode.cfm?fileToGrab=jsLargeFile">Lambda (Node): Check for Large File Uploads</a>
					<p><a href="showSourceCode.cfm?fileToGrab=jsReturnData">Lambda (Node): Return Data to Caller</a>
					<p><a href="showSourceCode.cfm?fileToGrab=jsGenerateRandom">Lambda (Node): Generate Random Number</a>
					<p><a href="showSourceCode.cfm?fileToGrab=jsDetectLabels">Lambda (Node): Detect Labels for Image</a>
					<h5>Transcribe a Video, Translate, and Speak Tranlation Workflow</h5>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfStartTranscribe">Lambda (Node): Start Transcribe Job</a>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfCheckTranscribeJob">Lambda (Node): Check Transcribe Job Status</a>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfGetTranscript">Lambda (Node): Get Transcription File</a>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfTranslateText">Lambda (Node): Translate Text</a>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfPrepTranlation">Lambda (Node): Prep Translated Text for Speech</a>
					<p><a href="showSourceCode.cfm?fileToGrab=vwfTextToSpeech">Lambda (Node): Convert Text to Speech</a>
					<p>&nbsp;</p>
					<p>Step Functions:</p>
					<p><a href="showSourceCode.cfm?fileToGrab=stateMachineChoiceDemo">State Machine: Describe A Random Image</a></p>
					<p><a href="showSourceCode.cfm?fileToGrab=transcribeTanslateStepFunc">State Machine: Transcribe a Video, Translate, and Speak Tranlation</a></p>
					<p>&nbsp;</p>
					<p>Python Examples</p>
					<p><a href="showSourceCode.cfm?fileToGrab=pySubscribe">Python: Subscribe to a SNS Topic via Email</a></p>
					<p><a href="showSourceCode.cfm?fileToGrab=pySendSNS">Python: Send a Test SNS Notification</a></p>
					<p><a href="showSourceCode.cfm?fileToGrab=pyCheckServers">Lambda (Python): Check Server Status</a>
				</div>
			</div>
		</div>

	</body>
</html>