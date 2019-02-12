<cfset iam = application.awsServiceFactory.createServiceObject('iam') />
<cfset errorMsg = "" />
<cfset accessKeysRotated = 0 />

<cfif structKeyExists(URL, "createS3Policy")>
	<cfscript>
        if (structKeyExists(application.awsResources.iam, "S3PolicyARN")) {
            errorMsg = "You have already created a policy with read/write permission to the 'awsPlayboxPrivate' S3 bucket.";
        } else {
            policyName = 'awsPlayboxDemoPolicy-ReadWriteAWSPlayboxPrivateBucket-' & dateTimeFormat(Now(), "yyyy-mm-dd-HH-nn-ss");
            createPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreatePolicyRequest')
                .withPolicyName(policyName)
                .withDescription('Allows read/write permission to the awsPlayboxPrivate S3 bucket.');
            policyDetails = fileRead(expandPath("./iamPolicies/awsPlayboxPrivateReadWrite.txt"));
            createPolicyRequest.setPolicyDocument(policyDetails);
            createPolicyResult = iam.createPolicy(createPolicyRequest);
            policyDetails = createPolicyResult.getPolicy();
            application.awsResources.iam.S3PolicyName = policyDetails.getPolicyName();
            application.awsResources.iam.S3PolicyARN = policyDetails.getARN();
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "createSNSPolicy")>
	<cfscript>
        if (structKeyExists(application.awsResources.iam, "SNSPolicyARN")) {
            errorMsg = "You have already created a policy with permission to send messages to the SNS topic: " & application.awsResources.currentSNSTopicARN;
        } else {
            policyName = 'awsPlayboxDemoPolicy-SendToSNS-' & dateTimeFormat(Now(), "yyyy-mm-dd-HH-nn-ss");
            createPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreatePolicyRequest')
                .withPolicyName(policyName)
                .withDescription('Allows user to send message to the SNS topic:' & application.awsResources.currentSNSTopicARN);
            policyDetails = fileRead(expandPath("./iamPolicies/snsSendMessage.txt"));
            // The policy text file has a placeholder for the current SNS topic for the application
            policyDetails = replace(policyDetails, "%CURRENT_TOPIC_ARN%", application.awsResources.currentSNSTopicARN);
            createPolicyRequest.setPolicyDocument(policyDetails);
            createPolicyResult = iam.createPolicy(createPolicyRequest);
            policyDetails = createPolicyResult.getPolicy();
            application.awsResources.iam.SNSPolicyName = policyDetails.getPolicyName();
            application.awsResources.iam.SNSPolicyARN = policyDetails.getARN();
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "createGroupWithPolicies")>
	<cfscript>
        if (structKeyExists(application.awsResources.iam, "S3GroupARN")) {
            errorMsg = "You have already created a group with the S3 bucket policy.";
        } else if (NOT structKeyExists(application.awsResources.iam, "S3PolicyARN")) {
            errorMsg = "You first need to create a policy with read/write permission to the 'awsPlayboxPrivate' S3 bucket.";
        } else if (NOT structKeyExists(application.awsResources.iam, "SNSPolicyARN")) {
            errorMsg = "You first need to create a policy with permission to publish to the current SNS topic.";
        } else {
            // This is a two-step process: 
            // 1. Create the group 
            // 2. Add the policy/policies to the group
            groupName = 'awsPlayboxDemoGroup-' & dateTimeFormat(Now(), "yyyy-mm-dd-HH-nn-ss");
            createGroupRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreateGroupRequest')
                .withGroupName(groupName);
            createGroupResult = iam.createGroup(createGroupRequest);
            groupDetails = createGroupResult.getGroup();
            // Add the S3 policy to the group
            attachGroupPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.AttachGroupPolicyRequest')
                .withGroupName(groupName)
                .withPolicyArn(application.awsResources.iam.S3PolicyARN);
            // attachGroupPolicy doesn't really return anyting useful in the AttachGroupPolicyResult object. It either succeeds or throws an error.
            // See https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/identitymanagement/model/AttachGroupPolicyResult.html
            attachGroupPolicyRequestResult = iam.attachGroupPolicy(attachGroupPolicyRequest);
            // Attach the SNS policy to the group
            attachGroupPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.AttachGroupPolicyRequest')
                .withGroupName(groupName)
                .withPolicyArn(application.awsResources.iam.SNSPolicyARN);
            attachGroupPolicyRequestResult = iam.attachGroupPolicy(attachGroupPolicyRequest);
            // Only add the information to the application structure if everything has gone through thus far
            application.awsResources.iam.PlayboxGroupName = groupDetails.getGroupName();
            application.awsResources.iam.PlayboxGroupARN = groupDetails.getARN();
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "createUserInAwsPlayboxGroup")>
	<cfscript>
        if (structKeyExists(application.awsResources.iam, "PlayboxUserARN")) {
            errorMsg = "You have already created a user for this demonstration.";
        } else if (NOT structKeyExists(application.awsResources.iam, "PlayboxGroupName")) {
            errorMsg = "You first need to create a group to access the S3 bucket and SNS topic.";
        } else {
            // This is a three step process: 
            // 1. Create the user  
            // 2. Create an Access Key for the user and get a Secret Key back
            // 3. Add the user to the group
            // 
            // STEP ONE: Create the User
            userName = 'awsPlayboxDemo-' & dateTimeFormat(Now(), "yyyy-mm-dd-HH-nn-ss");
            createUserRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreateUserRequest')
                .withUserName(userName);
            // Tags help you identify user types for management and billing purposes. 
            // They're very helpful as the complexity of your AWS service usage grows.
            // The setTags() method takes a Java <collection>. A CFML array works just fine.
            userTag = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.Tag')
                .withKey('userType')
                .withValue('Demonstration');
            tagArray = [ userTag ];
            createUserRequest.setTags(tagArray);
            createUserResult = iam.createUser(createUserRequest);
            userDetails = createUserResult.getUser();
            //
            // STEP TWO: Create an Access Key (and get the corresponding Secret Key in the result)
            // By default, when you create a new user, that user has no permissions, and no way to authenticate to AWS.
            // You have to create an Access Key/Secret Key pair for basic authentication.
            createAccessKeyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreateAccessKeyRequest')
                .withUserName(userName);
            createAccessKeyResult = iam.createAccessKey(createAccessKeyRequest);
            accesKeyInfo = createAccessKeyResult.getAccessKey();
            // Note that Secret Keys are only ever delivered one time. There's no way to retrieve them from AWS after creation.
            //
            // STEP THREE: Add the user to the group
            addUserToGroupRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.AddUserToGroupRequest')
                .withGroupName(application.awsResources.iam.PlayboxGroupName)
                .withUserName(userName);
            // addUserToGroup doesn't really return anyting useful in the AddUserToGroupResult object. It either succeeds or throws an error.
            // See https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/identitymanagement/model/AddUserToGroupResult.html
            addUserToGroupResult = iam.addUserToGroup(addUserToGroupRequest);
            //
            // Only add the information to the application structure if everything has gone through thus far
            application.awsResources.iam.PlayboxUserName = userDetails.getUserName();
            application.awsResources.iam.PlayboxUserARN = userDetails.getARN();
            // We're storing the Secret Key in memory here. 
            // For the love of all that is good, if you store this information in your own apps, you better do it as securely as possible.
            application.awsResources.iam.PlayboxUserAccessKeyID = accesKeyInfo.getAccessKeyID();
            application.awsResources.iam.PlayboxUserSecretKey = accesKeyInfo.getSecretAccessKey();
            application.awsResources.iam.PlayboxUserAccessKeyStatus = accesKeyInfo.getStatus();
            // The createdOn value for the Access Key is useful for determining which Access/Secret keys are old and need to be rotated.
            application.awsResources.iam.PlayboxUserAccessKeyCreatedOn = accesKeyInfo.getCreateDate();   
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "rotateAccessKeys")>
	<cfscript>
        if (NOT structKeyExists(application.awsResources.iam, "PlayboxUserARN")) {
            errorMsg = "You first need to create a user for this demonstration.";
        } else {
            // A user can have more than one set of credentials in AWS. 
            // It's common practice to set the current set of credentials as "inactive"
            // and then assign a new set when you rotate access keys.
            // You would do that via an UpdateAccessKeyRequest.
            // Here, we're simply deleting the old and creating a new one.
            // You should use the createdOn value on your access keys to determine
            // which ones are old and should be rotated.
            deleteAccessKeyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeleteAccessKeyRequest')
                .withUserName(application.awsResources.iam.PlayboxUserName)
                .withAccessKeyID(application.awsResources.iam.PlayboxUserAccessKeyID);
            // The deleteAccessKey method doesn't really return anything useful in the result object. It either succeeds or fails.
            deleteAccessKey = iam.deleteAccessKey(deleteAccessKeyRequest);
            // Now make a new access key for this user
            createAccessKeyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.CreateAccessKeyRequest')
                .withUserName(application.awsResources.iam.PlayboxUserName);
            createAccessKeyResult = iam.createAccessKey(createAccessKeyRequest);
            accesKeyInfo = createAccessKeyResult.getAccessKey();
            application.awsResources.iam.PlayboxUserAccessKeyID = accesKeyInfo.getAccessKeyID();
            application.awsResources.iam.PlayboxUserSecretKey = accesKeyInfo.getSecretAccessKey();
            application.awsResources.iam.PlayboxUserAccessKeyStatus = accesKeyInfo.getStatus();
            application.awsResources.iam.PlayboxUserAccessKeyCreatedOn = accesKeyInfo.getCreateDate();
            accessKeysRotated = 1;
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "deleteCurrentIAMResources")>
	<cfscript>
        if (structKeyExists(application.awsResources.iam, "PlayboxUserARN")) {
            // Before you can delete the user, you have to:
            // 1. Delete all access keys
            //   a. To do this with multiple access keys on an account, you have to first request all keys via 
            //      a ListAccessKeysRequest, then loop through the result, deleting each key as you go.
            // 2. Remove a user from all groups
            deleteAccessKeyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeleteAccessKeyRequest')
                .withUserName(application.awsResources.iam.PlayboxUserName)
                .withAccessKeyID(application.awsResources.iam.PlayboxUserAccessKeyID);
            deleteAccessKey = iam.deleteAccessKey(deleteAccessKeyRequest);
            removeUserFromGroupRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.RemoveUserFromGroupRequest')
                .withGroupName(application.awsResources.iam.PlayboxGroupName)
                .withUserName(application.awsResources.iam.PlayboxUserName);
            removeUserFromGroup = iam.removeUserFromGroup(removeUserFromGroupRequest);
            deleteUserRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeleteUserRequest')
                .withUserName(application.awsResources.iam.PlayboxUserName);
            deleteUserResult = iam.deleteUser(deleteUserRequest);
        }
        if (structKeyExists(application.awsResources.iam, "PlayboxGroupARN")) {
            // Before you can delete a group, you have to detach all policies associated with that group
            detachGroupPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DetachGroupPolicyRequest')
                .withPolicyArn(application.awsResources.iam.S3PolicyARN)
                .withGroupName(application.awsResources.iam.PlayboxGroupName);
            detachGroupPolicyResult = iam.detachGroupPolicy(detachGroupPolicyRequest);
            detachGroupPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DetachGroupPolicyRequest')
                .withPolicyArn(application.awsResources.iam.SNSPolicyARN)
                .withGroupName(application.awsResources.iam.PlayboxGroupName);
            detachGroupPolicyResult = iam.detachGroupPolicy(detachGroupPolicyRequest);
            deleteGroupRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeleteGroupRequest')
                .withGroupName(application.awsResources.iam.PlayboxGroupName);
            deleteGroupResult = iam.deleteGroup(deleteGroupRequest);
        }
        if (structKeyExists(application.awsResources.iam, "S3PolicyARN")) {
            deleteS3PolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeletePolicyRequest')
                .withPolicyArn(application.awsResources.iam.S3PolicyARN);
            deleteS3PolicyResult = iam.deletePolicy(deleteS3PolicyRequest);
        } 
        if (structKeyExists(application.awsResources.iam, "SNSPolicyARN")) {
            deleteSNSPolicyRequest = CreateObject('java', 'com.amazonaws.services.identitymanagement.model.DeletePolicyRequest')
                .withPolicyArn(application.awsResources.iam.SNSPolicyARN);
            deleteSNSPolicyResult = iam.deletePolicy(deleteSNSPolicyRequest);
        }
        application.awsResources.iam = {};
        errorMsg = "All current IAM resources have been deleted.";
    </cfscript>
