<cfset dynamoResult = "" />

<cfif structKeyExists(URL, "goDynamo")>
	<cfscript>
	dynamoDB = application.awsServiceFactory.createServiceObject('dynamoDB');

	switch(lcase(trim(URL.goDynamo))){
		case 'listTables':
			dynamoResult = dynamoDB.listTables();
			break;

		case 'putItem':
			table = CreateObject('java', 'com.amazonaws.services.dynamodbv2.document.Table').init(dynamoDB, application.awsResources.dynamoDBTableName);

			// This is just a convenience method for this demo. You can build your DynamoDB Item objects any way you want.
			itemMaker = CreateObject('component','awsPlaybox.model.dynamoItemMaker').init();

			for (i=1; i LTE 5; i++) {
				item = itemMaker.makeItem();
				outcome = table.putItem(item);
			}

			dynamoResult = item.toJSONPretty();
			break;

		// This is cfscript's way of dealing with mulitiple matching values for the same block
		case 'scanTable': case 'scanTableFilter':
			scanRequest = CreateObject('java', 'com.amazonaws.services.dynamodbv2.model.ScanRequest').init(application.awsResources.dynamoDBTableName);

			if (URL.goDynamo IS 'scanTableFilter') {
				// Although the value is a number, the dynamoAttributeValue.withN function requires a string to be passed in.
				filterBackTo = JavaCast('string',DateAdd('n', -1, Now()).getTime());
				// For more information on table scan filtering, see http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ScanJavaDocumentAPI.html
				dynamoAttributeValue = CreateObject('java', 'com.amazonaws.services.dynamodbv2.model.AttributeValue').init();
				attributeValuesStruct = {':filterBackTo'=dynamoAttributeValue.withN(filterBackTo)};
				scanRequest.withFilterExpression('epochTime > :filterBackTo');
				scanRequest.withExpressionAttributeValues(attributeValuesStruct);
			}

			scanResult = dynamoDB.scan(scanRequest);

			if (arrayLen(scanResult.items) GT 0) {
				scanResult.items.each(function(element,index) {
					dynamoResult &= element.toString() & '<br><br>';
				});
			} else {
				dynamoResult = "No records returned from the scan.";
			}
			break;

		default:
			throw(message="Unsupported action requested", detail="You have requested an action (#URL.goDynamo#) which is not supported at this time.");
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
				<h1>DynamoDB</h1>

				<cfif Len(dynamoResult)>
					<p>You said: <cfoutput>#URL.goDynamo#</cfoutput>
					<p><strong>Your Result:</strong><br/>
					<cfoutput>#dynamoResult#</cfoutput></p>
				</cfif>


				<p><a href="dynamodb.cfm?goDynamo=listTables">List Tables</a></p>
				<p><a href="dynamodb.cfm?goDynamo=putItem">Put Items</a></p>
				<p><a href="dynamodb.cfm?goDynamo=scanTable">Scan Table</a></p>
				<p><a href="dynamodb.cfm?goDynamo=scanTableFilter">Scan Table for Records in the Last Minute</a></p>
				<p align="right" ><a href="index.cfm" class="homeButton">Home</a></p>
			</div>
		</div>
	</body>
</html>