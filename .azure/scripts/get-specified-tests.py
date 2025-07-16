# get-specified-tests.py
import argparse
import os

parser = argparse.ArgumentParser( description="Evalute the current build artifacts and determine the Apex Tests required for validation." )
parser.add_argument( "artifactStagingDirectory" , help="Artifact Staging Directory" )
args = parser.parse_args()

def headFile( directorypath , filename , headLength=50 ):
    filepath = os.path.join( directorypath , filename )
    if os.path.isfile( filepath ):
        print( f"\n--- Reading first {headLength} lines of '{filename}' ---")
        try:
            with open( filepath , 'r' , encoding='utf-8' ) as f:
                for i , line in enumerate( f ):
                    if ( i >= headLength ):
                        break
                    if "// test w/ " in line:
                        print( "Found Test Code Coverage Annotation: " + line.strip() )
        except Exception as e:
            print( f"Error reading '{filename}': {e}" )
    else:
        print( f"\n--- Skipping '{filename}' (not a regular file) ---" )

def headDirectoryApex( directorypath ):
    print( "get-specified-tests.py: headDirectoryApex" )
    try:
        for filename in os.listdir( directorypath ):
            if filename.endswith( ( ".cls" , ".trigger" ) ):
                if "Test" in filename:
                    print( "Found Test Class: " + filename )
                else:
                    headFile( directorypath , filename )
    except FileNotFoundError:
        print( f"Error: Directory not found at '{directorypath}'" )
    except Exception as e:
        print( f"An unexpected error occurred: {e}" )

# Main function
def main():
    print( "get-specified-tests.py: main" )
    print( args.artifactStagingDirectory )
    headDirectoryApex( args.artifactStagingDirectory + "/force-app/main/default/classes/" )

    specifiedTests = "NSP_ServiceConstantsTest NSP_SalesConstantsTest"
    print( specifiedTests )
    return specifiedTests;

main()
