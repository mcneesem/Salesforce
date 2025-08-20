# git-delta.py
import argparse
import subprocess
import os
import shutil
import xml.etree.ElementTree as ET

PATH_FORCE_APP_MAIN_DEFAULT = "force-app/main/default"
NAMESPACE_SOAP_SFORCE_METADATA = "http://soap.sforce.com/2006/04/metadata"

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

# Scan Git Diff Paths
def scanGitDiffPaths( lines , verbose=False ):
    if verbose:
        print( "git-delta.py: scanGitDiffPaths" )
        print( lines )
        if lines:
            print( len( lines ) )
        print( " ----- " )
    response = {}
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
                    if PATH_FORCE_APP_MAIN_DEFAULT in parts[1]:
                        if verbose:
                            print( parts )
                        if parts[0] not in response:
                            response[parts[0]] = []
                        response[parts[0]].append( parts[1] )
    return response

# Find Parent Elements
def findParentElements( filepath , searchFullNames , verbose=False ):
    if verbose:
        print( "git-delta.py: findParentElements" )
        print( filepath )
        print( searchFullNames )
    response = {}
    if filepath:
        if os.path.exists( filepath ):
            if os.path.isfile( filepath ):
                namespace = NAMESPACE_SOAP_SFORCE_METADATA
                xmlns = " xmlns=\"" + namespace + "\""
                ET.register_namespace( "" , namespace )
                tree = ET.parse( filepath )
                root = tree.getroot()
                # build parentMap
                parentMap = {c: p for p in root.iter() for c in p}
                # iterate through all elements in the tree
                for element in root.iter():
                    if element.text:
                        for i , searchFullName in enumerate( searchFullNames ):
                            if searchFullName in element.text:
                                # only care about <fullName> element matches...
                                localTag = element.tag
                                if '}' in element.tag:
                                    # extract the local name after the '}'
                                    localTag = element.tag.split('}', 1)[1]
                                if ( localTag == "fullName" ):
                                    # found a critical <fullName> element...
                                    if verbose:
                                        print( "found: " + searchFullName )
                                        print( ET.tostring( element ).decode( "utf-8" ).replace( xmlns , "" ).strip() )
                                    if element in parentMap:
                                        # pull the parent element from the parent map for the critical <fullName> element...
                                        parentElement = parentMap[element]
                                        if parentElement is not None:
                                            # store the rendered parent element in the response...
                                            value = "    " + ET.tostring( parentElement , encoding="utf-8" , short_empty_elements=False ).decode( "utf-8" ).replace( xmlns , "" ).strip()
                                            response[searchFullName] = value
                                            if verbose:
                                                print( value )
    if verbose:
        print( " ----- " )
    return response

# Write Metadata File
def writeMetadataFile( filepath , searchFullNames , metadataType , verbose=False ):
    if verbose:
        print( "git-delta.py: writeMetadataFile" )
        print( filepath )
        print( searchFullNames )
    # extract all modified parent elements...
    modifiedParentElements = None
    if filepath in searchFullNames:
        modifiedParentElements = findParentElements(
            filepath ,
            searchFullNames[filepath] ,
            verbose
        )
    # concatenate modified parent elements into a reduced xml file...
    if modifiedParentElements:
        outputFileBody = ""
        outputFileBody += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        outputFileBody += "<" + metadataType + " xmlns=\"" + NAMESPACE_SOAP_SFORCE_METADATA + "\">\n"
        for key in modifiedParentElements:
            outputFileBody += modifiedParentElements[key]
            outputFileBody += "\n"
        outputFileBody += "</" + metadataType + ">\n"
        if verbose:
            print( "outputFileBody: " + filepath )
            print( outputFileBody )
        with open( filepath , 'w' ) as f:
            f.write( outputFileBody )
    if verbose:
        print( " ----- " )

# Safe Get Xml From String
def safeGetXmlFromString( line , verbose=False ):
    if line:
        # + indicates added line...
        if line.startswith( "+" ):
            # strip "+" from beginning of line
            line = line[1:]
        # strip all leading/trailing whitespace...
        line = line.strip()
    root = None
    if line:
        try:
            # attempt to convert stripped line into xml element...
            root = ET.fromstring( line )
        except Exception as e:
            root = None
    return root

