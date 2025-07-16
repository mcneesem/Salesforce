# get-specified-tests.py
import argparse

parser = argparse.ArgumentParser( description="Evalute the current build artifacts and determine the Apex Tests required for validation." )
parser.add_argument( "artifactStagingDirectory" , help="Artifact Staging Directory" )

# Main function
def main():
    print( "get-specified-tests.py: main" )
    print( args.artifactStagingDirectory )

    specifiedTests = "NSP_ServiceConstantsTest NSP_SalesConstantsTest"
    print( specifiedTests )
    return specifiedTests;

main()
