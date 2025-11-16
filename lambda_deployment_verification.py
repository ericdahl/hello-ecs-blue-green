import json
import os
import boto3

ssm = boto3.client('ssm')

def handler(event, context):
    """
    Lambda function to verify deployment approval via SSM parameter.

    This function is invoked as a lifecycle hook during ECS blue/green deployments.
    It checks the SSM parameter and either allows or blocks the deployment.
    """

    print(f"Received event: {json.dumps(event)}")

    ssm_parameter_name = os.environ['SSM_PARAMETER_NAME']

    try:
        response = ssm.get_parameter(Name=ssm_parameter_name)
        parameter_value = response['Parameter']['Value'].lower().strip()

        print(f"SSM Parameter '{ssm_parameter_name}' value: {parameter_value}")

        if parameter_value == 'true':
            print("Deployment verification passed. Proceeding with deployment.")
            return {"hookStatus": "SUCCEEDED"}
        else:
            print("Deployment verification failed. Blocking deployment.")
            return {"hookStatus": "FAILED"}

    except ssm.exceptions.ParameterNotFound:
        print(f"SSM Parameter '{ssm_parameter_name}' not found. Blocking deployment.")
        return {"hookStatus": "FAILED"}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"hookStatus": "FAILED"}
