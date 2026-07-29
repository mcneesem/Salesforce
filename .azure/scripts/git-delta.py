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

# Copy Folder Metadata
def copyFolderMetadataRecurse( filedir , output ):
    if filedir:
        if os.path.exists( filedir ):
            if os.path.isdir( filedir ):
                # metadata types with associated folder metadata types...
                metadataTypes = [ "dashboards" , "documents" , "email" , "reports" ]
                # ensure we stop searching at the base folder for the metadata type...
                basedir = os.path.basename( filedir )
                if ( basedir in metadataTypes ):
                    basedir = None
                # identify the folder metadata type from the file path...
                folderMetadataType = None
                parts = filedir.replace( PATH_FORCE_APP_MAIN_DEFAULT , "" ).split( os.sep )
                if parts:
                    if ( "dashboards" in parts ):
                        folderMetadataType = "dashboardFolder"
                    elif ( "documents" in parts ):
                        folderMetadataType = "documentFolder"
                    elif ( "email" in parts ):
                        folderMetadataType = "emailFolder"
                    elif ( "reports" in parts ):
                        folderMetadataType = "reportFolder"
                # construct the search file name...
                folderMetadataFileExt = None
                if folderMetadataType:
                    folderMetadataFileExt = "." + folderMetadataType + "-meta.xml"
                folderMetadataFile = None
                if ( folderMetadataFileExt and basedir ):
                    folderMetadataFile = ( basedir + folderMetadataFileExt )
                # search the current directory...
                parentdir = os.path.dirname( filedir )
                if ( folderMetadataFile and parentdir ):
                    if os.path.exists( parentdir ):
                        if os.path.isdir( parentdir ):
                            # GitDelta.Solution=DevOps skips the sub-folder metadata files...
                            # ~ if ( os.path.basename( parentdir ) in metadataTypes ):
                            # ~ this condition only searches for folder metadata files in the root-folder of the metadata type...
                            # GitDelta.Solution=PMCC always includes these sub-folder metadta files for completeness of the deployment package...
                            # ~ if True:
                            if ( True or ( os.path.basename( parentdir ) in metadataTypes ) ):
                                for i , sub in enumerate( os.listdir( parentdir ) ):
                                    if ( sub == folderMetadataFile ):
                                        # found the desired folder metadata file...
                                        folderMetadataFilePath = os.path.join(
                                            parentdir ,
                                            folderMetadataFile
                                        )
                                        copyFile( folderMetadataFilePath , output )
                            # recuse up the directory structure...
                            copyFolderMetadataRecurse( parentdir , output )

# Copy Master Detail Fields
def copyMasterDetailFields( filedir , output ):
    if filedir:
        if os.path.exists( filedir ):
            if os.path.isdir( filedir ):
                for i , sub in enumerate( os.listdir( filedir ) ):
                    if ( sub == "fields" ):
                        fieldsSubPath = os.path.join( filedir , sub )
                        for i , field in enumerate( os.listdir( fieldsSubPath ) ):
                            fieldPath = os.path.join( fieldsSubPath , field )
                            with open( fieldPath , 'r' ) as f:
                                content = f.read()
                                if ( content and ( "<type>MasterDetail</type>" in content ) ):
                                    copyFile( fieldPath , output )

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
                # always deploy full lwc (and aura) component directories...
                copyDirectoryRecurse( filedir , output )
            if any( metadataType in filepath for metadataType in [ "/dashboards/" , "/documents/" , "/email/" , "/reports/" ] ):
                # handle metadata types with associated folder metadata types...
                copyFolderMetadataRecurse( filedir , output )
            if "/objects/" in filepath:
                # always the deploy the master-detail fields when an object file changes...
                if filepath.endswith( ".object" + metaFileSuffix ):
                    copyMasterDetailFields( filedir , output )
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
                root = None
                try:
                    # attempt to parse xml file into root...
                    ET.register_namespace( "" , namespace )
                    root = ET.parse( filepath ).getroot()
                except Exception as e:
                    root = None
                    if "error" not in response:
                        response["error"] = []
                    response["error"].append( "Exception occurred during ElementTree.parse in findParentElements" ) # message
                    response["error"].append( filepath ) # fileName
                    response["error"].append( str( e ) ) # exception
                    if verbose:
                        print( response["error"] )
                if root:
                    # build parentMap
                    parentMap = {c: p for p in root.iter() for c in p}
                    # iterate through all elements in the root...
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
    response = {}
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
        if "error" in modifiedParentElements:
            # bubble up errors thrown in findParentElements...
            response["error"] = modifiedParentElements["error"]
        else:
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
    return response