# Find Modified Elements
# ~ find the <fullName> elements of any modified parent elements...
def findModifiedElements( lines , verbose=False ):
    if verbose:
        print( "git-delta.py: findModifiedElements" )
        print( lines )
        if lines:
            print( len( lines ) )
        print( " ----- " )
    response = {}
    if lines:
        currentPath = ""
        currentFullName = ""
        for i , line in enumerate( lines ):
            # +++ indicates modified file information line...
            if line.startswith( "+++" ):
                if PATH_FORCE_APP_MAIN_DEFAULT in line:
                    index = line.find( PATH_FORCE_APP_MAIN_DEFAULT )
                    currentPath = line[index:]
                if verbose:
                    print( "file: " + line )
            else:
                # track the current <fullName> element while reading each line of the `git diff` output...
                hasElementText = False
                rootCheck = safeGetXmlFromString( line )
                if rootCheck is not None:
                    if ( rootCheck.tag == "fullName" ):
                        currentFullName = rootCheck.text
                    if ( rootCheck.text is not None ) and ( rootCheck.text.strip() != "" ):
                        hasElementText = True
                # + indicates added line...
                if line.startswith( "+" ):
                    # ignore containing parent elements...
                    # ~ i.e. when an totally new parent element is added...
                    if hasElementText and currentFullName and currentPath:
                        if currentPath not in response:
                            response[currentPath] = []
                        if currentFullName not in response[currentPath]:
                            # add current <fullName> value to response of the modified keys for the current path...
                            response[currentPath].append( currentFullName )
                            if verbose:
                                print( "modified: " + currentFullName )
    if verbose:
        print( " ----- " )
    return response

# Scan Git Diff Lines
# ~ search `git diff` results for the <fullName> elements of any changed parent elements...
# ~ re-write a "reduced" version of *.*-meta.xml files containing only the new/modified parent elements...
# ~ match the output of InsperitySalesForceGitDelta@2.0.1
# ~ InsperitySalesForceGitDelta@2.0.1 produces some metadata files "reduced" to only the modified elements...
#   ~ *.labels-meta.xml
#   ~ *.sharingRules-meta.xml
#   ~ *.workflow-meta.xml
def scanGitDiffLines( lines , verbose=False ):
    if verbose:
        print( "git-delta.py: scanGitDiffLines" )
        print( lines )
        if lines:
            print( len( lines ) )
        print( " ----- " )
    # find the <fullName> elements of any modified parent elements...
    searchFullNames = findModifiedElements(
        lines ,
        verbose
    )

    metadataTypeMap = {}
    metadataTypeMap["labels"] = {}
    metadataTypeMap["labels"]["directoryName"] = "labels"
    metadataTypeMap["labels"]["suffix"] = "labels"
    metadataTypeMap["labels"]["xmlName"] = "CustomLabels"

    metadataTypeMap["sharingRules"] = {}
    metadataTypeMap["sharingRules"]["directoryName"] = "sharingRules"
    metadataTypeMap["sharingRules"]["suffix"] = "sharingRules"
    metadataTypeMap["sharingRules"]["xmlName"] = "SharingRules"

    metadataTypeMap["workflows"] = {}
    metadataTypeMap["workflows"]["directoryName"] = "workflows"
    metadataTypeMap["workflows"]["suffix"] = "Workflow"
    metadataTypeMap["workflows"]["xmlName"] = "Workflow"

    if verbose:
        print( metadataTypeMap )
        for metadataFolder in metadataTypeMap:
            print( metadataFolder + ": " + str( metadataTypeMap[metadataFolder] ) )
            print( metadataFolder + ": directoryName: " + str( metadataTypeMap[metadataFolder]["directoryName"] ) )
            print( metadataFolder + ": suffix: " + str( metadataTypeMap[metadataFolder]["suffix"] ) )
            print( metadataFolder + ": xmlName: " + str( metadataTypeMap[metadataFolder]["xmlName"] ) )

    if verbose:
        print( searchFullNames )
    if searchFullNames:
        if verbose:
            print( len( searchFullNames ) )
        for path in searchFullNames:
            if verbose:
                print( path + ": " + str( len( searchFullNames[path] ) ) )
            shortpath = path[( len( PATH_FORCE_APP_MAIN_DEFAULT ) + 1 ):]
            metadataFolder = shortpath[0:shortpath.find( "/" )]
            if verbose:
                print( "metadataFolder: " + metadataFolder )
                print( metadataFolder + ": " + str( metadataTypeMap[metadataFolder] ) )
                print( metadataFolder + ": directoryName: " + str( metadataTypeMap[metadataFolder]["directoryName"] ) )
                print( metadataFolder + ": suffix: " + str( metadataTypeMap[metadataFolder]["suffix"] ) )
                print( metadataFolder + ": xmlName: " + str( metadataTypeMap[metadataFolder]["xmlName"] ) )
            if metadataFolder:
                # re-write metadata file...
                writeMetadataFile(
                    path ,
                    searchFullNames ,
                    metadataTypeMap[metadataFolder]["xmlName"] ,
                    verbose
                )
    if verbose:
        print( " ----- " )

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
                '--unified=50' ,
                args.start ,
                args.end ,
                PATH_FORCE_APP_MAIN_DEFAULT + "/labels" ,
                PATH_FORCE_APP_MAIN_DEFAULT + "/sharingRules" ,
                PATH_FORCE_APP_MAIN_DEFAULT + "/workflows"
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

    scanGitDiffLines( gitDiffLines , args.verbose )

    gitDiffPaths = parseCommandResponse(
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
        print( "gitDiffPaths:runCommand:parseCommandResponse:" )
        print( gitDiffPaths )
        if gitDiffPaths:
            print( len( gitDiffPaths ) )
        print( " ----- " )

    gitDiffs = scanGitDiffPaths( gitDiffPaths , args.verbose )
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
