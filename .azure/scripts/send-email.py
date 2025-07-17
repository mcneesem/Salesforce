# send-email.py
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import smtplib
import argparse

parser = argparse.ArgumentParser( description="Generate an build report and send via email." )
parser.add_argument( "sparkpost_login" , help="Sparkpost Login" )
parser.add_argument( "sparkpost_password" , help="Sparkpost Password" )
parser.add_argument( "fromAddress" , help="From Address" )
parser.add_argument( "toAddress" , help="To Address" )
parser.add_argument( "summaryJob" , help="Summary Job" )
parser.add_argument( "summaryBranch" , help="Summary Branch" )
parser.add_argument( "summaryCommits" , help="Summary Commits" )
parser.add_argument( "summaryBuild" , help="Summary Build" )
parser.add_argument( "summaryValidation" , help="Summary Validation" )
parser.add_argument( "summaryOperation" , help="Summary Operation" )
args = parser.parse_args()

print(args)

# Send email
def send_email( subject , body ):
    print( "send-email.py: send_email" )
    message = MIMEMultipart()
    print(args.fromAddress)
    print(args.toAddress)
    print(subject)
    print(body)
    message["From"] = args.fromAddress
    message["To"] = args.toAddress
    message["Subject"] = subject
    message.attach(MIMEText(body, "plain")) # plain or html
    try:
        with smtplib.SMTP("smtpstatic.sparkpostmail.com", 587) as server:
            server.starttls()
            server.login(args.sparkpost_login, args.sparkpost_password)
            server.sendmail(args.fromAddress, args.toAddress, message.as_string())
            print("Email sent successfully!")
    except Exception as e:
        print(f"Error sending email: {e}")

# Main function
def main():
    print( "send-email.py: main" )
    print(args.summaryJob)
    print(args.summaryBranch)
    print(args.summaryCommits)
    print(args.summaryBuild)
    print(args.summaryValidation)
    print(args.summaryOperation)

    subject = "Azure: " + args.summaryJob

    body = ""
    # body += "Body: send-email.py" + "\n"
    # body += "\n"
    if ( args.summaryJob and args.summaryJob.strip() ):
        body += args.summaryJob + "\n"
        body += "\n"
    if ( args.summaryBranch and args.summaryBranch.strip() ):
        body += args.summaryBranch + "\n"
    if ( args.summaryCommits and args.summaryCommits.strip() ):
        body += args.summaryCommits + "\n"
    if ( args.summaryBuild and args.summaryBuild.strip() ):
        body += args.summaryBuild + "\n"
    if ( args.summaryValidation and args.summaryValidation.strip() ):
        body += args.summaryValidation + "\n"
    if ( args.summaryOperation and args.summaryOperation.strip() ):
        body += args.summaryOperation + "\n"

    send_email( subject , body )

main()
