console.log('Loading function');

var aws = require('aws-sdk');
var s3 = new aws.S3({ apiVersion: '2006-03-01' });
var sns = new aws.SNS();
var topicARN = 'YOUR TOPIC ARN GOES HERE';

exports.handler = function(event, context) {

    // Get the object from the event and its file size
    var bucket = event.Records[0].s3.bucket.name;
    var fileName = event.Records[0].s3.object.key;
    var fileSize = event.Records[0].s3.object.size;

    // Notify SNS topic if the file is larger than 20MB
    if ( fileSize > 20480000) {
        console.log("Notifying SNS of large upload. File: " + fileName);
		var messageBody = 'File: ' + fileName + '\n\nSize: ' + fileSize;
		var params = {
			TopicArn: topicARN,
			Message: messageBody,
			Subject: 'File Exceeding Size Limits Put in Bucket ' + bucket
		};
		sns.publish(params, function(err, data) {
	        if (err) {
			  	console.log(err, err.stack);
			  	context.fail('Error on SNS publish');
			} else {
				console.log('Successfully sent a message to SNS. Result:');
				console.log(data);
				context.succeed('Published to SNS about large file.');
		    }
		});
    } else {
        context.succeed('No alert needed.');
    }
};