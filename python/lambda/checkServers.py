import boto3
from datetime import datetime
from urllib2 import urlopen

snsClient = boto3.client('sns')
# The ARN of the SNS topic you want to notify in case of failure goes here. You need to set up this SNS topic.
topicARN = 'YOUR_ARN_GOES_HERE'

# URLs of the sites to check
SITES = ['http://yoursite.com/heartbeat.txt']
# String expected to be returned from the request
EXPECTED = 'This server is healthy'  

def validate(res):
    '''Return False to trigger a SNS message.
    Could modify this to perform any number of arbitrary checks on the contents of SITE.
    '''
    return EXPECTED in res


def lambda_handler(event, context):
    for site in SITES:
        print('Checking {} at {}...'.format(site, event['time']))
        try:
            if not validate(urlopen(site).read()):
                raise Exception('Validation failed')
        except:
            print('Check failed!')
            messageSubject = 'Site Check Scheduled Lambda Function Failed to Reach ' + site
            message = 'Failure reported at ' + event['time']
            snsClient.publish(TopicArn=topicARN, Message=message, Subject=messageSubject)
        else:
            print('Check passed!')
    
    return event['time']
