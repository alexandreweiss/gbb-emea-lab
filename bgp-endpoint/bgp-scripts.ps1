param(
    [string]
    $myRgName = "er-lab",

    [string]
    $myVnetGwName = "frc-er-gw"

)
# Variables
$peerName = "groupNva"
$peerIp = "192.168.200.36" # er-hub-router
$peerAsn = "64100"

# Get the ER gateway
$gw = Get-AzVirtualNetworkGateway -Name $myVnetGwName -ResourceGroupName $myRgName

# Enable BGP support
$virtualRouterName = "bgp-router"
#New-AzVirtualRouter -Name $virtualRouterName -ResourceGroupName $myRgName -Location $gw.Location -HostedGateway $gw

# Create the eBGP session
#Add-AzVirtualRouterPeer -PeerName $peerName -PeerIp $peerIp -PeerAsn $peerAsn -VirtualRouterName $virtualRouterName -ResourceGroupName $myRgName
#Update-AzVirtualRouterPeer -PeerName $peerName -PeerIp $peerIp -PeerAsn $peerAsn -VirtualRouterName $virtualRouterName -ResourceGroupName $myRgName

# View configuration
Get-AzVirtualRouter -RouterName $virtualRouterName -ResourceGroupName $myRgName

# Get routes
#Get-AzVirtualNetworkGatewayAdvertisedRoute -VirtualNetworkGatewayName $myVnetGwName -ResourceGroupName $myRgName | ft *
Get-AzVirtualNetworkGatewayLearnedRoute -VirtualNetworkGatewayName $myVnetGwName -ResourceGroupName $myRgName | ft *
