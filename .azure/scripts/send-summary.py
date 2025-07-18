# send-summary.py
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import smtplib
import argparse

parser = argparse.ArgumentParser( description="Generate an build report and send via email." )
parser.add_argument( "--login" , required=True , help="Sparkpost Login" )
parser.add_argument( "--password" , required=True , help="Sparkpost Password" )
parser.add_argument( "--sender" , required=True , help="From Address" )
parser.add_argument( "--recipient" , required=True , help="To Address" )
parser.add_argument( "--job" , help="Summary Job" )
parser.add_argument( "--branch" , help="Summary Branch" )
parser.add_argument( "--commits" , help="Summary Commits" )
parser.add_argument( "--build" , help="Summary Build" )
parser.add_argument( "--validation" , help="Summary Validation" )
parser.add_argument( "--operation" , help="Summary Operation" )
parser.add_argument( "--verbose" , action="store_true" , help="Enable verbose output" )
args = parser.parse_args()

# Send Summary
def sendSummary( subject , body ):
    if args.verbose:
        print( "send-summary.py: sendSummary" )
        print( "sender: " + args.sender )
        print( "recipient: " + args.recipient )
        print( "subject: " + subject )
        print( "body: \n" + body )
        print( " ~ ~ ~ " )
    message = MIMEMultipart()
    message["From"] = args.sender
    message["To"] = args.recipient
    message["Subject"] = subject
    message.attach(MIMEText(body, "plain")) # plain or html
    try:
        with smtplib.SMTP("smtpstatic.sparkpostmail.com", 587) as server:
            server.starttls()
            server.login( args.login , args.password )
            server.sendmail( args.sender , args.recipient , message.as_string() )
            if args.verbose:
                print( "Email sent successfully!" )
    except Exception as e:
        print( f"Error sending email: {e}" )

# Main function
def main():
    if args.verbose:
        print( "send-summary.py: main" )
        print( args )
        print( "job: " + args.job )
        print( "branch: " + args.branch )
        print( "commits: " + args.commits )
        print( "build: " + args.build )
        print( "validation: " + args.validation )
        print( "operation: " + args.operation )
        print( " ~ ~ ~ " )
    subject = "Azure: " + args.job
    body = ""
    if ( args.job and args.job.strip() ):
        body += args.job + "\n"
        body += "\n"
    if ( args.branch and args.branch.strip() ):
        body += args.branch + "\n"
    if ( args.commits and args.commits.strip() ):
        body += args.commits + "\n"
    if ( args.build and args.build.strip() ):
        body += args.build + "\n"
    if ( args.validation and args.validation.strip() ):
        body += args.validation + "\n"
    if ( args.operation and args.operation.strip() ):
        body += args.operation + "\n"
    sendSummary( subject.strip() , body.strip() )
    if args.verbose:
        print( " ~ ~ ~ " )

main()
