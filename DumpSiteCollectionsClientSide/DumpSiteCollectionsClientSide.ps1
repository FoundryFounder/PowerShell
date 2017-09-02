<#
   DumpSiteCollectionsClientSide.ps1
   Displays all property values for all O365 site collections.  Run on client.
   Copyright © 2017 John Huschka, Collaboration Foundry, www.collaboration-foundry.com
   August 15, 2017
#>

<#  DumpObjectProperties:  Displays all property values, sorted by property name, of a 
     parameter supplied object
#>
function DumpObjectProperties($objectToDump){
   write-host $objectToDump -ForegroundColor Cyan
   <#  "Get-Member" selects the name of every property on the object, and the output
         is passed into a Sort-Object, creating an alphabetical list of properties.
        We loop through the property names, using select-object to get the property value, 
         format-list to format its display, and Out-String to put it into a string.  
        We do one property at a time so that an exception resulting from an uninitialized
         property only impacts the display of one property.  #>
   
   $propertyNames = $($objectToDump | Get-Member -MemberType Property | %{ $_.Name } | Sort-Object)

   foreach ($propertyName in $propertyNames){
     $propertyNameArray = @($PropertyName)
     try{
       write-host ($objectToDump | format-list -Property $propertyNameArray | Out-String).trim()
     }
     catch{
       write-host "$propertyName : *** Unitialized ***"
     }
   }
}

Add-Type -Path 'Microsoft.SharePoint.Client.dll'
Add-Type -Path 'Microsoft.SharePoint.Client.Runtime.dll'

# Tenant Administration URL (e.g., Acme-admin.SharePoint.com)
$site = Read-Host 'Enter Tenant SharePoint admin site URL'

# Admin User Name
$admin = Read-Host 'Enter Admin User'

# Get Password as secure String
$password = Read-Host 'Enter Password' -AsSecureString

$O365Credential = New-Object System.Management.Automation.PsCredential($admin, $password)
$SPOCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)

Connect-SPOService –url  $site –Credential $O365Credential

# Retrieve O365 site objects.
$sites = Get-SPOSite 

<# For each O365 site object, retrieve the equivalent SharePoint site object.  Display 
    properties of both.  #>
foreach ($site in $sites)
{
    write-host `r`nO365 SITE $site.Url -BackgroundColor Red
    DumpObjectProperties $site

    $context = New-Object Microsoft.SharePoint.Client.ClientContext($site.Url)
    $context.Credentials = $SPOCredentials
    $spSite = $context.Site
    $context.load($spSite)

    <#  Loading the site will leave the proerties that are collections uninitialized.
         Therefore, we explicitly initialize collection properties.  
        Have experienced issues with permissions on specific properties.  Therefore, 
         we are doing an ExecuteQuery for each property.  #>
    $context.load($spSite.EventReceivers)
    $context.ExecuteQuery()
    $context.load($spSite.Features)
    $context.ExecuteQuery()

    <#  For at least some site collections (O365 groups), you must be an owner to access the RecycleBin.  #>
    $context.load($spSite.RecycleBin)
    $context.ExecuteQuery()
    $context.load($spSite.UserCustomActions) 
    $context.ExecuteQuery()

    write-host `r`nSHAREPOINT SITE $site.Url -BackgroundColor Red
    DumpObjectProperties $spSite
}

Disconnect-SPOService