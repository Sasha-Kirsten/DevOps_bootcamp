import boto3
import schedule

ec2_client = boto3.client('ec2', region_name='us-east-1')


def create_snapshot():
    volumes = ec2_client.describe_volumes()
    for volume in volumes['Volumes']:
        snapshot = ec2_client.create_snapshot(
            VolumeId=volume['VolumeId'],
            Description=f"Snapshot of volume {volume['VolumeId']}"
        )
        print(f"Created snapshot {snapshot['SnapshotId']} for volume {volume['VolumeId']}")
        print(snapshot)

schedule.every(10).seconds.do(create_snapshot)

while True:
    schedule.run_pending()

