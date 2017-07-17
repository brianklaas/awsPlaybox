import boto.sns
from datetime import datetime
import logging

logging.basicConfig(filename="publishToSNS.log", level=logging.DEBUG)

now = datetime.now()

snsConnection = boto.sns.connect_to_region("us-east-1")

topicARN = "YOUR TOPIC ARN GOES HERE"
message = "Did you know that today is " + now.strftime("%A %B %d, %Y") + "?"
# Note that in SMS messages, all you send is the subject, which must be less than 100 characters
message_subject = "Hello from Python at " + now.strftime("%-I:%M%p") + "!"

result = snsConnection.publish(topicARN, message, subject=message_subject)

print result