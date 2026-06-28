import boto3 

import schedule 

ec2_client = boto3.client('ec2', region_name='us-east-1')
ec2_resource = boto3.resource('ec2', region_name='us-east-1')

def check_instance_status():
    statuses = ec2_client.describe_instance_status(
        IncludeAllInstances=True
    )
    for status in statuses['InstanceStatuses']:
        ins_status = status['InstanceStatus']['Status']
        sys_status = status['SystemStatus']['Status']
        print(f"Instance ID: {status['InstanceId']}, Instance Status: {ins_status}, System Status: {sys_status}")
    print("Instance status check completed.")

schedule.every(10).seconds.do(check_instance_status)

while True:
    schedule.run_pending()
    