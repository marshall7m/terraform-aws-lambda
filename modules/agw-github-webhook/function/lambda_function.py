import json
import hmac
import hashlib
import logging
import boto3
from github import Github
import os
import re

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
        clone_url = parsed_payload['pull_request']['base']['repo']['clone_url']
        base_sha = parsed_payload['pull_request']['base']['sha']
        head_sha = parsed_payload['pull_request']['head']['sha']
    except Exception:
        log.error('payload does not have a repository.clone_url attribute')
        return {
            "statusCode": 400,
            "body": json.dumps({'error': 'payload does not have a repository.clone_url attribute'})
        }
    trigger_pipeline = validate_pr(
        clone_url, 
        base_sha, 
        head_sha, 
        os.environ['path_filter']
    )

    if not trigger_pipeline:
        return {
            'statusCode': 403,
            'body': json.dumps(f'Pull request does not fulfill file path trigger filter: ${path_filter}')
        }
        
    try:
        response = cp.start
    except Exception:
        log.error(f'unable to trigger target CodePipeline: ${pipeline_name}')
        return {
            "statusCode": 500,
            "body": json.dumps({'error': f'unable to trigger target CodePipeline: ${pipeline_name}'})
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

# def validate_pr(repo_full_name, base_ref, head_ref, path_filter=""):
#     gh = Github(os.environ["GITHUB_TOKEN"])

#     repo = gh.get_repo(repo_full_name)
#     head = repo.get_branch(head_ref)
#     base = repo.get_branch(base_ref)

#     diff_paths = [f.filename for f in repo.compare(
#         base.commit.sha, head.commit.sha.files)]

#     for f in diff_paths:
#         if re.search(path_filter, f):
#             return True