<#
.SYNOPSIS
    Script to list (get) or delete inactive users on a workspace one tenant

.DESCRIPTION
    View or delete inactive users.
    Deletes users 1 at the time, pretty slow.

.PARAMETER tenant
    Defines the tenant URI, must not end with a slash. valid example: https://test123.awmdm.com

.PARAMETER awTenantCode
    The API Key found in tenant admin console > System/Advanced/API

.PARAMETER action
    GET     list inactive users
    DELETE  delete inactive users

.INPUTS
    None

.OUTPUTS
    Default log path is .\log\transcript.txt

.NOTES
    Created: 2020
    Updated: 2021-06-31

!!
    DO - NOT - BLINDLY - RUN - THIS - ON - A - PRODUCTION - SERVER
!!
  
.EXAMPLE
    .\ws1-api-agent.ps1  $tenant https://test123.awmdm.com -awTenantCode longstringboye -action GET
#>

#----------[Initialisations] ---

param (
    [Parameter(Mandatory=$false)]
    [string]$tenant = $null,
    [Parameter(Mandatory=$false)]
    [string]$awTenantCode = $null,
    [Parameter(Mandatory=$false)]
    [Validateset('GET', 'DELETE')]
    [string]$action
)

# Load things
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

#----------[Functions] ---

function UserPrompt {
<# Create something that vaguely resembles a gui#>
    param (
        $title,
        $message
    )
    [Microsoft.VisualBasic.Interaction]::InputBox($message, $title)
}

function SecStrCred ($clixml) {
<# Save API credentials to file, encrypted with currently logged on account #>
    if ((Test-Path -Path $clixml) -ne $true){
            Get-Credential -Message 'Enter REST API credentials' | Export-Clixml -Path $clixml
        }
    }

function AuthToBase64 ($clixml) {
<# Convert username and password to Base64 string for API authentication #>
    $cred = Import-Clixml -Path $clixml
    $un = $cred.username
    $pw = [System.Net.NetworkCredential]::new("", $cred.password).password
    $unpw = "${un}:${pw}"
    [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($unpw))
}

function URI-State {
<# Set URI to GET, tenant must not end with a forward slash ("/") #>
    param(
        [string]
        $uriState,
        [string]
        $tenant
    )
    if ($tenant.StartsWith('https://') -eq $false){
        $tenant = 'https://'+$tenant
        }
    switch ($uriState) {
        'DELETE' {$tenant+"/API/system/users/idValue/delete"}
        'GET'  {$tenant+"/API/system/users/search?pagesize=5000"}
        }
    }
    
function SetHeaders {
<# Set header #>
    param (
        [Parameter(Mandatory=$true)][string]$awTenantCode,
        [Parameter(Mandatory=$true)][string]$base64
    )
    # Header hashtable
        @{ 
            "Accept"            =  "application/json"
            "aw-tenant-code"    =   $awTenantCode
            "Authorization"     =  "Basic $base64"
        }
}

function ListInactive ($userQuery) {
<# Iterate input, add inactive users to new array #> 
[System.Collections.ArrayList]$inactiveArray = foreach ($u in $userQuery.users) {
    if ($u.status -eq $false) {
        $u
        }
    }
    return $inactiveArray 
}

function ReadyGetDelete ($action, $tenant, $header) {
<# Connect to API with method GET to list every user #>
$userArray = Invoke-RestMethod -uri (URI-State 'GET' $tenant) -Method GET -Headers $header

    switch ($action) {

        GET     {
            # Get inactive users
            [array]$inactiveUsers = ListInactive $userArray 

            # Show inactive users
            $inactiveUsers | Format-Table UserName, FirstName, LastName, Email -AutoSize
            Write-Host 'found' $userArray.Users.Length 'users, of which' $inactiveUsers.Users.Length 'are inactive'`n
        }

        DELETE  {
            $i = 0 # Write-Progress
            # Get inactive users
            [array]$inactiveUsers = ListInactive $userArray 

            Clear-Host
            Write-host '--- press CTRL + C to stop' `n'---- found' $inactiveUsers.count 'users'

            # Delete inactive users
            foreach ($d in $inactiveUsers){
                # Invoke!!
                Invoke-RestMethod -URI (URI-State 'DELETE' $tenant).replace('idValue', $d.id.value) -Method $action -Headers $header > $null

                $i = $i+1 # Write-Progress counter
                [array]$deletedUsers += $d | Select-Object UserName, FirstName, LastName, Email
                Write-Progress -Activity 'now deleting...' -Status ($d | Select-Object UserName, FirstName, LastName, Email) -PercentComplete ($i/$inactiveUsers.count*100)
            }

            Clear-Host
        
            if (!$deletedUsers){
                Write-Host ---`n'no users were deleted, if deleted users expected please verify inputs'`n---

            }else{
                Write-Host 'the following users were deleted from your tenant'
                $deletedUsers
            }
        }   
    }
}

#----------[Set & Validate] ---

# URI
if (!$tenant) {
    $tenant = UserPrompt "Tenant" "Enter tenant URI.`n`nFormat:`thttps://test123.awmdm.com"
}

# Validate URI
if ($tenant -notmatch '(https)?(:\/\/)?[-a-zA-Z0-9.]{2,256}\.[a-z]{2,6}\b[-a-zA-Z0-9@:%_\+.~#?&//=]*'){
    Write-Output " - Invalid URI"
    break
}

# Api key
if (!$awTenantCode) {
    $awTenantCode = UserPrompt "AwTenantCode" "Enter API Key`n`nAvailable in System/Advanced/API"
}

# Validate key
if ($awTenantCode -eq ''){
    Write-Output " - Invalid API key"
    break
}

# Action
if (!$action) {
    try {
        [Validateset('GET', 'DELETE')][string]$action = UserPrompt "Enter REST Method" "Valid methods are: GET or DELETE"
    }catch{
        Write-Output " - Invalid action"
        break
    }
}

#----------[Execution] --- 

SecStrCred .\auth.clixml                    # Check for API-credentials, set if missing
$base64 = AuthToBase64 .\auth.clixml        # Decrypt API-credentials (with svc acc), convert to Base64
$header = SetHeaders $awTenantCode $base64  # Set headers for API authentication
Start-Transcript -Path $PSScriptRoot\log\transcript.txt # -Append # Uncomment to append instead of overwrite log 
ReadyGetDelete $action $tenant $header      # Run with GET or DELETE as action
Stop-Transcript