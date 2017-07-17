/*
DynamoDB Item Maker

This component creates DynamoDB Item objects with randomized attributes.

Author: Brian Klaas (bklaas@jhu.edu)
(c) 2017, The Johns Hopkins Bloomberg School of Public Health Center for Teaching and Learning

*/

component output="false" hint="A utility for creating random DynamoDB items." {

	/**
	*	@description Component initialization
	*/
	public any function init() {
		variables.possibleEvents = ['quiz.setTempAnswer','quiz.updateTempAnswer','quiz.deleteTempAnswer'];
		return this;
	}

	/**
	*	@description Creates a DynamoDB Item object with randomized attributes
	*	@requiredArguments
	*		- serviceName = Name of the service we want to use
	*/
	public any function makeItem() {
		var itemObject = CreateObject('java', 'com.amazonaws.services.dynamodbv2.document.Item').init();
		itemObject.withPrimaryKey('userID', JavaCast('string',RandRange(100,1000)), 'epochTime', JavaCast('long',Now().getTime()));
		itemObject.withNumber('courseOfferingID', JavaCast('int',RandRange(50,250)));
		itemObject.withString('event', variables.possibleEvents[RandRange(1,ArrayLen(variables.possibleEvents))]);
		if(RandRange(1,10) LTE 5) {
			var params = {'quizID':RandRange(25,75), 'questionID':RandRange(5000,9000), 'answerID':RandRange(10000,15000)};
			itemObject.withMap('params',params);
		}
		if(RandRange(1,10) LTE 2) {
			itemObject.withBoolean('leavePage', JavaCast('boolean', true));
		}
		return itemObject;
	}

}