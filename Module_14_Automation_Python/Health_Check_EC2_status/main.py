import boto3 

ec2_client = boto3.client('ec2', region_name='us-east-1')

ec_resource = boto3.resource('ec2', region_name='us-east-1')

reservations = ec2_client.describe_instances()

for reservation in reservations['Reservations']:
    instance = reservation['Instances'][0]
    for instance in instance:
        print(f"Instance ID: {instance['InstanceId']}, State: {instance['State']['Name']}")

statuses = ec2_client.describe_instance_status()
for status in statuses['InstanceStatuses']:
    ins_status = status['InstanceStatus']['Status']
    sys_status = status['SystemStatus']['Status']
    print(f"Instance ID: {status['InstanceId']}, Instance Status: {ins_status}, System Status: {sys_status}")


    