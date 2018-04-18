// This function simply translates variable names between the cfdemoTranslateText and cfDemoConvertTextToSpeech functions because Step Functions states language can't do that.

exports.handler = (event, context, callback) => {
    
    var textToSpeak = event.translatedText;
    var languageOfText = event.languageOfText;
    var transcriptFileName = event.sourceTranscriptFileName;
    
    var returnData = {
        textToSpeak: textToSpeak,
        languageOfText: languageOfText,
        transcriptFileName: transcriptFileName
    }
    
    callback(null, returnData);
};