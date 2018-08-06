<cfset rekogFunctionResult = "" />

<!--- Put the URLs to your images in S3 here --->
<cfset s3images = structNew()>
<cfset s3images.awsBucketName = "YOUR BUCKET NAME GOES HERE" />
<cfset s3images.facesForMatching = [ "ARRAY","OF","PATHS","TO","IMAGES","IN","THE","BUCKET","LISTED","ABOVE" ] />
<cfset s3images.imagesForLabels = [ "ARRAY","OF","PATHS","TO","IMAGES","IN","THE","BUCKET","LISTED","ABOVE" ] />
<cfset s3images.imagesWithText = [ "ARRAY","OF","PATHS","TO","IMAGES","IN","THE","BUCKET","LISTED","ABOVE" ] />

<cfif structKeyExists(URL, "rekogRequest")>
	<cfscript>
		rekognitionLib = CreateObject('component', 'awsPlaybox.model.rekognitionLib').init();
		switch(trim(URL.rekogRequest)){
			case 'compareFaces':
				sourceImage = s3images.facesForMatching[randRange(1, arrayLen(s3images.facesForMatching))];
				targetImage = s3images.facesForMatching[randRange(1, arrayLen(s3images.facesForMatching))];
				compareFacesResult = rekognitionLib.compareFaces(s3images.awsBucketName, sourceImage, targetImage);
				similarityValue = rekognitionLib.getSimilarityValue(compareFacesResult);
				if (similarityValue gte 0) {
					rekogFunctionResult = "Rekognition gave a similarity value of " & similarityValue & " to the two images.";
				} else {
					rekogFunctionResult = "There was no match between the two images!";
				}
				break;

			case 'detectLabels':
				sourceImage = s3images.imagesForLabels[randRange(1, arrayLen(s3images.imagesForLabels))];
				getImageLabelsResult = rekognitionLib.getImageLabels(s3images.awsBucketName, sourceImage);
				break;

			case 'detectSentiment':
				sourceImage = s3images.facesForMatching[randRange(1, arrayLen(s3images.facesForMatching))];
				detectSentimentResult = rekognitionLib.detectSentiment(s3images.awsBucketName, sourceImage);
				break;

			case 'detectText':
				sourceImage = s3images.imagesWithText[randRange(1, arrayLen(s3images.imagesWithText))];
				detectTextResult = rekognitionLib.detectText(s3images.awsBucketName, sourceImage);
				break;

			default:
				throw(message="Unsupported service requested", detail="You have requested a method (#URL.rekogRequest#) which is not supported at this time.");
				break;
		}
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
				<h1>Rekognition</h1>

				<cfif structKeyExists(URL, "rekogRequest")>
					<cfswitch expression="#trim(URL.rekogRequest)#">
						<cfcase value="compareFaces">
							<cfoutput>
								<p>#rekogFunctionResult#</p>
								<p>Here are the two images used:</p>
								<p>
									<img src="http://#s3images.awsBucketName#.s3.amazonaws.com/#sourceImage#" width="300" height="300" border="1" />
									<img src="http://#s3images.awsBucketName#.s3.amazonaws.com/#targetImage#" width="300" height="300" border="1" />
								</p>
							</cfoutput>
						</cfcase>
						<cfcase value="detectLabels">
							<cfoutput>
								<div>
									<div style="width:50%; float:left;">
										<p>Here is the image used:</p>
										<p>
											<img src="http://#s3images.awsBucketName#.s3.amazonaws.com/#sourceImage#" width="450" height="350" border="1" />
										</p>
									</div>
									<div style="width:50%; float:right;">
										<p>Here are the labels:</p>
										<cfloop array="#getImageLabelsResult#" index="idxThisLabel">
											<li>#idxThisLabel.label# &mdash; #idxThisLabel.confidence#%</li>
										</cfloop>
									</div>
								</div>
								<br clear="all">
							</cfoutput>
						</cfcase>
						<cfcase value="detectSentiment">
							<cfoutput>
								<div>
									<div style="width:50%; float:left;">
										<p>Here is the image used:</p>
										<p>
											<img src="http://#s3images.awsBucketName#.s3.amazonaws.com/#sourceImage#" width="450" height="350" border="1" />
										</p>
									</div>
									<div style="width:50%; float:right;">
										<cfset faceCounter = 0>
										<cfloop array="#detectSentimentResult#" index="idxThisFaceInfo">
											<cfset faceCounter++>
											<p>Face #faceCounter#:</p>
											<cfdump var="#idxThisFaceInfo#">
										</cfloop>
									</div>
								</div>
								<br clear="all">
							</cfoutput>
						</cfcase>
						<cfcase value="detectText">
							<cfoutput>
								<div>
									<div style="width:50%; float:left;">
										<p>Here is the image used:</p>
										<p>
											<img src="http://#s3images.awsBucketName#.s3.amazonaws.com/#sourceImage#" width="450" height="350" border="1" />
										</p>
									</div>
									<div style="width:50%; float:right;">
										<p>Lines of text:</p>
										<cfloop array="#detectTextResult.lines#" index="idxThisLine">
											#idxThisLine.id# | #idxThisLine.label# | (#idxThisLine.confidence#%)<br/>
										</cfloop>
										<p>Individual words:</p>
										<cfloop array="#detectTextResult.words#" index="idxThisWord">
											Line: #idxThisWord.parentID# &mdash; #idxThisWord.label# (#idxThisWord.confidence#%)<br/>
										</cfloop>
									</div>
								</div>
								<br clear="all">
							</cfoutput>
						</cfcase>
					</cfswitch>
				</cfif> <!--- End if a Rekognition request was made --->

				<p><a href="rekognition.cfm?rekogRequest=compareFaces">Compare Two Faces</a></p>
				<p><a href="rekognition.cfm?rekogRequest=detectLabels">Label the Properties of an Image</a></p>
				<p><a href="rekognition.cfm?rekogRequest=detectSentiment">Detect Facial Sentiment of an Image</a></p>
				<p><a href="rekognition.cfm?rekogRequest=detectText">Detect Text in an Image</a></p>

				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>
		
	</body>
</html>