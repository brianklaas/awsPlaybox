<cfset successMsg = "">
<cfset resultData = "">

<!--- Basic: Uploading a file via the AWS Java SDK so you can use minimal S3 permissions in IAM, 
    rather than the maximal S3 permissions required by Adobe CF's built-in functionality. --->
<cfif structKeyExists(FORM, "s3BucketName") AND structKeyExists(FORM, "fileToPutOnS3")>
    <cfscript>
        s3 = application.awsServiceFactory.createServiceObject('s3');
        if ((Len(Trim(FORM.s3BucketName)) GT 1) && (Len(Trim(FORM.fileToPutOnS3)) GT 1)) {
            uploadedFile = fileUpload(getTempDirectory(), "form.fileToPutOnS3", " ", "makeunique");
            fileLocation = getTempDirectory() & uploadedFile.serverFile;
            // The AWS SDK putFileRequest object requires a Java file object in binary format
            fileContent = fileReadBinary(getTempDirectory() & uploadedFile.serverFile);
            // The method signature for storing a file with Server-Side Encryption requires a byte stream, not a standard Java file object
            if (structKeyExists(FORM, "useSSES3")) {
                objectMetadata = CreateObject('java', 'com.amazonaws.services.s3.model.ObjectMetadata').init();
                objectMetadata.setContentLength(ArrayLen(fileContent));
                objectMetadata.setSSEAlgorithm(ObjectMetadata.AES_256_SERVER_SIDE_ENCRYPTION);
                fileInputStream = CreateObject('java', 'java.io.ByteArrayInputStream').init(fileContent);
                putFileRequest = CreateObject('java', 'com.amazonaws.services.s3.model.PutObjectRequest').init(trim(FORM.s3BucketName), uploadedFile.serverFile, fileInputStream, objectMetadata);
            } else {
                javaFileObject = CreateObject('java', 'java.io.File').init(fileLocation);
                putFileRequest = CreateObject('java', 'com.amazonaws.services.s3.model.PutObjectRequest').init(trim(FORM.s3BucketName), uploadedFile.serverFile, javaFileObject);
            }
            if ((structKeyExists(FORM, "storageClass")) && (len(trim(FORM.storageClass)) gt 1)) {
                storageClassObj = CreateObject('java', 'com.amazonaws.services.s3.model.StorageClass');
                putFileRequest.setStorageClass(storageClassObj.valueOf(FORM.storageClass));
            }
            if ((structKeyExists(FORM, "tagKey")) && (structKeyExists(FORM, "tagValue"))) {
                tag = CreateObject('java', 'com.amazonaws.services.s3.model.Tag').init(FORM.tagKey, FORM.tagValue);
                fileTagging = CreateObject('java', 'com.amazonaws.services.s3.model.ObjectTagging').init([tag]);
                putFileRequest.setTagging(fileTagging);
            }
            s3.putObject(putFileRequest);
            successMsg = "The file was uploaded to the S3 bucket. ";
        }
    </cfscript>
</cfif>

<!--- Generate Time-Expiring, Signed URL to a Private File on S3 --->
<cfif structKeyExists(FORM, "s3BucketName") AND structKeyExists(FORM, "pathToFile")>
    <cfscript>
        credentialsConfig = CreateObject('component','awsPlaybox.model.awsCredentials').init();
        signingUtils = CreateObject("component", "awsPlaybox.model.s3RequestSigningUtils").init(credentialsConfig.accessKey, credentialsConfig.secretKey);
        signedURL = signingUtils.createSignedURL(s3BucketName=FORM.s3BucketName,objectKey=FORM.pathToFile);
        resultData = "Signed URL to s3://#FORM.s3BucketName#/#FORM.pathToFile# : <a href='#signedURL#'>#signedURL#</a>";
    </cfscript>
</cfif>

<!--- Update the Lifecycle Rules on a Bucket
    Note: When you add S3 Lifecycle configuration to a bucket, Amazon S3 replaces the bucket's current Lifecycle 
    configuration, if there is one. --->
