<cfset transcribeJobResult = StructNew() />

<cfif structKeyExists(FORM, "pathToFileOnS3")>
    <cfscript>
        // Although Transcribe supports FLAC, WAV, MP3 and MP4 files, this demo only handles MP3 or MP4.
        fileExtension = listLast(Trim(FORM.pathToFileOnS3), ".");
        if (NOT listFindNoCase("MP3,MP4", fileExtension)) {
            writeOutput('Unsupported fileExtension: ' & fileExtension);
            abort;
        }

		// The AWS Service Factory, created at application startup, handles the building of the object that will speak to
		// the Transcribe service, and handles authentication to AWS.
		transcribeService = application.awsServiceFactory.createServiceObject('transcribe');

        // Each job in Transcribe for your account must have a unique name
        jobName = "AWSPlayboxTranscribeJob" & DateDiff("s", DateConvert("utc2Local", "January 1 1970 00:00"), now());

        // Unlike most basic properties of a Transcribe job, the path to the file has to be put into its own Media object
        s3MediaObject = CreateObject('java', 'com.amazonaws.services.transcribe.model.Media').init();
        s3MediaObject.setMediaFileUri(Trim(FORM.pathToFileOnS3));

        // Transcribe job settings allow you to specify custom dictionaries, identify multiple speakers, and more. 
        // https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/transcribe/model/Settings.html
        // Here we are enabling settings to identify up to five multiple speakers for all our jobs.
        transcribeJobSettings = CreateObject('java', 'com.amazonaws.services.transcribe.model.Settings').init();
        transcribeJobSettings.setShowSpeakerLabels(true);
        transcribeJobSettings.setMaxSpeakerLabels(5);

        startTranscriptionJobRequest = CreateObject('java', 'com.amazonaws.services.transcribe.model.StartTranscriptionJobRequest').init();
        startTranscriptionJobRequest.setTranscriptionJobName(jobName);
        startTranscriptionJobRequest.setMedia(s3MediaObject);
        startTranscriptionJobRequest.setMediaFormat(fileExtension);
        startTranscriptionJobRequest.setSettings(transcribeJobSettings);
        // This demo assumes that the audio is in English-US (en-US). As of Aug, 2018, Transcribe also supports Spanish-US (es-US).
        startTranscriptionJobRequest.setLanguageCode('en-US');

        // When we start an execution of Transcribe job, we get a start job result object back.
		// Job result object is of type com.amazonaws.services.transcribe.model.StartTranscriptionJobResult
		startTranscriptionJobResult = transcribeService.startTranscriptionJob(startTranscriptionJobRequest);
		transcriptionJob = startTranscriptionJobResult.getTranscriptionJob();

		jobInfo = { 
			jobName=jobName, 
			timeStarted=Now() 
		};
        
        // Here we add the information about current executions to memory so we can retrieve them as needed. 
        // In a real app, you'd want to save this to database.
		arrayAppend(application.currentTranscribeJobs, jobInfo);
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "checkTranscribeJob")>
	<cfscript>
		transcribeService = application.awsServiceFactory.createServiceObject('transcribe');
        deleteJob = 0;

        // In order to get information on any given transcript job, we have to make a getTranscriptionJobRequest
        getTranscriptionJobRequest = CreateObject('java', 'com.amazonaws.services.transcribe.model.GetTranscriptionJobRequest').init();
		getTranscriptionJobRequest.setTranscriptionJobName(URL.checkTranscribeJob);

        getTranscriptionJobResult = transcribeService.getTranscriptionJob(getTranscriptionJobRequest);
        // The getTranscriptionJobResult object has its own method called getTranscriptionJob. Confusing, no?
        transcriptJob = getTranscriptionJobResult.getTranscriptionJob();

        transcribeJobResult.status = transcriptJob.getTranscriptionJobStatus();
        transcribeJobResult.jobName = transcriptJob.getTranscriptionJobName();
        transcribeJobResult.createdOn = transcriptJob.getCreationTime();
        transcribeJobResult.sourceMediaUri = transcriptJob.getMedia().getMediaFileUri();
        // Possible results for the job status are Completed, Failed, and In_Progress.
        // A production application would would handle error results and schedule in progress tasks for checking again at a later time.
		if (transcribeJobResult.status IS "COMPLETED") {
            transcribeJobResult.finishedOn = transcriptJob.getCompletionTime();
            // The URI location of the transcription output is in a Transcript object returned from the getTranscript method.
            transcribeJobResult.transcriptUri = transcriptJob.getTranscript().getTranscriptFileUri();
            deleteJob = 1;
        } else if (transcribeJobResult.status IS "FAILED") {
            transcribeJobResult.failureReason = transcriptJob.getFailureReason();
            deleteJob = 1;
        }
        if (deleteJob eq 1) {
            application.currentTranscribeJobs.each(function(element, index) {
				if (element.jobName IS URL.checkTranscribeJob) {
					arrayDeleteAt(application.currentTranscribeJobs, index);
					break;
				}
			});
        }
    </cfscript>
