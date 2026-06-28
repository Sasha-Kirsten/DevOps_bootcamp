import boto3

ec2_client = boto3.client('ec2', region_name='us-east-1')
ec2_resource = boto3.resource('ec2', region_name='us-east-1')

instance_ids_frankfurt = ['i-0e1f2a3b4c5d6e7f8', 'i-1a2b3c4d5e6f7g8h9']

reservations = ec2_client.describe_instances(InstanceIds=instance_ids_frankfurt)

for reservation in reservations['Reservations']:
    for instance in reservation['Instances']:
        print(f"Instance ID: {instance['InstanceId']}, State: {instance['State']['Name']}")

response = ec2_client.create_tags(
    DryRun=False|True,
    Resources=[
        'string',
    ],
    Tags=[
        {
            'Key': 'string',
            'Value': 'string'
        },
    ]
)

reservations = ec2_client.describe_instances(InstanceIds=instance_ids_frankfurt)

print("Updated instance tags:")
for reservation in reservations['Reservations']:
    for instance in reservation['Instances']:
        print(f"Instance ID: {instance['InstanceId']}, Tags: {instance.get('Tags', [])}")