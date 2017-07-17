import boto.sns
import logging

logging.basicConfig(filename="subscribeViaEmail.log", level=logging.DEBUG)

snsConnection = boto.sns.connect_to_region("us-east-1")

topicARN = "YOUR TOPIC ARN GOES HERE"
emailAddress = "YOUR EMAIL ADDRESS GOES HERE"

subscription = snsConnection.subscribe(topicARN, "email", emailAddress)

print subscription