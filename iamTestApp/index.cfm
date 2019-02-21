<cfset successMsg = "">

<cfif structKeyExists(FORM, "userAccessKey") AND structKeyExists(FORM, "userSecretKey")>
    <cfscript>
        awsCredentials = CreateObject('java','com.amazonaws.auth.BasicAWSCredentials').init(trim(FORM.userAccessKey), trim(FORM.userSecretKey));
		awsStaticCredentialsProvider = CreateObject('java','com.amazonaws.auth.AWSStaticCredentialsProvider').init(awsCredentials);
		awsRegion = "us-east-1";
        if ((Len(Trim(FORM.s3BucketName)) GT 1) && (Len(Trim(FORM.fileToPutOnS3)) GT 1)) {
            uploadedFile = fileUpload(getTempDirectory(), "form.fileToPutOnS3", " ", "makeunique");
            fileLocation = getTempDirectory() & uploadedFile.serverFile;
            fileContent = fileReadBinary(getTempDirectory() & uploadedFile.serverFile);
            // We're not using CFML's built-in support for S3 here because it requires a lot more permissions to be set than what we'd normally want.
            // It's also good to show how to upload a file to S3 using the SDK.
            s3 = CreateObject('java', 'com.amazonaws.services.s3.AmazonS3ClientBuilder').standard().withCredentials(awsStaticCredentialsProvider).withRegion(#awsRegion#).build();
            javaFileObject = CreateObject('java', 'java.io.File').init(fileLocation);
            putFileRequest = CreateObject('java', 'com.amazonaws.services.s3.model.PutObjectRequest').init(trim(FORM.s3BucketName), uploadedFile.serverFile, javaFileObject);
            s3.putObject(putFileRequest);
            successMsg = "The file was uploaded to the S3 bucket. ";
        }
        if (Len(Trim(FORM.snsTopicARN)) GT 20) {
            sns = CreateObject('java', 'com.amazonaws.services.sns.AmazonSNSClientBuilder').standard().withCredentials(awsStaticCredentialsProvider).withRegion(#awsRegion#).build();
            subject = "AWS Playbox IAM Permissions Demo";
            message = "Hello there!" & chr(13) & chr(13) & "The current time is " & DateTimeFormat(Now(), "Full") & ".";
            publishRequest = CreateObject('java', 'com.amazonaws.services.sns.model.PublishRequest').withTopicARN(FORM.snsTopicARN).withSubject(subject).withMessage(message);
            sns.publish(publishRequest);
            successMsg &= "A message was sent to the SNS topic.";
        }
    </cfscript>
</cfif>

<cfcontent reset="true" />

<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>AWS Playbox: IAM Service Demo</title>
		<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700,800' rel='stylesheet' type='text/css'>
		<link rel="stylesheet" href="../assets/styles.css?v=1.0">
	</head>

	<body>
		<div align="center">
			<div id="mainBox">
				<h3>Identity Access Management (IAM) Demo:</h3>
				<h1>IAM User Permission Demo</h1>
                <p>In order for this demo to work, you must have first created all the resources on the <a href="/awsPlaybox/iam.cfm">IAM playbox page</a>.</p>
                <p>If you want to test failure scenarios, enter a valid S3 bucket or SNS topic to which this user does <b>not</b> have permission.</p>
                <p>&nbsp;</p>
                <cfif Len(successMsg) GT 1>
                    <p class="successBox"><cfoutput>#successMsg#</cfoutput></p>
                </cfif>
                <form name="iamTest" action="index.cfm" method="post" enctype="multipart/form-data">
                    <h3>User Credentials</h3>
                    <p>
                        Enter the Access Key for this user:<br>
                        <input type="text" name="userAccessKey" size="30" <cfif structKeyExists(FORM, "userAccessKey") AND len(trim(FORM.userAccessKey)) GT 1>value="<cfoutput>#trim(FORM.userAccessKey)#</cfoutput>"</cfif>>
                    </p>
                    <p>
                        Enter the Secret Key for this user:<br>
                        <input type="text" name="userSecretKey" size="50" <cfif structKeyExists(FORM, "userSecretKey") AND len(trim(FORM.userSecretKey)) GT 1>value="<cfoutput>#trim(FORM.userSecretKey)#</cfoutput>"</cfif>>
                    </p>
                    <h3>S3 Test</h3>
                    <p>
                        Enter the bucket name specified in the /awsPlaybox/iamPolicies/awsPlayboxPrivateReadWrite.txt policy file:<br>
                        <input type="text" name="s3BucketName" size="30" <cfif structKeyExists(FORM, "s3BucketName") AND len(trim(FORM.s3BucketName)) GT 1>value="<cfoutput>#trim(FORM.s3BucketName)#</cfoutput>"</cfif>><br>
                        Select a file to upload: <input type="file" name="fileToPutOnS3"><br>
                        <input type="submit" value="Upload File to S3 Bucket">
                    <p>&nbsp;</p>
                    <h3>SNS Test</h3>
                    <p>
                        Enter the ARN of the SNS topic that you created on the <a href="/awsPlaybox/sns.cfm">SNS demo page</a>:<br>
                        <input type="text" name="snsTopicARN" size="70" <cfif structKeyExists(FORM, "snsTopicARN") AND len(trim(FORM.snsTopicARN)) GT 1>value="<cfoutput>#trim(FORM.snsTopicARN)#</cfoutput>"</cfif>><br>
                        <input type="submit" value="Send SNS Message for This User">
                    </p>
                </form>
                <p>&nbsp;</p>
                <p align="right" ><a href="/awsPlaybox/index.cfm" class="homeButton">AWSPlaybox Home</a></p>
			</div>
		</div>
	</body>
</html>