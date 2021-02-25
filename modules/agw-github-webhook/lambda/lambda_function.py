import json
import hmac
import hashlib
import logging
import boto3

log = logging.getLogger(__name__)

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
     
    try:
        clone_url = parsed_payload['repository']['clone_url']
    except Exception:
        log.error('payload does not have a repository.clone_url attribute')
        return {
            "statusCode": 400,
            "body": json.dumps({'error': 'payload does not have a repository.clone_url attribute'})
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('Request was successful')
    }

def validate_sig(header_sig, payload):
    
    sha, sig = header_sig.split('=')
    if sha != 'sha256':
        log.error('Signature not signed with sha256')
        return False

    ssm = boto3.client('ssm')
    git_secret = ssm.get_parameter(Name='github-webhook-auth-secret', WithDecryption=True)['Parameter']['Value']
    expected_sig = hmac.new(bytes(git_secret, 'utf-8'), bytes(payload, 'utf-8'), hashlib.sha256).hexdigest()
    
    authorized = hmac.compare_digest(str(sig), str(expected_sig))
    
    if not authorized:
       log.error('Header signature and expected signature do not match')

    return authorized
