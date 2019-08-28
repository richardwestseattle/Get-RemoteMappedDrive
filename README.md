## NAME
    Get-RemoteMappedDrive

## SYNOPSIS
    Enumerate user profiles on local and remote computers, and retrieve the users' mapped drives.

## SYNTAX
    Get-RemoteMappedDrive [-ComputerName] <String[]> [-maxConcurrentJobs <Int32>] [-timeLimitperJob <Int32>] [-showStatus] [<CommonParameters>]


## DESCRIPTION
    Enumerate user profiles on local and remote computers, and retrieve the users' mapped drives. 

    Author: Richard West

    Contact: richard@premiumsource.solutions


## PARAMETERS
    -ComputerName <String[]>

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Accept wildcard characters?  false

    -maxConcurrentJobs <Int32>
        [int]Max number of allowed parallel background jobs. Default value is 20.

        Required?                    false
        Position?                    named
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -timeLimitperJob <Int32>
        [int]Max number of minutes allowed for each background job. Jobs that exceed threshold are cancelled. Default value is 1.

        Required?                    false
        Position?                    named
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -showStatus [<SwitchParameter>]
        [switch]Write scan status to console.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable.

## INPUTS
    [String[]] #Computer Name(s).


## OUTPUTS
    [PSOBJECT]
        #Properties:
            [String]ScanDate #Format yyyy-MM-dd-HH-mm-ss
            [String]UserName
            [String]SID
            [String]ComputerName
            [String]Letter
            [String]RemotePath

## EXAMPLES
### EXAMPLE 1

    PS C:\>Get All Users' Mapped Drives on Computer, "MyComputerName". Format output as a table.

    PS> Get-RemoteMappedDrive -ComputerName "MyComputerName"| Select-Object UserName, ComputerName, Name, Value, ScanDate | Format-Table


### EXAMPLE 2

    PS C:\>Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2".

    PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" | Select-Object UserName, ComputerName, Name, Value, ScanDate | Format-Table


### EXAMPLE 3

    PS C:\>Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2". Export to CSV.

    PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" | Select-Object UserName, ComputerName, Name, Value, ScanDate | Export-CSV -NoTypeInformation -Path 
    "$($PSScriptRoot)\drives.csv"



### EXAMPLE 4

    PS C:\>Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2". Configure [int]maxConcurrentJobs and [int]timeLimitperJob.

    PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" -maxConcurrentJobs 10 -timeLimitperJob 2


### EXAMPLE 5

    PS C:\>Pipe computer names into Get-RemoteMappedDrive

    PS> $ComputerList = "Computer1", "Computer2", "Computer3"
    PS> $ComputerList | Get-RemoteMappedDrive -showStatus

## RELATED LINKS
    Project URI: 'https://github.com/richardwestseattle/Get-RemoteMappedDrive'
    Website: 'http://premiumsource.solutions'
    Contact: 'richard@premiumsource.solutions' 
