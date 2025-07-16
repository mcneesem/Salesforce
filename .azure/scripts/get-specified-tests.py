# get-specified-tests.py
import argparse
import os

parser = argparse.ArgumentParser( description="Evalute the current build artifacts and determine the Apex Tests required for validation." )
parser.add_argument( "artifactStagingDirectory" , help="Artifact Staging Directory" )
args = parser.parse_args()

def headFile( directorypath , filename , headLength=50 ):
    testClasses = {}
    filepath = os.path.join( directorypath , filename )
    if os.path.isfile( filepath ):
        try:
            with open( filepath , 'r' , encoding='utf-8' ) as f:
                for i , line in enumerate( f ):
                    if ( i >= headLength ):
                        break
                    if "// test w/ " in line:
                        print( "Found Test Code Coverage Annotation: " + line.strip() )
                        testClasses.add( line.strip() )
        except Exception as e:
            print( f"Error reading '{filename}': {e}" )
    else:
        print( f"\n--- Skipping '{filename}' (not a regular file) ---" )
    return testClasses

def headDirectoryApex( directorypath ):
    print( "get-specified-tests.py: headDirectoryApex" )
    testClasses = {}
    try:
        for filename in os.listdir( directorypath ):
            if filename.endswith( ( ".cls" , ".trigger" ) ):
                if "Test" in filename:
                    print( "Found Test Class: " + filename )
                    testClasses.add( filename )
                else:
                    testClasses = testClasses | headFile( directorypath , filename )
    except FileNotFoundError:
        print( f"Error: Directory not found at '{directorypath}'" )
    except Exception as e:
        print( f"An unexpected error occurred: {e}" )
    return testClasses

# Main function
def main():
    print( "get-specified-tests.py: main" )
    print( args.artifactStagingDirectory )
    print( " ----- " )
    testClasses = {}
    testClasses = testClasses | headDirectoryApex( args.artifactStagingDirectory + "/force-app/main/default/classes/" )
    testClasses = testClasses | headDirectoryApex( args.artifactStagingDirectory + "/force-app/main/default/triggers/" )
    print( testClasses )
    print( " ----- " )
    specifiedTests = "XXX"
    print( specifiedTests )
    return specifiedTests;

main()
