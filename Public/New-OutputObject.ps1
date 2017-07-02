Function New-OutputObject {
    <#

    .SYNOPSIS
    Function intended for preparing a PowerShell object for output files like reports or logs.

    .DESCRIPTION
    Function intended for preparing a PowerShell custom object what contains e.g. file name for output/create files like reports or log. The name is prepared based on prefix, middle name part, suffix, date, etc. with verification if provided path exist and is it writable.

    Returned object contains properties
    - OutputObjectPath - to use it please check examples - as a [System.IO.FileInfo]
    - ExitCode
    - ExitCodeDescription

    Exit codes and descriptions
    - 0 = "Everything is fine :-)"
    - 1 = "Provided parent path <PATH> doesn't exist"
    - 2 = "The name not created due to unaccepatable chars"
    - 3 = "Provided patch <PATH> is not writable"
    - 4 = "The file\folder <PATH>\\<FILE_OR_FOLDER_NAME> already exist  - can be overwritten"
    - 5 = "The file\folder <PATH>\\<FILE_OR_FOLDER_NAME> already exist  - can't be overwritten"

    .PARAMETER ObjectType
    Type of object to prepare - file or folder

    .PARAMETER ParentPath
    The folder path what will be used as the parent path for the new created object.
    When non existing path will be provided the error code will be returned.

    By default output files are stored in the current path.

    .PARAMETER OutputObjectNamePrefix
    Prefix used for creating output files name

    .PARAMETER OutputObjectNameMidPart
    Part of the name which will be used in midle of output file name

    .PARAMETER OutputObjectNameSuffix
    Part of the name which will be used at the end of output file name

    .PARAMETER IncludeDateTimePartInOutputObjectName
    Set to TRUE if report file name should contains part based on date and time - format yyyyMMdd-HHmm is used

    .PARAMETER DateTimePartInOutputObjectName
    Set to date and time which should be used in output file name, by default current date and time is used

    .PARAMETER DateTimePartFormat
    Format string used to format date and time in output object name.

    .PARAMETER OutputFileNameExtension
    Set to extension which need to be used for output file, by default ".txt" is used

    .PARAMETER NamePartsSeparator
    A char used to separate parts in the name, by default "-" is used

    .PARAMETER BreakIfError
    Break function execution if parameters provided for output file creation are not correct or destination file path is not writables

    .EXAMPLE

    PS \> (Get-Item env:COMPUTERNAME).Value
    WXDX75

    PS \> $FileNeeded = @{

        ParentPath = 'C:\USERS\UserName\';
        OutputObjectNamePrefix = 'Messages';
        OutputObjectNameMidPart = (Get-Item env:COMPUTERNAME).Value;
        IncludeDateTimePartInOutputObjectName = $true;
        IncludeDateTimePartInOutputObjectName = $true;

        BreakIfError = $true
    }

    PS \> $PerServerReportFileMessages = New-OutputFile @FileNeeded


    PS \> $PerServerReportFileMessages | Format-List


    OutputObjectPath      : C:\users\UserName\Messages-WXDX75-20151021-001205.txt
    ExitCode            : 0
    ExitCodeDescription : Everything is fine :-)

    PS \> New-Item -Path $PerServerReportFileMessages.OutputObjectPath -ItemType file

    Directory: C:\USERS\UserName

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       21/10/2015     00:12              0 Messages-WXDX75-20151021-001205.txt

    The file created on provided parameters.
    Under preparation the file name is created, provided part of names are used, and availability of name (if the file exist now) is checked.

    .EXAMPLE

    $FileNeeded = @{

        ParentPath = 'C:\USERS\UserName\';
        OutputObjectNamePrefix = 'Messages';
        OutputObjectNameMidPart = 'COMPUTERNAME';
        IncludeDateTimePartInOutputObjectName = $false;
        OutputFileNameExtension = "csv";
        OutputObjectNameSuffix = "failed"
    }

    PS \> $PerServerReportFileMessages = New-OutputFile @FileNeeded


    PS \> $PerServerReportFileMessages.OutputObjectPath | Select-Object -Property Name,Extension,Directory | Format-List

    Name      : Messages-COMPUTERNAME-failed.csv
    Extension : .csv
    Directory : C:\USERS\UserName



    PS \> ($PerServerReportFileMessages.OutputObjectPath).gettype()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     FileInfo                                 System.IO.FileSystemInfo

    PS \> Test-Path ($PerServerReportFileMessages.OutputObjectPath)

    False

    The funciton return object what contain the property named OutputObjectPath what is the object of type System.IO.FileSystemInfo.

    File is not created. Only the object in the memory is prepared.

    .OUTPUTS
    System.Object[]

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, File, Folder, FileSystem

    CURRENT VERSION
    - 0.9.9 - 2017-05-16

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/VERSIONS.md

    LICENSE
    Copyright (c) 2016 Wojciech Sciesinski
    This function is licensed under The MIT License (MIT)
    Full license text: https://opensource.org/licenses/MIT

    #>

    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('File', 'Folder')]
        [Alias('ItemType')]
        [String]$ObjectType,
        [parameter(Mandatory = $false)]
        [String]$ParentPath = ".",
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNamePrefix = "Output",
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNameMidPart = $null,
        [parameter(Mandatory = $false)]
        [String]$OutputObjectNameSuffix = $null,
        [parameter(Mandatory = $false)]
        [Bool]$IncludeDateTimePartInOutputObjectName = $true,
        [parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DateTimePartInOutputObjectName = $null,
        [parameter(Mandatory = $false)]
        [String]$DateTimePartFormat,
        [parameter(Mandatory = $false)]
        [String]$OutputFileNameExtension,
        [parameter(Mandatory = $false)]
        [alias("Separator")]
        [String]$NamePartsSeparator = "-",
        [parameter(Mandatory = $false)]
        [Switch]$BreakIfError

    )

    #Declare variable

    [Int]$ExitCode = 0

    $ExitCodesDescriptions = @{'0'= 'Everything is fine :-)';
                                '1' = "Provided parent path {0} doesn't exist"; # $ParentPath
                                '2' = 'The name not created due to unaccepatable chars';
                                '3' = "Provided path {0} is not writable"; # $ParentPath
                                '4' = "The {0} {1} already exist  - can be overwritten" # $ItemTypeLowerCase, $OutputObjectPath.FullName
                                '5' = "The {0} {1} already exist  - can't be overwritten" # $ItemTypeLowerCase, $OutputObjectPath
    }

    [String]$ExitCodeDescription = 'Everything is fine :-)'

    $FinalNameParts = [ordered]@{NamePrefix=$OutputObjectNamePrefix;
                                NameMidPart=$OutputObjectNameMidPart;
                                NameSuffix=$OutputObjectNameSuffix;
                                DateTimePartInName='';
                                FileNameExtension=''
    }

    $Result = New-Object -TypeName PSObject

    If ( $PSVersionTable.PSEdition -eq 'Core' -and $ISLinux) {

        $PathSeparator = '/'

    }
    Else {

        $PathSeparator = '\'

    }

    If ($ObjectType -eq 'File') {

        $PathType = 'Leaf'

        $ItemTypeLowerCase = 'file'

        $ItemTypeCapitalized = 'File'

        $SkipInFinalName = @('FileNameExtension')

        If ([String]::IsNullOrEmpty($DateTimePartFormat)) {

            $DateTimePartFormat = 'yyyyMMdd-HHmmss'

        }
        Else {

            $TestCharsResult = Test-CharsInPath -Path $DateTimePartFormat -SkipCheckCharsInFolderPart

            If ( $TestCharsResult -eq 3) {

                 If ( $BreakIfError.IsPresent ) {

                    $FileNameInvalidChars = [System.IO.Path]::GetInvalidFileNameChars() #41 chars

                    $MessageText = "Provided {0} value for DateTimePartFormat contains char what is not allowed in a file name. Unallowed chars are: {0}" -f $FileNameInvalidChars

                    Throw $MessageText

                }

                Else {

                    [Int]$ExitCode = 2

                    [String]$ExitCodeDescription = "The name not created due to unaccepatable chars"

                }

            }

        }

        if ( [String]::IsNullOrEmpty($OutputFileNameExtension)) {

            $OutputFileNameExtension = '.txt'

            $FinalNameParts['FileNameExtension'] = '.txt'

        }
        Else {

            $FinalNameParts['FileNameExtension'] = "." -f $OutputFileNameExtension

        }

    }

    Else {

        $PathType = 'Container'

        $ItemTypeLowerCase = 'folder'

        $ItemTypeCapitalized = 'Folder'

        $SkipInFinalName = @('FileNameExtension')

        If ([String]::IsNullOrEmpty($DateTimePartFormat)) {

            $DateTimePartFormat = 'yyyyMMdd'

        }
        Else {

            $TestCharsResult = Test-CharsInPath -Path $DateTimePartFormat -SkipCheckCharsInFileNamePart

            If ( $TestCharsResult -eq 2 ) {

                If ( $BreakIfError.IsPresent ) {

                    $PathInvalidChars = [System.IO.Path]::GetInvalidPathChars() #36 chars

                    $MessageText = "Provided value for DateTimePartFormat contains char what is not allowed in a folder name. Unallowed chars are: {0}" -f $PathInvalidChars

                    Throw $MessageText

                }
                Else {

                    [Int]$ExitCode = 2

                    [String]$ExitCodeDescription = "The name not created due to unaccepatable chars"

                }

            }

        }

        if (-not [String]::IsNullOrEmpty($OutputFileNameExtension)) {

            [String]$MessageText = 'The value assigned to the parameter OutputFileNameExtension for a folder OutputType is ignored.'

            Write-Warning -Message $MessageText

        }

    }

    #Convert relative path to absolute path
    [String]$ParentPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ParentPath)

    #Assign value to the variable $IncludeDateTimePartInOutputObjectName if is not initialized
    If ($IncludeDateTimePartInOutputObjectName -and ($null -eq $DateTimePartInOutputObjectName)) {

        [String]$DateTimePartInObjectNameString = $(Get-Date -format $DateTimePartFormat)

        $FinalNameParts['DateTimePartInName'] = $DateTimePartInObjectNameString

    }
    elseif ($IncludeDateTimePartInOutputObjectName) {

        [String]$DateTimePartInObjectNameString = $(Get-Date -Date $DateTimePartInOutputObjectName -format $DateTimePartFormat)

        $FinalNameParts['DateTimePartInName'] = $DateTimePartInObjectNameString

    }

    #Check if Output directory exist
    If (-not (Test-Path -Path $ParentPath -PathType Container)) {

        [Int]$ExitCode = 1

        [String]$MessageText = "Provided parent path {0} doesn't exist" -f $ParentPath

        [String]$ExitCodeDescription = $MessageText

    }

    #Try if Output directory is writable - a temporary object is created for that
    Else {

        #Try if Output directory is writable - a temporary file is created for that
        Try {

            [String]$TempObjectName = [System.IO.Path]::GetTempFileName() -replace '.*\\', ''

            [String]$TempObjectPath = "{0}{1}" -f $ParentPath, $TempObjectName

            New-Item -Path $TempObjectPath -type File -ErrorAction Stop | Out-Null

        }
        Catch {

            [String]$MessageText = "Provided path {0} is not writable" -f $ParentPath

            If ($BreakIfError.IsPresent) {

                Throw $MessageText

            }
            Else {

                [Int]$ExitCode = 3

                [String]$ExitCodeDescription = $MessageText

            }

        }

        Remove-Item -Path $TempObjectPath -ErrorAction SilentlyContinue | Out-Null

    }

    $PartsToJoin =@($ParentPath$PathSeparator)

    ForEach ( $NamePart in $FinalNameParts.Keys) {

        If ( $SkipInFinalName -notcontains $NamePart -and (-not [String]::IsNullOrEmpty( $NamePart))) {

            $PartsToJoin += $FinalNameParts[$NamePart]

        }

    }

    [String]$FinalName =  [string]::Join("$NamePartsSeparator",$PartsToJoin)

    #Constructing the object name
    If (!($IncludeDateTimePartInOutputObjectName) -and !([String]::IsNullOrEmpty($OutputObjectNameMidPart))) {

        [String]$OutputObjectPathTemp1 = "{0}{4}{1}{3}{2}" -f $ParentPath, $OutputObjectNamePrefix, $OutputObjectNameMidPart, $NamePartsSeparator, $PathSeparator

    }
    Elseif (!($IncludeDateTimePartInOutputObjectName) -and [String]::IsNullOrEmpty($OutputObjectNameMidPart)) {

        [String]$OutputObjectPathTemp1 = "{0}{2}{1}" -f $ParentPath, $OutputObjectNamePrefix, $PathSeparator

    }
    ElseIf ($IncludeDateTimePartInOutputObjectName -and !([String]::IsNullOrEmpty($OutputObjectNameMidPart))) {

        [String]$OutputObjectPathTemp1 = "{0}{5}{1}{4}{2}{4}{3}" -f $ParentPath, $OutputObjectNamePrefix, $OutputObjectNameMidPart, $DateTimePartInObjectNameString, $PathSeparator

    }
    Else {

        [String]$OutputObjectPathTemp1 = "{0}{4}{1}{3}{2}" -f $ParentPath, $OutputObjectNamePrefix, $DateTimePartInObjectNameString, $NamePartsSeparator, $PathSeparator

    }


    If ($ObjectType -eq 'File' -and (-not [String]::IsNullOrEmpty($OutputFileNameExtension))) {

        If ([String]::IsNullOrEmpty($OutputObjectNameSuffix)) {

            [String]$OutputObjectPathTemp = "{0}.{1}" -f $OutputObjectPathTemp1, $OutputFileNameExtension

        }
        Else {

            [String]$OutputObjectPathTemp = "{0}{3}{1}.{2}" -f $OutputObjectPathTemp1, $OutputObjectNameSuffix, $OutputFileNameExtension, $NamePartsSeparator

        }

    }
    Else {

        If ([String]::IsNullOrEmpty($OutputObjectNameSuffix)) {

            [String]$OutputObjectPathTemp = "{0}" -f $OutputObjectPathTemp1

        }
        Else {

            [String]$OutputObjectPathTemp = "{0}{2}{1}" -f $OutputObjectPathTemp1, $OutputObjectNameSuffix, $NamePartsSeparator

        }

    }

    $SequencesToReplace = @{'//' = '/';
                            '\\' = '\';
                            '..' = '.';
                            "$NamePartsSeparator." = '.';
                            "$NamePartsSeparator$NamePartsSeparator" = $NamePartsSeparator;
                            "$PathSeparator$NamePartsSeparator" = $PathSeparator
    }

    ForEach ( $SequenceKey in $SequencesToReplace.keys ) {

        $FinalName = "{0}{1}" -f $FinalName.Substring(0,2), (($FinalName.substring(2, $FinalName.length - 2)).Replace($SequenceKey, $SequencesToReplace[$SequenceKey]))

    }

    If ( $ExitCode -eq 2 ) {

      If ($ObjectType -eq 'File') {

            [System.IO.FileInfo]$OutputObjectPath = $null

            [System.IO.FileInfo]$OutputObjectPathNew = $null

        }
        Else {

            [System.IO.DirectoryInfo]$OutputObjectPath = $null

            [System.IO.DirectoryInfo]$OutputObjectPathNew = $null

        }

    }
    Else {

        If ($ObjectType -eq 'File') {

            #Replacing doubled chars \\ , -- , .. - except if \\ is on begining - means that path is UNC share
            [System.IO.FileInfo]$OutputObjectPath = "{0}{1}" -f $OutputObjectPathTemp.substring(0, 2), (($OutputObjectPathTemp.substring(2, $OutputObjectPathTemp.length - 2).replace("\\", '\')).replace("--", "-")).replace("..", ".")

            [System.IO.FileInfo]$OutputObjectPathNew = $FinalName

        }
        Else {

            #Replacing doubled chars \\ , -- , .. - except if \\ is on begining - means that path is UNC share
            [System.IO.DirectoryInfo]$OutputObjectPath = "{0}{1}" -f $OutputObjectPathTemp.substring(0, 2), (($OutputObjectPathTemp.substring(2, $OutputObjectPathTemp.length - 2).replace("\\", '\')).replace("--", "-")).replace("..", ".")

            [System.IO.DirectoryInfo]$OutputObjectPathNew = $FinalName

        }

        If (Test-Path -Path $OutputObjectPath -PathType $PathType) {

            $Answer = Get-OverwriteDecision -Path $OutputObjectPath -ItemType $ObjectType

            switch ($Answer) {

                0 {

                    [Int]$ExitCode = 4

                    [String]$MessageText = "The {0} {1} already exist  - can be overwritten" -f $ItemTypeLowerCase, $OutputObjectPath.FullName

                    [String]$ExitCodeDescription = $MessageText

                }

                1 {

                    [Int]$ExitCode = 5

                    [String]$MessageText = "The {0} {1} already exist  - can't be overwritten" -f $ItemTypeLowerCase, $OutputObjectPath

                    [String]$ExitCodeDescription = $MessageText

                }

                2 {


                    Throw $MessageText

                }

            }

        }

    }

    $Result | Add-Member -MemberType NoteProperty -Name OutputObjectPath -Value $OutputObjectPath

    $Result | Add-Member -MemberType NoteProperty -Name OutputObjectPathNew -Value $OutputObjectPathNew

    #$Result | Add-Member -MemberType AliasProperty -Name Path -Value OutputObjectPath

    If ($ObjectType -eq 'File') {

        $Result | Add-Member -MemberType AliasProperty -Name OutputFilePath -Value OutputObjectPath

    }
    Else {

        $Result | Add-Member -MemberType AliasProperty -Name OutputFolderPath -Value OutputObjectPath

    }

    $Result | Add-Member -MemberType NoteProperty -Name ExitCode -Value $ExitCode

    $Result | Add-Member -MemberType NoteProperty -Name ExitCodeDescription -Value $ExitCodeDescription

    Return $Result

}