</cfif>

<cfscript>
    stepsDone = {};
    stepsDone.createS3Policy = (structKeyExists(application.awsResources.iam, "S3PolicyARN")) ? 1 : 0;
    stepsDone.createSNSPolicy = (structKeyExists(application.awsResources.iam, "SNSPolicyARN")) ? 1 : 0;
    stepsDone.createPlayboxGroup = (structKeyExists(application.awsResources.iam, "PlayboxGroupName")) ? 1 : 0;
    stepsDone.createPlayboxUser = (structKeyExists(application.awsResources.iam, "PlayboxUserARN")) ? 1 : 0;
</cfscript>

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
				<h1>Identity Access Management (IAM)</h1>
                <p>Basic IAM Workflow:</p>
                <ul>
                    <li>Create policies</li>
                    <li>Make groups to follow those policies</li>
                    <li>Create users and add them to those groups to acccess resources in AWS</li>
                    <li>Rotate user access keys on a regular basis</li>
                </ul>
                
                <cfif Len(errorMsg) GT 1>
                    <p class="errorBox"><cfoutput>#errorMsg#</cfoutput></p>
                </cfif>

                <h3>Policies</h3>
                <ol class="paddedList">
                    <li>
                        <cfif stepsDone.createS3Policy>&#x2705; </cfif>Create policy with read/write permission to "awsPlayboxPrivate" S3 bucket. 
                        <cfif NOT stepsDone.createS3Policy> 
                            &nbsp; <a href="iam.cfm?createS3Policy" class="doItButton">Do It</a>
                        <cfelse>
                            <ul style="font-size:14px;">
                                <cfoutput>
                                    <li><b>Policy Name:</b> #application.awsResources.iam.S3PolicyName#</li>
                                    <li><b>Policy ARN:</b> #application.awsResources.iam.S3PolicyARN#</li>
                                </cfoutput>
                            </ul>
                        </cfif>
                        </li>
                    <li>
                        <cfif stepsDone.createSNSPolicy>&#x2705; </cfif>Create policy to allow sending of messages to the SNS topic created on the SNS page.
                        <cfif NOT Len(Trim(application.awsResources.currentSNSTopicARN))>
                            <br><br><a href="sns.cfm">Go to the SNS page</a> and create a topic first.
                        <cfelse>
                            <cfif NOT stepsDone.createSNSPolicy>
                                &nbsp; <a href="iam.cfm?createSNSPolicy" class="doItButton">Do It</a>
                                <ul style="font-size:14px;">
                                    <cfoutput>
                                        <li><b>SNS Topic ARN:</b> #application.awsResources.currentSNSTopicARN#</li>
                                    </cfoutput>
                                </ul>
                            <cfelse>
                                <ul style="font-size:14px;">
                                    <cfoutput>
                                        <li><b>Policy Name:</b> #application.awsResources.iam.SNSPolicyName#</li>
                                        <li><b>Policy ARN:</b> #application.awsResources.iam.SNSPolicyARN#</li>
                                    </cfoutput>
                                </ul>
                            </cfif>
                        </cfif>
                    </li>
                </ol>
                <h3>Groups</h3>
                <ol class="paddedList" start="3">
                    <li>
                        <cfif stepsDone.createPlayboxGroup>&#x2705; </cfif>Create group to utilize the S3 and SNS policies, above.
                        <cfif NOT stepsDone.createPlayboxGroup>
                            &nbsp; <a href="iam.cfm?createGroupWithPolicies" class="doItButton">Do It</a>
                        <cfelse>
                            <ul style="font-size:14px;">
                                <cfoutput>
                                    <li><b>Group Name:</b> #application.awsResources.iam.PlayboxGroupName#</li>
                                    <li><b>Group ARN:</b> #application.awsResources.iam.PlayboxGroupARN#</li>
                                </cfoutput>
                            </ul>
                        </cfif>
                    </li>
                </ol>
                <h3>Users</h3>
                <ol class="paddedList" start="4">
                    <li>
                        <cfif stepsDone.createPlayboxUser>&#x2705; </cfif>Create user to access resources using the AWS Playbox group, above.
                        <cfif NOT stepsDone.createPlayboxUser>
                            &nbsp; <a href="iam.cfm?createUserInAwsPlayboxGroup" class="doItButton">Do It</a>
                        <cfelse>
                            <ul style="font-size:14px;">
                                <cfoutput>
                                    <li><b>User Name:</b> #application.awsResources.iam.PlayboxUserName#</li>
                                    <li><b>User ARN:</b> #application.awsResources.iam.PlayboxUserARN#</li>
                                    <li><b>User Access Key:</b> #application.awsResources.iam.PlayboxUserAccessKeyID#</li>
                                    <li><b>User Secret Key:</b> #application.awsResources.iam.PlayboxUserSecretKey#</li>
                                    <li><b>User Access Key Status:</b> #application.awsResources.iam.PlayboxUserAccessKeyStatus#</li>
                                    <li><b>User Access Key Created On:</b> #DateTimeFormat(application.awsResources.iam.PlayboxUserAccessKeyCreatedOn,"yyyy-mm-dd HH:nn:ss")#</li>
                                </cfoutput>
                            </ul>
                        </cfif>
                    </li>
                    <li>
                        Rotate access keys of AWS Playbox user, above.
                        <cfif stepsDone.createPlayboxUser>
                            &nbsp; <a href="iam.cfm?rotateAccessKeys" class="doItButton">Do It</a>
                        </cfif>
                        <cfif accessKeysRotated>
                            <ul style="font-size:14px;">
                                <cfoutput>
                                    <li>Access keys successfully rotated, and are listed above.</li>
                                </cfoutput>
                            </ul>
                        </cfif>
                    </li>
                </ol>
                <p>&nbsp;</p>
                <p><b><a href="iam.cfm?deleteCurrentIAMResources">Delete</a></b> all of these IAM resources.</p>
                <p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>
	</body>
</html>