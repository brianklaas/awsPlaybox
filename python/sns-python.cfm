<cfset resultMessage = "" />

<cfif structKeyExists(URL, "example")>
	<cfset pathToPythonCode = expandPath("/awsPlaybox/python/sns/") />
	<cfset pathToBashScript = pathToPythonCode & "pythonInvoke.sh" />
	<cfswitch expression="#Val(URL.example)#">
		<cfcase value="1">
			<cfset fileToExecute = pathToPythonCode & "subscribeViaEmail.py" />
			<cfexecute name = "#pathToBashScript#"
				arguments = "#fileToExecute#"
			    variable = "pythonScriptResult"
			    errorVariable = "errorFromPythonScript"
			    timeout = "10">
			</cfexecute>
			<cfif Len(errorFromPythonScript)>
				<cfthrow message="SNS Topic Subscribe Error" detail="#errorFromPythonScript#" />
			</cfif>
			<cfset resultMessage = "Subscribed to topic via email." />
		</cfcase>
		<cfcase value="2">
			<cfset fileToExecute = pathToPythonCode & "publishToSNS.py" />
			<cfexecute name = "#pathToBashScript#"
				arguments = "#fileToExecute#"
			    variable = "pythonScriptResult"
			    errorVariable = "errorFromPythonScript"
			    timeout = "10">
			</cfexecute>
			<cfif Len(errorFromPythonScript)>
				<cfthrow message="SNS Send Error" detail="#errorFromPythonScript#" />
			</cfif>
			<cfset resultMessage = "Test message sent to SNS." />
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="Unsupported action requested" detail="You have requested an example (#URL.example#) which is not supported at this time." />
		</cfdefaultcase>
	</cfswitch>
</cfif>

<cfcontent reset="true" />

<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>AWS Playbox: AWS Service Demos</title>
		<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700,800' rel='stylesheet' type='text/css'>
		<link rel="stylesheet" href="../assets/styles.css?v=1.0">
	</head>

	<body>
		<div align="center">
			<div id="mainBox">
				<h3>AWS Service Demos:</h3>
				<h1>Simple Notification Service (SNS)</h1>
				<h3>Python Example</h3>

				<cfif Len(resultMessage)>
					<hr noshade />
					<p><strong><cfoutput>#resultMessage#</cfoutput></strong></p>
					<hr noshade />
				</cfif>

				<p><a href="sns-python.cfm?example=1">Subscribe to a topic via email</a> &nbsp; &nbsp; [ <a href="../showSourceCode.cfm?fileToGrab=pySubscribe">Source</a> ]</p>
				<p><a href="sns-python.cfm?example=2">Send a test SNS notification</a> &nbsp; &nbsp; [ <a href="../showSourceCode.cfm?fileToGrab=pySendSNS">Source</a> ]</p>
				<p align="right" ><a href="../index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>