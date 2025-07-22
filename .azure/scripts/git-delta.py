# git-delta.py
import argparse
import os

parser = argparse.ArgumentParser( description="Evalute the current git checkout and determine the delta required for a build." )
parser.add_argument( "--diff" , required=True , help="File containing results of 'git diff' command." )
parser.add_argument( "--files" , required=True , help="File containing results of 'git ls-files' command." )
parser.add_argument( "--verbose" , action="store_true" , help="Enable verbose output" )
args = parser.parse_args()

# Scan Git File
def scanGitFile( filepath , verbose=False ):
    if args.verbose:
        print( "git-delta.py: scanGitFile" )
        print( filepath )
    if os.path.exists( filepath ):
        if os.path.isfile( filepath ):
            with open( filepath , 'r' , encoding='utf-8' ) as f:
                for i , line in enumerate( f ):
                    if verbose:
                        print( line.strip() )

# Main function
def main():
    if args.verbose:
        print( "git-delta.py: main" )
        print( args.diff )
        print( args.files )
        print( args.verbose )
        print( " ----- " )
    scanGitFile( args.diff , args.verbose )
    if args.verbose:
        print( " ----- " )
    scanGitFile( args.files , False )
    if args.verbose:
        print( " ----- " )

main()
