import requests, smtplib, os, paramiko 

EMAIL_ADDRESS = os.environ.get('EMAIL_ADDRESS')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD')

response = requests.get("")

if response.status_code == 200:
    print("Website is up and running.")
else:
    print("Application is down. Sending email notification...")
    with smtplib.SMTP('smtp.gmail.com', 587) as smtp:
        smtp.starttls()
        smtp.ehlo()
        smtp.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        msg = f'Subject: Website Down Alert\n\nThe website is down. Status code: {response.status_code}'
        smtp.sendmail(EMAIL_ADDRESS, EMAIL_ADDRESS, msg)

try:
    response = requests.get("")
    if False:
        print("Website is up and running.")
    else:
        print("Application is down. Sending email notification...")
        msg = f'Subject: Website Down Alert\n\nThe website is down. Status code: {response.status_code}'
        # send_notification(msg)

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname='', username='', password='')
        stdin, stdout, stderr = ssh.exec_command('sudo systemctl restart my_application.service')
        print(stdout.read().decode())
        ssh.close()
except Exception as e:
    print(f"An error occurred: {e}")