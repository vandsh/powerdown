# find the path to the desktop folder:
$contentFolder = Get-Item -Path 'content'
$outputFolder = Get-Item -Path 'output'
$template = Get-Item -Path 'template.html'

# specify which files you want to monitor
$fileFilter = '*'  

# specify whether you want to monitor subfolders as well:
$IncludeSubfolders = $true

# specify the file or folder properties you want to monitor:
# https://docs.microsoft.com/en-us/dotnet/api/system.io.notifyfilters?view=net-6.0
$attributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite, [IO.NotifyFilters]::DirectoryName

# lister loop timeout in seconds
$listerTimeout = 1

$animation = @"
(>'-')>
#
<('-'<)
"@

$frames = $animation.Split("#").Trim()

try
{
  $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
    Path = $contentFolder
    Filter = $fileFilter
    IncludeSubdirectories = $IncludeSubfolders
    NotifyFilter = $attributeFilter
  }

  $action = {
    # change type information:
    $details = $event.SourceEventArgs
    $messageData = $event.MessageData
    $Name = $details.Name
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $OldName = $details.OldName

    # type of change:
    $ChangeType = $details.ChangeType
    
    # when the change occured:
    $Timestamp = $event.TimeGenerated
    
    # info logging:
    # $text = "{0} was {1} at {2}. Full Path: {3} Old Path: {4}" -f $FullPath, $ChangeType, $Timestamp, $FullPath ,$OldFullPath
    # Write-Host ""
    # Write-Host $text -ForegroundColor DarkYellow
    
    # get related path of whatever item changed...
    $relativePath = $FullPath.Replace($messageData.contentFolder, '');
    $outputPath = Join-Path -Path $messageData.outputFolder -ChildPath $relativePath
    
    # logic block:
    switch ($ChangeType)
    {
      'Changed'  {
        if([IO.Path]::GetExtension($relativePath) -eq '.md'){
            $outputPath = [io.path]::ChangeExtension($outputPath, "html")
            $text = "`r{0} changed, updating {1}" -f $Name, $outputPath
            Write-Host $text -ForegroundColor Blue
            $content = (ConvertFrom-Markdown -Path $FullPath).Html
            (Get-Content -Path $messageData.template) -f $content | Set-Content -Path $outputPath
        }
        else{
            $text = "`r{0} created, creating {1}" -f $Name, $outputPath
            Write-Host $text -ForegroundColor Green
            Get-Content -Path $FullPath | Set-Content -Path $outputPath
        }
      }
      'Created'  {
        if([IO.Path]::GetExtension($relativePath) -eq '.md'){
            $outputPath = [io.path]::ChangeExtension($outputPath, "html")
            $text = "`r{0} created, creating {1}" -f $Name, $outputPath
            Write-Host $text -ForegroundColor Green
            New-Item -Force -Path $outputPath
            $content = (ConvertFrom-Markdown -Path $FullPath).Html
            (Get-Content -Path $messageData.template) -f $content | Set-Content -Path $outputPath
        }
        else{
            $text = "`r{0} created, creating {1}" -f $Name, $outputPath
            Write-Host $text -ForegroundColor Green
            Copy-Item -Force -Path $FullPath -Destination $outputPath
        }
      }
      'Deleted'  { 
        if([IO.Path]::GetExtension($relativePath) -eq '.md'){
            $outputPath = [io.path]::ChangeExtension($outputPath, "html")
        }
        $text = "`r{0} deleted, deleting {1}" -f $Name, $outputPath
        Write-Host $text -ForegroundColor Gray
        Remove-Item -Path $outputPath -Force -Recurse -Confirm:$false
      }
      'Renamed'  { 
        $outputPathOld = Join-Path -Path $messageData.outputFolder -ChildPath ($OldFullPath.Replace($messageData.contentFolder, ''))
        if([IO.Path]::GetExtension($relativePath) -eq '.md'){
            $outputPath = [io.path]::ChangeExtension($outputPath, "html")
            $outputPathOld = [io.path]::ChangeExtension($outputPathOld, "html")
            $Name = [io.path]::ChangeExtension($Name, "html")
        }
        $text = "`r{0} renamed to {1}" -f $OldName, $Name
        Write-Host $text -ForegroundColor Yellow
        Rename-item -Path $outputPathOld -NewName $Name -Force
      }
        
      # fallthru:
      default   { Write-Host $_ -ForegroundColor Red -BackgroundColor White }
    }
  }

  # tying up eventhandlers
  $handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action -MessageData @{contentFolder = $contentFolder; outputFolder = $outputFolder; template = $template}
    Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action -MessageData @{contentFolder = $contentFolder; outputFolder = $outputFolder; template = $template}
    Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action -MessageData @{contentFolder = $contentFolder; outputFolder = $outputFolder; template = $template}
    Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action -MessageData @{contentFolder = $contentFolder; outputFolder = $outputFolder; template = $template}
  }
  $watcher.EnableRaisingEvents = $true
  Write-Host "Watching for changes..."

  # endless listener loop:
  do
  {
    Wait-Event -Timeout $listerTimeout
    $frame = $frames[(get-date).Second % 2]
    Write-Host "`r$frame" -NoNewline
  } while ($true)
}
finally
{
  # this gets executed when user presses CTRL+C:
  $watcher.EnableRaisingEvents = $false
  $handlers | ForEach-Object {
    Unregister-Event -SourceIdentifier $_.Name
  }
  $handlers | Remove-Job
  $watcher.Dispose()
  Write-Warning "Stopping listening..."
}