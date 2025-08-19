# git-delta.py
import argparse
import subprocess
import os
import shutil

parser = argparse.ArgumentParser( description="Evalute the current git checkout and determine the delta required for a build." )
parser.add_argument( "--start" , default="HEAD" , help="From commit for 'git diff' command." )
parser.add_argument( "--end" , default="HEAD" , help="To commit for 'git diff' command." )
parser.add_argument( "--output" , required=True , help="Output directory for delta package." )
parser.add_argument( "--verbose" , action="store_true" , help="Enable verbose output" )
args = parser.parse_args()

# Copy File
def copyFile( filepath , output ):
    if filepath:
        if os.path.exists( filepath ):
            if os.path.isfile( filepath ):
                if output:
                    if os.path.exists( output ):
                        if os.path.isdir( output ):
                            destination = os.path.join(
                                output ,
                                os.path.dirname( filepath )
                            )
                            os.makedirs( destination , exist_ok=True )
                            shutil.copy( filepath , destination )

# Copy Directory Recurse
def copyDirectoryRecurse( filedir , output ):
    if filedir:
        if os.path.exists( filedir ):
            if os.path.isdir( filedir ):
                for i , sub in enumerate( os.listdir( filedir ) ):
                    subpath = os.path.join( filedir , sub )
                    copyFile( subpath , output )
                    if subpath:
                        if os.path.exists( subpath ):
                            if os.path.isdir( subpath ):
                                copyDirectoryRecurse( subpath , output )

# Get File Path Without Extension
def getFilePathWithoutExtension( filepath ):
    filepathWithoutExtension = filepath
    if filepath:
        if os.path.exists( filepath ):
            if os.path.isfile( filepath ):
                filesplit = os.path.splitext( os.path.basename( filepath ) )
                if ( len( filesplit ) > 0 ):
                    filepathWithoutExtension = os.path.join(
                        os.path.dirname( filepath ) ,
                        filesplit[0]
                    )
    return filepathWithoutExtension

# Copy File Paths
# ~ needs to handle some files differently...
# ~ InsperitySalesForceGitDelta@2 produces some metadata files "reduced" to only the modified elements...
#   ~ *.labels-meta.xml
#   ~ *.sharingRules-meta.xml
#   ~ *.workflow-meta.xml
def copyFilePaths( filepaths , output , verbose=False ):
    if verbose:
        print( "git-delta.py: copyFilePaths" )
        print( filepaths )
        print( output )
    if filepaths:
        metaFileSuffix = "-meta.xml"
        for i , filepath in enumerate( filepaths ):
            # always copy the requested file...
            copyFile( filepath , output )
            if filepath.endswith( metaFileSuffix ):
                # is-a *-meta.xml file...
                # ~ also copy the source file...
                copyFile( filepath.removesuffix( metaFileSuffix ) , output )
            else:
                # is-not-a *-meta.xml file...
                # ~ also copy the meta file...
                copyFile( filepath + metaFileSuffix , output )
            # conditionally copy more related files...
            filedir = os.path.dirname( filepath )
            if any( metadataType in filepath for metadataType in [ "/aura/" , "/lwc/" ] ):
                copyDirectoryRecurse( filedir , output )
            if "/staticresources/" in filepath:
                copyFile(
                    getFilePathWithoutExtension( filepath ) + ".resource" + metaFileSuffix ,
                    output
                )
                if not filedir.endswith( "/staticresources" ):
                    # is-a zipped static resource...
                    copyDirectoryRecurse( filedir , output )
                    copyFile(
                        filedir + ".resource" + metaFileSuffix ,
                        output
                    )
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
                print( key + ": " + str( len( gitDiffs[key] ) ) )
                print( gitDiffs[key] )
            if ( ( key == "A" ) or ( key == "M" ) ):
                copyFilePaths( gitDiffs[key] , output , verbose )
            elif key != "D":
                if verbose:
                    print( "destructiveChanges" )

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

# Parse Command Response
def parseCommandResponse( stdout , verbose=False ):
    if args.verbose:
        print( "git-delta.py: parseCommandResponse" )
        # print( stdout )
    lines = []
    if stdout:
        for i , line in enumerate( stdout.splitlines() ):
            stripped = line.strip()
            if verbose:
                print( stripped )
            lines.append( stripped )
    return lines

# Run Command
def runCommand( command , verbose=False ):
    if args.verbose:
        print( "git-delta.py: runCommand" )
    if verbose:
        print( command )
    response = ""
    if command:
        # Running a simple command and capturing its output
        try:
            result = subprocess.run(
                command ,  # Command and its arguments as a list
                capture_output=True,  # Capture stdout and stderr
                text=True ,  # Decode output as text (UTF-8 by default)
                check=True  # Raise CalledProcessError if the command returns a non-zero exit code
            )
            if result:
                if verbose:
                    print( result.returncode )
                if ( result.returncode == 0 ):
                    response = result.stdout
                else:
                    response = result.stderr
        except subprocess.CalledProcessError as e:
            response = e
    if verbose:
        print( response )
    return response

# Main function
def main():
    if args.verbose:
        print( "git-delta.py: main" )
        print( args.start )
        print( args.end )
        print( args.output )
        print( args.verbose )
        print( " ----- " )

    if False: # disabled git-ls-file for now...
        gitLsFileLines = parseCommandResponse(
            runCommand(
                [
                    'git' ,
                    'ls-files'
                ] ,
                False
            ) ,
            False
        )
        if args.verbose:
            print( "gitLsFileLines:runCommand:parseCommandResponse:" )
            print( gitLsFileLines )
            if gitLsFileLines:
                print( len( gitLsFileLines ) )
            print( " ----- " )

    gitDiffLines = parseCommandResponse(
        runCommand(
            [
                'git' ,
                '--no-pager' ,
                'diff' ,
                '--name-status' ,
                '--no-renames' ,
                args.start ,
                args.end
            ] ,
            True
        ) ,
        False
    )
    if args.verbose:
        print( "gitDiffLines:runCommand:parseCommandResponse:" )
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
