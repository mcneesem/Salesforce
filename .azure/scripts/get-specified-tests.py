# get-specified-tests.py
import argparse
import os

parser = argparse.ArgumentParser( description="Evalute the current build artifacts and determine the Apex Tests required for validation." )
parser.add_argument( "isDebug" , help="Debug" )
parser.add_argument( "artifactStagingDirectory" , help="Artifact Staging Directory" )
args = parser.parse_args()

# Scan Apex File
def scanApexFile( directorypath , filename , headLength=50 ):
    testClasses = set()
    filepath = os.path.join( directorypath , filename )
    if os.path.isfile( filepath ):
        with open( filepath , 'r' , encoding='utf-8' ) as f:
            for i , line in enumerate( f ):
                if ( i >= headLength ):
                    break
                annotation = "// test w/ "
                if annotation in line:
                    # found one of the following patterns...
                    # // test w/ OneSpecificApexTest, TwoSpecificApexTest (XX%)
                    # // test w/ OneSpecificApexTest (XX%)
                    # // test w/ TwoSpecificApexTest (XX%)
                    if args.isDebug:
                        print( "Found Test Code Coverage Annotation: " + line.strip() )
                    testClasses.add( line.strip().split( annotation )[1].split( " (" , 1 )[0] )
    return testClasses

# Scan Apex Directory
def scanApexDirectory( directorypath ):
    testClasses = set()
    for filename in os.listdir( directorypath ):
        if filename.endswith( ( ".cls" , ".trigger" ) ):
            if "Test" in filename:
                # found a test class...
                if args.isDebug:
                    print( "Found Test Class: " + filename )
                testClasses.add( filename.split( "." , 1 )[0] )
            else:
                # scan the content of the file for test code coverage annotations...
                testClasses = testClasses | scanApexFile( directorypath , filename )
    return testClasses

# Main function
def main():
    if args.isDebug:
        print( "get-specified-tests.py: main" )
        print( args.artifactStagingDirectory )
        print( " ----- " )
    testClasses = set()
    testClasses = testClasses | scanApexDirectory( args.artifactStagingDirectory + "/force-app/main/default/classes/" )
    testClasses = testClasses | scanApexDirectory( args.artifactStagingDirectory + "/force-app/main/default/triggers/" )
    if args.isDebug:
        print( testClasses )
        print( " ----- " )
    specifiedTests = " ".join( testClasses )
    print( specifiedTests )
    return specifiedTests

main()
