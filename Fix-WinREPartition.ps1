## fix annoying WinRE WU issue ##
#https://support.microsoft.com/en-us/topic/kb5028997-instructions-to-manually-resize-your-partition-to-install-the-winre-update-400faa27-9343-461c-ada9-24c8229763bf


# find the WinRE partition and volume
$reVol = Get-Partition | Where-Object Type -eq 'Recovery'

if ( -NOT $reVol ) {
    throw "Recovery partition not found."
}


# get the system colume
$sysDrvLtr = $env:SystemDrive.Trim(':')
$sysVol = Get-Partition -DriveLetter $sysDrvLtr

# disable WinRE
reagentc /disable


# shrink the system volume
$newSize = $sysVol.Size -250MB
Resize-Partition -DiskNumber $sysVol.DiskNumber -PartitionNumber $sysVol.PartitionNumber -Size $newSize

# delete the WinRE partition
Remove-Partition -DiskNumber $reVol.DiskNumber -PartitionNumber $reVol.PartitionNumber -Confirm:$false

# now create the new WinRE partition
$newPart = New-Partition -DiskNumber $reVol.DiskNumber -UseMaximumSize -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"

# format the volume
Format-Volume -Partition $newPart -FileSystem NTFS -NewFileSystemLabel "Windows RE tools" -Force

# set GPT attributes
$null = @"
select disk $($newPart.DiskNumber)
select partition $($newPart.PartitionNumber)
gpt attributes=0x8000000000000001
exit
"@ | diskpart.exe

# enable WinRE
reagentc /enable

