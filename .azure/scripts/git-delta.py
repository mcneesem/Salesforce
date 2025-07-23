# git-delta.py
import argparse
import os
import shutil

parser = argparse.ArgumentParser( description="Evalute the current git checkout and determine the delta required for a build." )
parser.add_argument( "--diff" , required=True , help="File containing results of 'git diff' command." )
parser.add_argument( "--files" , required=True , help="File containing results of 'git ls-files' command." )
parser.add_argument( "--output" , required=True , help="Output directory for delta package." )
parser.add_argument( "--verbose" , action="store_true" , help="Enable verbose output" )
args = parser.parse_args()

# Copy File
def copyFile( filepath , output , verbose=False ):
    if verbose:
        print( "git-delta.py: copyFile" )
        print( filepath )
        print( output )
    if filepath:
        if os.path.exists( filepath ):
            if os.path.isfile( filepath ):
                if output:
                    if os.path.exists( output ):
                        if os.path.isdir( output ):
                            filedir = os.path.dirname( filepath )
                            destination = os.path.join( output , filedir )
                            os.makedirs( destination , exist_ok=True )
                            shutil.copy( filepath , destination )
    if verbose:
        print( " ----- " )

# Copy File Paths
def copyFilePaths( filepaths , output , verbose=False ):
    if verbose:
        print( "git-delta.py: copyFilePaths" )
        print( filepaths )
        print( output )
    if filepaths:
        for i , filepath in enumerate( filepaths ):
            copyFile( filepath , output , verbose )
    if verbose:
        print( " ----- " )

# Copy Package Files
def copyPackageFiles( gitDiffs , output , verbose=False ):
    if verbose:
        print( "git-delta.py: copyPackageFiles" )
        print( gitDiffs )
        print( output )
    if gitDiffs:
        for key in gitDiffs:
            if verbose:
                print( key )
                print( gitDiffs[key] )
            if key != "D":
                copyFilePaths( gitDiffs[key] , output , verbose )

# Scan Git Diff Lines
def scanGitDiffLines( lines , verbose=False ):
    if verbose:
        print( "git-delta.py: scanGitDiffLines" )
        print( lines )
        if lines:
            print( len( lines ) )
        print( " ----- " )
    gitDiffs = {}
    if lines:
        for i , line in enumerate( lines ):
            stripped = line.strip()
            separator = "\t"
            if separator in stripped:
                # git diff
                # ~ A: Addition of a file.
                # ~ C: Copy of a file into a new one.
                # ~ D: Deletion of a file.
                # ~ M: Modification of the contents or mode of a file.
                # ~ R: Renaming of a file.
                # ~ T: Change in the type of the file (e.g., from a regular file to a symbolic link).
                # ~ U: File is unmerged (requires conflict resolution).
                # ~ X: "Unknown" change type (typically indicates an internal issue).
                parts = stripped.split( separator )
                if ( len( parts ) == 2 ):
                    # only care about diffs inside of the salesforce metadata folder structure...
                    if "force-app/main/default" in parts[1]:
                        if verbose:
                            print( parts )
                        if parts[0] not in gitDiffs:
                            gitDiffs[parts[0]] = []
                        gitDiffs[parts[0]].append( parts[1] )
    return gitDiffs

# Parse File
def parseFile( filepath , verbose=False ):
    if args.verbose:
        print( "git-delta.py: parseFile" )
        print( filepath )
    lines = []
    if filepath:
        if os.path.exists( filepath ):
            if os.path.isfile( filepath ):
                with open( filepath , 'r' , encoding='utf-8' ) as f:
                    for i , line in enumerate( f ):
                        stripped = line.strip()
                        if verbose:
                            print( stripped )
                        lines.append( stripped )
    return lines

# Main function
def main():
    if args.verbose:
        print( "git-delta.py: main" )
        print( args.diff )
        print( args.files )
        print( args.output )
        print( args.verbose )
        print( " ----- " )

    gitLsFileLines = parseFile( args.files , False )
    if args.verbose:
        print( "gitLsFileLines:" )
        print( gitLsFileLines )
        if gitLsFileLines:
            print( len( gitLsFileLines ) )
        print( " ----- " )

    gitDiffLines = parseFile( args.diff , True )
    if args.verbose:
        print( "gitDiffLines:" )
        print( gitDiffLines )
        if gitDiffLines:
            print( len( gitDiffLines ) )
        print( " ----- " )

    gitDiffs = scanGitDiffLines( gitDiffLines , args.verbose )
    if args.verbose:
        print( "gitDiffs:" )
        if gitDiffs:
            print( gitDiffs.keys() )
        print( gitDiffs )
        if gitDiffs:
            print( len( gitDiffs ) )
            for key in gitDiffs:
                print( key + ": " + str( len( gitDiffs[key] ) ) )
        print( " ----- " )

    copyPackageFiles( gitDiffs , args.output , args.verbose )
    if args.verbose:
        print( " ----- " )

main()
