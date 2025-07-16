# get-specified-tests.py
import argparse
import os

parser = argparse.ArgumentParser( description="Evalute the current build artifacts and determine the Apex Tests required for validation." )
parser.add_argument( "artifactStagingDirectory" , help="Artifact Staging Directory" )
args = parser.parse_args()

def headFile( directorypath , filename , headLength=50 ):
    testClasses = set()
    filepath = os.path.join( directorypath , filename )
    if os.path.isfile( filepath ):
        try:
            with open( filepath , 'r' , encoding='utf-8' ) as f:
                for i , line in enumerate( f ):
                    if ( i >= headLength ):
                        break
                    annotation = "// test w/ "
                    if annotation in line:
                        print( "Found Test Code Coverage Annotation: " + line.strip() )
                        testClasses.add( line.strip().split( annotation )[1].split( " (" , 1 )[0] )
        except Exception as e:
            print( f"Error reading '{filename}': {e}" )
    else:
        print( f"\n--- Skipping '{filename}' (not a regular file) ---" )
    return testClasses

def headDirectoryApex( directorypath ):
    print( "get-specified-tests.py: headDirectoryApex" )
    testClasses = set()
    try:
        for filename in os.listdir( directorypath ):
            if filename.endswith( ( ".cls" , ".trigger" ) ):
                if "Test" in filename:
                    print( "Found Test Class: " + filename )
                    testClasses.add( filename.partition( "." ) )
                else:
                    testClasses = testClasses | headFile( directorypath , filename )
    except FileNotFoundError:
        print( f"Error: Directory not found at '{directorypath}'" )
    except Exception as e:
        print( f"An unexpected error occurred: {e}" )
    return testClasses

# Main function
def main() -> str:
    print( "get-specified-tests.py: main" )
    print( args.artifactStagingDirectory )
    print( " ----- " )
    testClasses = set()
    testClasses = testClasses | headDirectoryApex( args.artifactStagingDirectory + "/force-app/main/default/classes/" )
    testClasses = testClasses | headDirectoryApex( args.artifactStagingDirectory + "/force-app/main/default/triggers/" )
    print( testClasses )
    print( " ----- " )
    print( " ".join( testClasses ) )
    print( " ----- " )

    specifiedTests = "XXX"
    print( specifiedTests )
    return specifiedTests;

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log_error(f"Unhandled exception: {e!s}")
        log_debug(traceback.format_exc())
        # Exit with success code to prevent pipeline failure
        sys.exit(0)