# Trim Diff Line
def trimDiffLine( line , verbose=False ):
    if line:
        # + indicates added line...
        if line.startswith( "+" ):
            # strip "+" from beginning of line
            line = line[1:]
        # strip all leading/trailing whitespace...
        line = line.strip()
    return line

# Safe Get Xml From String
def safeGetXmlFromString( line , verbose=False ):
    line = trimDiffLine( line , verbose )
    root = None
    if line:
        try:
            # attempt to convert stripped line into xml element...
            root = ET.fromstring( line )
        except Exception as e:
            root = None
    return root

# Is Ignored Element
def isIgnoredElement( line , verbose=False ):
    isIgnored = False
    line = trimDiffLine( line , verbose )
    if line:
        # convert end tags to open elements to reduce comparison complexity...
        if "</" in line:
            line = line.replace( "</" , "<" )
        # compile the set of ignored parent elements...
        # ~ identified from the metadata coverage report...
        ignoredElementsCustomLabels = { "<labels>" }
        ignoredElementsWorkflows = { "<alerts>" , "<fieldUpdates>" , "<flowActions>" , "<knowledgePublishes>" , "<outboundMessages>" , "<rules" , "<tasks>" }
        ignoredElementsSharingRules = { "<sharingCriteriaRules>" , "<sharingGuestRules>" , "<sharingOwnerRules>" , "<sharingTerritoryRules>" }
        ignoredElements = ignoredElementsCustomLabels | ignoredElementsWorkflows | ignoredElementsSharingRules
        # only ignore specific elements...
        if line in ignoredElements:
            isIgnored = True
    return isIgnored

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
                rootCheck = safeGetXmlFromString( line , verbose )
                if rootCheck is not None:
                    if ( rootCheck.tag == "fullName" ):
                        currentFullName = rootCheck.text
                    if ( rootCheck.text is not None ) and ( rootCheck.text.strip() != "" ):
                        hasElementText = True
                # + indicates added line...
                if line.startswith( "+" ):
                    # ignore specific containing parent elements...
                    # ~ elements without text are parent elements containing child elements (hasElementText=false)...
                    # ~ i.e. when an totally new Custom Label is added, git see a new line like "+    <label>"...
                    isIgnored = False
                    if not hasElementText:
                        isIgnored = isIgnoredElement( line , verbose )
                    if not isIgnored and currentFullName and currentPath:
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
    response = {}
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
                writeMetadataFileResponse = writeMetadataFile(
                    path ,
                    searchFullNames ,
                    metadataTypeMap[metadataFolder]["xmlName"] ,
                    verbose
                )
                if writeMetadataFileResponse:
                    if "error" in writeMetadataFileResponse:
                        # bubble up errors thrown in writeMetadataFile...
                        if "errors" not in response:
                            response["errors"] = []
                        response["errors"].append( writeMetadataFileResponse["error"] )
    if verbose:
        print( " ----- " )
    return response

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

    scanGitDiffLinesResponse = scanGitDiffLines( gitDiffLines , args.verbose )

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

    # output any errors found before ending the process...
    if scanGitDiffLinesResponse:
        if "errors" in scanGitDiffLinesResponse:
            # bubble up errors thrown in scanGitDiffLines...
            errorMessages = None
            for error in scanGitDiffLinesResponse["errors"]:
                errorMessage = ", ".join( error )
                if not errorMessages:
                    errorMessages = []
                errorMessages.append( errorMessage )
            if errorMessages:
                gitDeltaPythonErrors = " | ".join( errorMessages )
                print( f"##vso[task.setvariable variable=gitDeltaPythonErrors]{gitDeltaPythonErrors}" )
                if args.verbose:
                    print( gitDeltaPythonErrors )

    if args.verbose:
        print( " ----- " )

main()
