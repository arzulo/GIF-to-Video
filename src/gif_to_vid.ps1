# Handle input parameter if we are doing ProRes or MP4 codec
# Acceptable answers currently
# - h.264
# - prores
param (
    [string]$codec = "h.264"
)
Add-Type -AssemblyName System.Windows.Forms

# Set the environment paths to contain the common Aseprite.exe locations so we can access aseprite executable
$ffmpeg_dir = $PSScriptRoot
Set-Location -Path $ffmpeg_dir

# Default properties
$user = [Environment]::UserName
$envFile = ".env_$user"
$prevPathProp = "prev_path"
$pwd = Get-Location
$envFilePath = "$pwd\$envFile"
$outputFolder = "vidOutput"

# Determine container type based on the codec
switch($codec) {
    "prores" { 
        $container = 'mov'
        # FFMPEG properties
        # $frameRate = 23.976
        $defaultFrameRate = 60;
        $frameRate= Read-Host -Prompt "Output framerate? [default: $defaultFrameRate]"
        if ([string]::IsNullOrWhiteSpace($frameRate)) { $frameRate= $defaultFrameRate}
        break
    }
    Default {
        $container = 'mp4'
    }
}

# Determine initial directory
If (Test-Path $envFilePath) {
    # Read in the JSON
    $json = Get-Content -Path $envFilePath -Raw | ConvertFrom-Json
    $initDir = $json."$prevPathProp"
} 
Else {
    $initDir = [Environment]::GetFolderPath('Desktop')
}


# Create a file browser dialog to select the file
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
	#InitialDirectory = $initDir
    Multiselect = $true
	RestoreDirectory = $true
	Filter ='Gif (*.gif)|*.gif' }
$null = $FileBrowser.ShowDialog()

# Get path for the first file used to create output path
$filePath = $FileBrowser.FileName
# Get path for folder it sits in
$folderPath = Split-Path -Path $filePath

# Save folder path of chosen file to .env file
# Create JSON
#$obj = @{ $prevPathProp = $folderPath}
#$obj | ConvertTo-Json | Set-Content -Path "$pwd/$envFile"

# Create the output folder for the aseprite export
$exportPath = "$folderPath\$outputFolder"
If(!(test-path $exportPath))
{
      New-Item -ItemType Directory -Force -Path $exportPath
}

# Do the aseprite export (out null makes it so that the export completes before moving to ffmpeg)
# aseprite.exe -b $filePath --scale $outputScale --save-as "$exportPath\img.png" | Out-Null

# Loop through each file selected and do the conversion 
Foreach ($file in $FileBrowser.FileNames) {
    try {
        # Determine the name of the file
        # $output_name = "$(Get-Date -Format 'yyyy_ddMM_HHmmss')_$((Split-Path -Leaf $file).replace('.gif',"".${container}""))"
        $output_name = "$((Split-Path -Leaf $file).replace('.gif',""_$(Get-Date -Format 'yyyy_ddMM_HHmmss').${container}""))"
        "Starting conversion for $file..."
   
        # Determine container type based on the codec
        switch($codec) {
            "prores" { 
                # This version is for .mov container and Apple ProRes4444 codec to support alpha channels in Da Vinci
                .\ffmpeg.exe -loglevel error -i $file -c:v prores_ks -profile:v 4444 -c:a aac -strict experimental -b:a 192k -pix_fmt argb -r $frameRate "$exportPath\${output_name}" -y  # THIS ONE IS THE WINNER WINNER CHICKEN DINNER
                break
            }
            Default {
                # This version is for generic twitter exports and .mp4 container
                # h.264 container needs to have height and width divisible by 2, so truncate...
                # Don't specify framerate so that it takes on the original framerate of the design
                .\ffmpeg.exe -hide_banner -loglevel error -i $file -c:a aac -pix_fmt yuv420p -c:v libx264 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -crf 15 "$exportPath\$output_name" -y
            }
        }

    } catch {
        "An error occured with ffmpeg. Please read above"
        read-host "Press ENTER to continue..."
    }
    if($LASTEXITCODE -ne 0) {
        "An error occured with ffmpeg. Please read above"
        "File: $file"
        read-host "Press ENTER to continue..."
    } else {
        "Succesfully converted file: $output_name!"
        "--------------------"
        "--------------------"
    }

}

"All done!"
"Window will automatically close in 4 seconds"
Start-Sleep -Seconds 4


### OLD EXPORT TYPES
#.\ffmpeg.exe -hide_banner -loglevel error -i $filePath -vf yuv420p -c:a aac -pix_fmt yuv420p -vb 10000M "$exportPath\$outputName.mp4" -y
#.\ffmpeg.exe -hide_banner -loglevel error -i $filePath -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 23 -maxrate 4M -bufsize 4M "$exportPath\$outputName.mp4" -y
#.\ffmpeg.exe -hide_banner -loglevel error -i $file -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 23 -maxrate 4M -bufsize 4M -r $frameRate "$exportPath\$output_name" -y
#.\ffmpeg.exe -loglevel error -i $file -sws_flags neighbor -c:v qtrle -c:a aac -strict experimental -b:a 192k -pix_fmt argb "$exportPath\$output_name" -y  # THIS ONE IS THE WINNER WINNER CHICKEN DINNER
# .\ffmpeg.exe -loglevel error -i $file -c:v libx265 -pix_fmt yuva420p "$exportPath\$output_name" -y 
#.\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 0  -r 23.976 "$exportPath\$output_name" -y 
#.\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:a aac -pix_fmt yuv420p -c:v libx265 -preset veryslow -qp 0  -r 23.976 "$exportPath\$output_name" -y 
#.\ffmpeg.exe -hide_banner -loglevel error -i $file -i color=95FF00 -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1" -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 23 -maxrate 4M -bufsize 4M -r $frameRate "$exportPath\$output_name" -y
#.\ffmpeg.exe -hide_banner -loglevel error -i $file -filter_complex "color=95FF00:s=200x200[bg];[bg][0]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=format=auto:shortest=1[out]" -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 23 -maxrate 4M -bufsize 4M -r $frameRate "$exportPath\$output_name" -y
#.\ffmpeg.exe -i input.gif -filter_complex "color=95FF00:s=WIDTHxHEIGHT[bg];[bg][0]overlay=format=auto:shortest=1[out]" -c:a aac -c:v libx264 -pix_fmt yuv420p -crf 23 -r 30 output.mp4
#.\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 15 -maxrate 4M -bufsize 4M -r 23.976 "$exportPath\$output_name" -y 
#.\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:a aac -pix_fmt yuv420p -c:v libx264 -crf 15 -r 23.976 "$exportPath\$output_name" -y 
# .\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:v libx264 -crf 0 -preset veryslow -c:a aac -strict experimental -b:a 192k "$exportPath\$output_name" -y 
# .\ffmpeg.exe -f gif -f lavfi -hide_banner -loglevel error -i color=95FF00 -i $file -sws_flags neighbor -filter_complex "[0][1]scale2ref[bg][gif];[bg]setsar=1[bg];[bg][gif]overlay=shortest=1,scale=w='2*trunc(iw/2)':h='2*trunc(ih/2)'" -c:v libx264 -crf 0 -preset veryslow -c:a aac -strict experimental -b:a 192k "$exportPath\$output_name" -y 
# .\ffmpeg.exe -loglevel error -i $file -sws_flags neighbor -c:v libx264 -crf 0 -pix_fmt rgba -preset veryslow -c:a aac -strict experimental -b:a 192k "$exportPath\$output_name" -y 