<cfif structKeyExists(FORM, "s3BucketNameForLifecycle")>
    <cfscript>
        s3 = application.awsServiceFactory.createServiceObject('s3');
        // Only update configuration if a rule has been selected
        if ((structKeyExists(FORM, "moveTo1ZIAAfter30")) || (structKeyExists(FORM, "deleteAfter90"))) {
            bucketLifecycleConfig = CreateObject('java', 'com.amazonaws.services.s3.model.BucketLifecycleConfiguration').init();
            // Big thanks to Ben Nadel for documenting how to instantiate Java nested classes! 
            // https://www.bennadel.com/blog/1370-ask-ben-instantiating-nested-java-classes-in-coldfusion.htm
            rule = CreateObject('java', 'com.amazonaws.services.s3.model.BucketLifecycleConfiguration$Rule').init();
            ruleIDString = "";
            if (structKeyExists(FORM, "moveTo1ZIAAfter30")) {
                ruleIDString = "Move to One Zone Infrequent Access after 30 days";
                storageClassObj = CreateObject('java', 'com.amazonaws.services.s3.model.StorageClass');
                transition = CreateObject('java', 'com.amazonaws.services.s3.model.BucketLifecycleConfiguration$Transition').withDays(30).withStorageClass(storageClassObj.valueOf('OneZoneInfrequentAccess'));
                // setTransitions expects a Java List, which is just a CF array
                rule.setTransitions([transition]);
            }
            if (structKeyExists(FORM, "deleteAfter90")) {
                if (len(ruleIDString)) {
                    ruleIDString &= " and delete file after 90 days";
                } else {
                    ruleIDString = "Delete file after 90 days";
                }
                rule.setExpirationInDays(90);
            }
            rule.setId(ruleIDString);
            rule.setStatus(bucketLifecycleConfig.ENABLED);
            bucketLifecycleConfig.setRules([rule]);
            s3.setBucketLifecycleConfiguration(FORM.s3BucketNameForLifecycle, bucketLifecycleConfig);
        }
        if (structKeyExists(FORM, "deleteLifecycleConfig")) {
            s3.deleteBucketLifecycleConfiguration(FORM.s3BucketNameForLifecycle);
        }
        // Get the current bucket lifecycle rules for display
        // This information sometimes gets cached by AWS, so that's why we sleep
        sleep(500);
        lifecycleConfigResult = s3.getBucketLifecycleConfiguration(FORM.s3BucketNameForLifecycle);
        if (NOT isNull(lifecycleConfigResult)) {
            rulesOnBucket = lifecycleConfigResult.getRules();
            if (arrayLen(rulesOnBucket)) {
                ruleListString = "<ul>";
                rulesOnBucket.each(function(item) {
                    ruleListString &= "<li>" & item.getId() & "</li>";
                });
                ruleListString &= "</ul>";
            }
            resultData = "Lifecycle rules on the #FORM.s3BucketNameForLifecycle# bucket: " & ruleListString;
        } else {
        resultData = "There are no lifecycle rules on the #FORM.s3BucketNameForLifecycle# bucket.";
        }
    </cfscript>
 </cfif>

<!--- Bucket versioning --->
<cfif structKeyExists(FORM, "s3BucketNameForVersioning")>
    <cfscript>
        s3 = application.awsServiceFactory.createServiceObject('s3');
        // Once you enable versioning on a bucket, you can never set it to OFF. It must always be suspended.
        status = "Suspended";
        if (structKeyExists(FORM, "enableVersioning")) {
            status = "Enabled";     
        }
        bucketVersioningConfig = CreateObject('java', 'com.amazonaws.services.s3.model.BucketVersioningConfiguration').withStatus(status);
        bucketVersioningConfigRequest = CreateObject('java', 'com.amazonaws.services.s3.model.SetBucketVersioningConfigurationRequest').init(FORM.s3BucketNameForVersioning, bucketVersioningConfig);
        s3.setBucketVersioningConfiguration(bucketVersioningConfigRequest);
        bucketVersioning = s3.getBucketVersioningConfiguration(FORM.s3BucketNameForVersioning);
        successMsg = "Versioning on the #FORM.s3BucketNameForVersioning# bucket: " & bucketVersioning.getStatus();
    </cfscript>
