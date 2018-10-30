<cfset finalTranslation = "">

<cfif structKeyExists(FORM, "textToTranslate")>
    <cfscript>
        if (not(len(trim(FORM.targetLanguage))) or not(len(trim(FORM.textToTranslate)))) {
            writeOutput('You need to supply both a target language and text to translate.');
            abort;
        }

        // The AWS Service Factory, created at application startup, handles the building of the object that will speak to
		// the Translate service, and handles authentication to AWS.
		translateService = application.awsServiceFactory.createServiceObject('translate');

        // We can re-use the same TranslateJobRequest object when looping below, so we'll only create it once.
        translateJobRequest = CreateObject('java', 'com.amazonaws.services.translate.model.TranslateTextRequest').init();
        translateJobRequest.setSourceLanguageCode('en');
        translateJobRequest.setTargetLanguageCode(trim(FORM.targetLanguage));

        // Translate has a service limit of translating 5000 bytes of UTF-8 characters per request. 
        // We'll only translate 4900 characters at a time just to be safe.
        // Additionally, the service has a throttling limit of 10,000 bytes per 10 seconds per language pair (source/target language).
        // As such, we have to see how long our text is and then break it apart into chunks that will not go over these limits.
        // If you're looking for sample long text, try the full text of Herman Melville's Moby Dick: https://www.gutenberg.org/files/2701/2701-h/2701-h.htm
        trimmedSourceText = trim(FORM.textToTranslate);
        totalChunks = ceiling(len(trimmedSourceText) / 4900);
        totalPauses = ceiling(totalChunks / 2);
        currentEndPosition = 1;
        currentChunkCounter = 0;
        currentPauseCounter = 0;
        finalTranslation = "";

        for (currentChunkCounter = 1; currentChunkCounter <= totalChunks; currentChunkCounter++) {
            chunkToTranslate = mid(trimmedSourceText, currentEndPosition, 4900);
            currentEndPosition += 4900;

            // We don't want to cut words off in the middle, so let's adjust for that.
            if (len(chunkToTranslate) GTE 4900) {
                 lastWord = ListLast(chunkToTranslate, " ");
                 chunkToTranslate = left(chunkToTranslate, (len(chunkToTranslate) - len(lastWord)));
                 currentEndPosition -= len(lastWord);
            }

            // We can re-use the translateJobRequest object because the only thing we change from request to request is the text being translated.
            translateJobRequest.setText(chunkToTranslate);
            translateTextResult = translateService.translateText(translateJobRequest);
            // For more on the translateTextResult object see https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/translate/model/TranslateTextResult.html
            finalTranslation &= translateTextResult.getTranslatedText();

            // Check to see if we need to pause as to not exceed the 10,000 bytes per 10 seconds limit.
            if ((currentChunkCounter mod 2) eq 0) {
                if (currentPauseCounter LTE totalPauses) {
                    sleep(10000);
                    currentPauseCounter++;
                }
            }
         } // End totalChunks loop
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
				<h1>Translate</h1>

                <cfif Len(finalTranslation)>
                    <p><b>Translated Output:</b></p>
                    <p><cfoutput>#finalTranslation#</cfoutput></p>
                    <hr noshade>
                </cfif>

                <h3>Translate Some Text:</h3>
                <form action="translate.cfm" method="post">
                    <p>Translating from English to: 
                        <select name="targetLanguage">
                            <option value="ar">Arabic</option>
                            <option value="zh">Chinese (Simplified)</option>
                            <option value="zh-TW">Chinese (Traditional)</option>
                            <option value="cs">Czech</option>
                            <option value="fr">French</option>
                            <option value="de">German</option>
                            <option value="it">Italian</option>
                            <option value="ja">Japanese</option>
                            <option value="pt">Portuguese</option>
                            <option value="ru">Russian</option> 
                            <option value="es">Spanish</option>
                            <option value="tr">Turkish</option>
                        </select>
                    </p>
					<p>Text to translate: <br/>
                        <textarea name="textToTranslate" rows="5" cols="70" wrap="virtual"></textarea>
                    </p>
                    <p><input type="submit"></p>
				</form>

				<p align="right"><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>

	</body>
</html>