</cfif>

<cfif structKeyExists(URL, "getTranscriptText")>
	<cfscript>
        // See the comments for checkTranscribeJob, above, for what this all does.
        transcribeService = application.awsServiceFactory.createServiceObject('transcribe');
        getTranscriptionJobRequest = CreateObject('java', 'com.amazonaws.services.transcribe.model.GetTranscriptionJobRequest').init();
		getTranscriptionJobRequest.setTranscriptionJobName(URL.getTranscriptText);
        getTranscriptionJobResult = transcribeService.getTranscriptionJob(getTranscriptionJobRequest);
        transcriptJob = getTranscriptionJobResult.getTranscriptionJob();
        transcriptUri = transcriptJob.getTranscript().getTranscriptFileUri();

        // Read in the transcript file and pull out just the transcript text
        cfhttp(method="GET", charset="utf-8", url="#transcriptUri#", result="transcriptFile");
        transcriptFileAsJSON = deserializeJSON(transcriptFile.fileContent, false);
        // The JSON result file contains four properties: accountID, jobName, results, and status.
        transcriptData = transcriptFileAsJSON.results;
        // Withn the results property, there are three properties: items, speaker labels, and transcripts.
        // Items are the indivdiual words in the transcript and the exact time each word appears. Useful for making captions.
        // The transcripts property is an array and, at this time, will only contain a single member, a property labeled: transcript.
        transcriptText = transcriptData.transcripts[1].transcript;
        cfheader(name="Content-Disposition", value="inline; fileName=#URL.getTranscriptText#.txt");
        writeDump(transcriptText);
        abort;
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
				<h1>Transcribe</h1>

                <cfif structKeyExists(URL, "checkTranscribeJob")>
					<p>Result of Transcribe job check:</p>
					<cfoutput>
                        <p>Job Name: #transcribeJobResult.jobName#</p>
                        <p>Source Media: #transcribeJobResult.sourceMediaUri#</p>
                        <p>Created On: #DateTimeFormat(transcribeJobResult.createdOn, "long")#</p>
                        <p>Status: <strong>#transcribeJobResult.status#</strong></p>
						<cfif (transcribeJobResult.status IS "COMPLETED")>
							<p>Finished On: #DateTimeFormat(transcribeJobResult.finishedOn, "long")#</p>
							<p>Transcript file location: #transcribeJobResult.transcriptUri#</p>
                            <p><a href="#transcribeJobResult.transcriptUri#" download>Download the full transcript job output</a>
                            <br/><br/><a href="transcribe.cfm?getTranscriptText=#transcribeJobResult.jobName#" download>Download just the text transcript</a>
                            <!--- The link that Transcribe generates for output in the default, AWS-owned bucket is time stamped, and only valid for 5 minutes from when it was generated during the getTranscriptionJob request. --->
                            <br/><br/><small>Note: these links are only valid until #DateTimeFormat(DateAdd('n',5,now()), 'short')#</small></p>
						<cfelseif (transcribeJobResult.status IS "FAILED")>
                            <p>Reason for failure: #transcribeJobResult.failureReason#</p>
						</cfif>
					</cfoutput>
                    <hr noshade>
				</cfif>

                <cfif arrayLen(application.currentTranscribeJobs) GT 0>
                    <h3>Current Transcribe Jobs:</h3>
                    <cfoutput>
                        <ul>
                            <cfloop array="#application.currentTranscribeJobs#" index="item">
                                <li><a href="transcribe.cfm?checkTranscribeJob=#item.jobName#">Job: Started #DateTimeFormat(item.timeStarted, "long")#</a></li>
                            </cfloop>
                        </ul>
                     </cfoutput>
                </cfif>

                <h3>Start New Transcribe Job:</h3>
                <form action="transcribe.cfm" method="post">
					<p>Path to MP4 or MP3 file on S3: <input name="pathToFileOnS3" type="url" size="75"> &nbsp; <input type="submit">
                        <br/><small>Note: the file in S3 must be in the same region as where you are calling Transcribe.
                        <br/>The correct format for the path is: https://s3-&lt;aws-region&gt;.amazonaws.com/&lt;bucket-name&gt;/&lt;keyprefix&gt;/&lt;objectkey&gt;
                        <br/>For example: https://s3-us-east-1.amazonaws.com/examplebucket/mediafolder/example.mp4</small>
                    </p>
				</form>

				<p align="right"><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>