<cfset snsMessageSent = 0 />

<cfif structKeyExists(URL, "sendMessage")>
	<cfscript>
		subject = "AWS Playbox SNS CFML Demo";
		message = "Hello there!" & chr(13) & chr(13) & "The current time is " & DateTimeFormat(Now(), "Full") & ".";

		sns = application.awsServiceFactory.createServiceObject('sns');
		publishRequest = CreateObject('java', 'com.amazonaws.services.sns.model.PublishRequest').init(application.awsResources.snsTopicARN, message,subject);

		sns.publish(publishRequest);

		snsMessageSent = 1;
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
				<h1>Simple Notification Service (SNS)</h1>

				<cfif snsMessageSent>
					<p><b>A SNS notification was sent!</b></p>
				</cfif>
				<p>This service wasn't covered in the presentation, but it's so powerful, and so simple to use, that I wanted to include a brief demo here.</p>
				<p>SNS can be used to send text-based messages to any service which subscribes to the message. Subscribers can include other applications, email accounts, or SMS messages on wireless networks around the world. There are limitations to SMS subscriptions (<a href="http://docs.aws.amazon.com/sns/latest/dg/SMSMessages.html">see the AWS docs</a>), but this is a super-easy way to build nearly-zero cost admin notification systems which can alert you on your phone.</p>
				<p>To get this working, you need to create a <em>topic</em> in SNS, and then select either email or SMS subscription to that topic. You'll also need to confirm your subscription per the activation messages that AWS sends you. Once you do that, this demo will work!</p>
				<p><a href="sns.cfm?sendMessage=1">Send a test SNS notification</a></p>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>