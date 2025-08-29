<#
.SYNOPSIS
    Retrieves the URL of a Brightcove video.

.DESCRIPTION
    This function retrieves the URL of a Brightcove video based on the provided AccountID, VideoID, and optional PlayerID.

.PARAMETER AccountID
    The Brightcove account ID.

.PARAMETER VideoID
    The ID of the Brightcove video.

.PARAMETER PlayerID
    The ID of the Brightcove player. If not specified, the default player will be used.

.EXAMPLE
    Get-BrightcoveVideoUrl -AccountID "1712641351001" -VideoID "6232757450011" -PlayerID "default"
    Retrieves the URL of the Brightcove video with the specified AccountID, VideoID, and PlayerID.

.NOTES
    https://www.cisdem.com/resource/download-brightcove-videos.html
#>

function Get-BrightcoveVideoUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccountID,
        [Parameter(Mandatory = $true)]
        [string]$VideoID,
        [Parameter(Mandatory = $false)]
        [string]$PlayerID
    )

    if (-not $PlayerID) {
        $PlayerID = "default"
    }

    $url = "http://players.brightcove.net/${AccountID}/${PlayerID}_default/index.html?videoId=${VideoID}"
    $url
}
