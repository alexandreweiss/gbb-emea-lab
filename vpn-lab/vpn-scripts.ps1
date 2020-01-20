# Start packet capture on a connection
param(
    [string]
    $myRgName = "er-lab",

    [string]
    $myVnetGwName = "frc-vpn-gw",

    [string]
    $myConnectionName = "frc-vpn-gw-er-hub-vpnsite-lng"
)



# Packet capture
# Configure the filter to be on ICMP only with a source of 192.168.202.0/24
$captureFilter = "{`"TracingFlags`": 11,`"MaxPacketBufferSize`": 120,`"MaxFileSize`": \500,`"Filters`" :[{`"SourceSubnets`": [`"192.168.202.0/24`"],`"DestinationSubnets`": [`"192.168.201.0/24`"],`"SourcePort`": [450],`"DestinationPort`": [4500],`"TcpFlags`": -1,`"Protocol`": [6],`"CaptureSingleDirectionTrafficOnly`": true}]}"

# Start the capture at the GW level using the filter
Start-AzVirtualnetworkGatewayPacketCapture -ResourceGroupName $myRgName -Name $myVnetGwName -FilterData $captureFilter

# # 5 minute later ... we stop the capture
# Obtain the SAS token for the GW to push the pcap capture file to
# Name of the storage account and container to output capture file to
$storageName = "frcdiagsa"
$containerName = "vpn-diags"
# Retreive the storage account keys
$key = Get-AzStorageAccountKey -ResourceGroupName $myRgName -Name $storageName
# Create the storage account context
$context = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $key[0].Value
# Create the new container that will receive the capture file
New-AzStorageContainer -Name $containerName -Context $context
# Get current date to calculate the token validity period
$now = Get-Date
# Generate the SAS URL
$sasurl = New-AzStorageContainerSASToken -Name $containerName -Context $context -Permission "rwd" -StartTime $now.AddHours(-1) -ExpiryTime $now.AddDays(1) -FullUri

# Send the stop command
Stop-AzVirtualNetworkGatewayPacketCapture -ResourceGroupName $myRgName -Name $myVnetGwName -SasUrl $sasurl


#### VPN P2S MFA

# Create the VPN Entreprise application in your subscription by connecting to the below URL
https://login.microsoftonline.com/common/oauth2/authorize?client_id=41b23e61-6c1e-4545-b367-cd054e0ed4b4&response_type=code&redirect_uri=https://portal.azure.com&nonce=1234&prompt=admin_consent

# Point the VPN GW to AAD
$gw = Get-AzVirtualNetworkGateway -Name $myVnetGwName -ResourceGroupName $myRgName
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -VpnClientRootCertificates @()
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -AadTenantUri "https://login.microsoftonline.com/c2230db6-ebec-4e14-b8a8-fd4175203abd" -AadAudienceId "41b23e61-6c1e-4545-b367-cd054e0ed4b4" -AadIssuerUri "https://sts.windows.net/c2230db6-ebec-4e14-b8a8-fd4175203abd/" -VpnClientAddressPool 10.10.0.0/27 -VpnClientProtocol OpenVPN

# Create and download the profile
$profile = New-AzVpnClientConfiguration -Name $myVnetGwName -ResourceGroupName $myRgName -AuthenticationMethod "EapTls"
$profile.VpnProfileSASUrl