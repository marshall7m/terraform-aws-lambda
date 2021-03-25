import json
import hmac
import hashlib
import logging
import boto3
import os
import re

log = logging.getLogger(__name__)
ssm = boto3.client('ssm')
def lambda_handler(event, context):
    authorized = validate_sig(event['headers']['X-Hub-Signature-256'], event['body'])
    if not authorized:
        return {
            'statusCode': 403,
            'body': json.dumps({'error': 'signature is invalid'})
        }
    try:
        parsed_payload = json.loads(event['body'])
    except Exception:
        log.error('payload can not be decoded')
        return {
            "statusCode": 400,
            "body": json.dumps({'error': 'payload can not be decoded'})
        }

    return {
        'statusCode': 200,
        'body': json.dumps('Request is valid')
    }

def validate_sig(header_sig, payload):
    github_secret = ssm.get_parameter(Name=os.environ['GITHUB_WEBHOOK_SECRET_SSM_KEY'], WithDecryption=True)['Parameter']['Value']
    try:
        sha, sig = header_sig.split('=')
    except ValueError:
        log.error("Signature not signed with sha256 (e.g. sha256=123456)")
        return False

    if sha != 'sha256':
        log.error('Signature not signed with sha256 (e.g. sha256=123456)')
        return False

    expected_sig = hmac.new(bytes(github_secret, 'utf-8'), bytes(payload, 'utf-8'), hashlib.sha256).hexdigest()

    authorized = hmac.compare_digest(str(sig), str(expected_sig))

    if not authorized:
       log.error('Header signature and expected signature do not match')
    
    log.info('Header signature and expected signature match')
    
    return authorized