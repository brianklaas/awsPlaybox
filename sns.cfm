<cfset snsMessageSent = 0 />
<cfset topicCreated = 0 />
<cfset subscriptionRequestSent = 0 />
<cfset sns = application.awsServiceFactory.createServiceObject('sns') />

<cfif structKeyExists(URL, "createTopic")>
	<cfscript>
		topicName = "AWSPlayboxDemoTopic-" & dateTimeFormat(Now(), "yyyy-mm-dd-HH-nn-ss");
		createTopicRequest = CreateObject('java', 'com.amazonaws.services.sns.model.CreateTopicRequest').withName(topicName);

		createTopicResult = sns.createTopic(createTopicRequest);

		application.awsResources.currentSNSTopicARN = createTopicResult.getTopicArn();

		topicCreated = 1;
	</cfscript>
</cfif>

<cfif structKeyExists(FORM, "emailAddress")>
	<cfscript>
		if (Len(Trim(FORM.emailAddress)) LTE 5) {
			throw(message="Invalid email address provided.");
			abort;
		}
		subscribeRequest = CreateObject('java', 'com.amazonaws.services.sns.model.SubscribeRequest').withTopicARN(application.awsResources.currentSNSTopicARN).withProtocol("email").withEndpoint(Trim(FORM.emailAddress));
		sns.subscribe(subscribeRequest);

		subscriptionRequestSent = 1;
	</cfscript>
</cfif>

<cfif structKeyExists(URL, "sendMessage")>
	<cfscript>
		subject = "AWS Playbox SNS CFML Demo";
		message = "Hello there!" & chr(13) & chr(13) & "The current time is " & DateTimeFormat(Now(), "Full") & ".";

		publishRequest = CreateObject('java', 'com.amazonaws.services.sns.model.PublishRequest').withTopicARN(application.awsResources.currentSNSTopicARN).withSubject(subject).withMessage(message);
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

				<cfif topicCreated>
					<p><b>The topic was created!</b></p>
				</cfif>
				<cfif subscriptionRequestSent>
					<p>A subscription request was sent for <cfoutput>#Trim(FORM.emailAddress)#</cfoutput>. You must confirm that you want this subscription by responding to the "AWS Notification - Subscription Confirmation" email sent by AWS before any SNS notifications are sent to this address.</p>
					<hr noshade />
				</cfif>
				<cfif snsMessageSent>
					<p><b>A SNS notification was sent!</b></p>
				</cfif>

				<cfif Len(application.awsResources.currentSNSTopicARN) GT 0>
					<p>The topic ARN is: <cfoutput>#application.awsResources.currentSNSTopicARN#</cfoutput></p>
					<form action="sns.cfm" method="post">
						<p>Subscribe to this topic via this email address: <input name="emailAddress" type="email"> &nbsp; <input type="submit"></p>
					</form>
					<p><a href="sns.cfm?sendMessage=1">Send a test SNS notification</a> 
						<br>(Note: you must have subscribed to the topic and confirmed your subscription to see any result)</p>
				<cfelse>
					<p><a href="sns.cfm?createTopic=1">Create a new topic</a></p>
				</cfif>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>