</cfif>

<!--- Get versions of a file --->
<cfif structKeyExists(FORM, "s3BucketNameForFileVersions") && len(trim(FORM.pathToFileForVersioning) GT 3)>
    <cfscript>
        s3 = application.awsServiceFactory.createServiceObject('s3');
        // We'll only retrieve the 5 most recent versions of the file
        listVersionsRequest = CreateObject('java', 'com.amazonaws.services.s3.model.ListVersionsRequest').withBucketName(FORM.s3BucketNameForFileVersions).withPrefix(trim(FORM.pathToFileForVersioning)).withMaxResults(5);
        versionsResult = s3.listVersions(listVersionsRequest);
        summariesArray = versionsResult.getVersionSummaries();
        summariesArray.each(function(objectSummary) {
            resultData &= "Key: " & objectSummary.getKey() & ", versionID: " & objectSummary.getVersionId() & "<br>";
        });
    </cfscript>
</cfif>

<!--- Get file tags --->
<cfif structKeyExists(FORM, "s3BucketNameForFileTags") && len(trim(FORM.pathToFileForTags) GT 3)>
    <cfscript>
        s3 = application.awsServiceFactory.createServiceObject('s3');
        taggingRequest = CreateObject('java', 'com.amazonaws.services.s3.model.GetObjectTaggingRequest').init(FORM.s3BucketNameForFileTags, FORM.pathToFileForTags);
        tagsResult = s3.getObjectTagging(taggingRequest);
        tagsArray = tagsResult.getTagSet();
        tagsArray.each(function(tag) {
            resultData &= "Key: " & tag.getKey() & ", Value: " & tag.getValue() & "<br>";
        });
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
				<h1>Simple Storage Service (S3)</h1>
                <cfif Len(successMsg) GT 1>
                    <p class="successBox"><cfoutput>#successMsg#</cfoutput></p>
                </cfif>
                <cfif Len(resultData) GT 1>
                    <div class="resultsBox"><p><cfoutput>#resultData#</cfoutput></p></div>
                </cfif>

                <hr noshade>
                <h3>Upload a File with the AWS Java SDK</h3>
                <p>This will bypass CFML tags and functions to upload the file to the specified destination bucket.</p>
                <form name="s3Upload" action="s3.cfm" method="post" enctype="multipart/form-data">
                    <p>
                        Enter the destination bucket name:
                        <input type="text" name="s3BucketName" size="30" <cfif structKeyExists(FORM, "s3BucketName") AND len(trim(FORM.s3BucketName)) GT 1>value="<cfoutput>#trim(FORM.s3BucketName)#</cfoutput>"</cfif>><br>
                        Select a file to upload: <input type="file" name="fileToPutOnS3"><br>
                        Use Server-Side Encryption with Amazon S3-Managed Keys: <input type="checkbox" name="useSSES3"><br>
                        Storage class: <select name="storageClass">
                            <option value="">S3 Standard</option>
                            <option value="IntelligentTiering">S3 Intelligent-Tiering</option>
                            <option value="StandardInfrequentAccess">S3 Standard-Infrequent Access (S3 Standard-IA)</option>
                            <option value="OneZoneInfrequentAccess">S3 One Zone-Infrequent Access (S3 One Zone-IA)</option>
                            <option value="Glacier">Amazon S3 Glacier (S3 Glacier)</option>
                            <option value="DeepArchive">Amazon S3 Glacier Deep Archive (S3 Glacier Deep Archive)</option>
                        </select><br>
                        With tags: Key: <input type="text" name="tagKey" size="20"> Value: <input type="text" name="tagValue" size="20"><br>
                        <input type="submit" value="Upload File to S3 Bucket">
                    </p>
                </form>
                <hr noshade>
                <h3>Create a Time-Expiring, Signed URL for a File on S3</h3>
                <form name="s3ExpiringURL" action="s3.cfm" method="post">
                    <p>
                        Enter the destination bucket name: 
                        <input type="text" name="s3BucketName" size="30" <cfif structKeyExists(FORM, "s3BucketName") AND len(trim(FORM.s3BucketName)) GT 1>value="<cfoutput>#trim(FORM.s3BucketName)#</cfoutput>"</cfif>><br>
                        Enter the path and file name in the bucket: <input type="text" name="pathToFile" size="30"><br>
                        <input type="submit" value="Generate Signed URL">
                    </p>
                </form>
                <hr noshade>
                <h3>Bucket Lifecycle Rules</h3>
                <form name="s3BucketLifecycle" action="s3.cfm" method="post">
                    <p>
                        Enter the target bucket name: 
                        <input type="text" name="s3BucketNameForLifecycle" size="30" <cfif structKeyExists(FORM, "s3BucketNameForLifecycle") AND len(trim(FORM.s3BucketNameForLifecycle)) GT 1>value="<cfoutput>#trim(FORM.s3BucketNameForLifecycle)#</cfoutput>"</cfif>><br>
                        <input type="checkbox" name="moveTo1ZIAAfter30">Move to S3 One Zone-Infrequent Access after 30 days<br>
                        <input type="checkbox" name="deleteAfter90">Delete file after 90 days<br>
                        OR:<br>
                        <input type="checkbox" name="deleteLifecycleConfig">Delete lifecycle configuration on bucket<br>
                        <input type="submit" value="Adjust Lifecycle Rule on This Bucket">
                    </p>
                </form>
                <hr noshade>
                <h3>Bucket Versioning</h3>
                <form name="s3BucketVersioning" action="s3.cfm" method="post">
                    <p>
                        Enter the bucket name: 
                        <input type="text" name="s3BucketNameForVersioning" size="30" <cfif structKeyExists(FORM, "s3BucketNameForVersioning") AND len(trim(FORM.s3BucketNameForVersioning)) GT 1>value="<cfoutput>#trim(FORM.s3BucketNameForVersioning)#</cfoutput>"</cfif>><br>
                        <input type="checkbox" name="enableVersioning">Enable versioning<br>
                        <input type="checkbox" name="disableVersioning">Disable versioning<br>
                        <input type="submit" value="Change Versioning">
                    </p>
                </form>
                <hr noshade>
                <h3>List Versions of a File</h3>
                <form name="s3FileVersions" action="s3.cfm" method="post">
                    <p>
                        Enter the destination bucket name: 
                        <input type="text" name="s3BucketNameForFileVersions" size="30" <cfif structKeyExists(FORM, "s3BucketNameForFileVersions") AND len(trim(FORM.s3BucketNameForFileVersions)) GT 1>value="<cfoutput>#trim(FORM.s3BucketNameForFileVersions)#</cfoutput>"</cfif>><br>
                        Enter the path and file name in the bucket: <input type="text" name="pathToFileForVersioning" size="30"><br>
                        <input type="submit" value="Get Versions of this File">
                    </p>
                </form>
                <hr noshade>
                <h3>List Tags on a File</h3>
                <form name="s3FileTags" action="s3.cfm" method="post">
                    <p>
                        Enter the destination bucket name: 
                        <input type="text" name="s3BucketNameForFileTags" size="30" <cfif structKeyExists(FORM, "s3BucketNameForFileTags") AND len(trim(FORM.s3BucketNameForFileTags)) GT 1>value="<cfoutput>#trim(FORM.s3BucketNameForFileTags)#</cfoutput>"</cfif>><br>
                        Enter the path and file name in the bucket: <input type="text" name="pathToFileForTags" size="30"><br>
                        <input type="submit" value="Get Tags for this File">
                    </p>
                </form>
                <hr noshade>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>