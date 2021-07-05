$client_id = ""
$client_secret = ""
$grant_type = "client_credentials"



$username = ""




#new token

$result = Invoke-RestMethod -Method 'Post' -Uri "https://id.twitch.tv/oauth2/token?client_id=$client_id&client_secret=$client_secret&grant_type=$grant_type" 

Write-Host "new token: $result"


#validate token

$access_token = $result.access_token

$headers = @{ 'Authorization'="Bearer $access_token" }

$result = Invoke-RestMethod -Uri "https://id.twitch.tv/oauth2/validate" -Headers $headers

Write-Host "validating: $result"



$headers = @{ 'client-id'=$client_id; 'Authorization'="Bearer $access_token" }

$result = Invoke-RestMethod -Uri "https://api.twitch.tv/helix/users?login=$username" -Headers $headers

Write-Host "user: $result"

$user_id = $result.data[0].id


$result = Invoke-RestMethod -Uri "https://api.twitch.tv/helix/clips?broadcaster_id=$user_id&first=100" -Headers $headers

Write-Host "clips: $result"

$clips = @()

$clips += $result.data

$cursor = $result.pagination.cursor

while($result.data.Length -eq 100){

    $result = Invoke-RestMethod -Uri "https://api.twitch.tv/helix/clips?broadcaster_id=$user_id&first=100&after=$cursor" -Headers $headers

    Write-Host "clips: $result"

    $cursor = $result.pagination.cursor

    $clips += $result.data

}

Write-Host "count: $($clips.Length)"

$names = @{}

for($i = 0; $i -lt $clips.Length; $i++){

    $download_url = $clips[$i].thumbnail_url;

    $index = $download_url.IndexOf("-preview")

    $download_url = $download_url.Substring(0, $index) + ".mp4"

    $title = $clips[$i].title.trim()

    $title = $title.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

    $title = $title.replace('[','')
    
    $creator_name = $clips[$i].creator_name

    $path = "$env:UserProfile\Documents\$username\$title - $creator_name.mp4"

    $names["$title - $creator_name.mp4"]++

    $time = $clips[$i].created_at

    if($names["$title - $creator_name.mp4"] -gt 1){

        $time = $time.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $path = "$env:UserProfile\Documents\$username\$title - $creator_name - $time.mp4"
        

    }

    if((Test-Path -Path $path -PathType Leaf) -eq $false){

        #Write-Host "download: $download_url"
        Write-Host "save: $path"
        Invoke-WebRequest -Uri $download_url -UseBasicParsing -OutFile ( New-Item -Path $path )

    }
    
}


<#
$table = @{}

for($i = 0; $i -lt $clips.Length; $i++){

    $table[$clips[$i].creator_name] ++

}
#>


#revoke

$result = Invoke-RestMethod -Method 'Post' -Uri "https://id.twitch.tv/oauth2/revoke?client_id=$client_id&token=$access_token" 

Write-Host "revoking: $result"
