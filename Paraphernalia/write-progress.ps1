#write-progress
#for ($i = 1; $i -le 100; $i++ ) {
     Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i
     Start-Sleep -Milliseconds 25
 #}

  $PSStyle.Progress.View = 'Classic'

for($I = 0; $I -lt 10; $I++ ) {
    $OuterLoopProgressParameters = @{
        Activity         = 'Updating'
        Status           = 'Progress->'
        PercentComplete  = $I * 10
        CurrentOperation = 'OuterLoop'
    }
    Write-Progress @OuterLoopProgressParameters
    for($j = 1; $j -lt 101; $j++ ) {
        $InnerLoopProgressParameters = @{
            ID               = 1
            Activity         = 'Updating'
            Status           = 'Progress'
            PercentComplete  = $j
            CurrentOperation = 'InnerLoop'
        }
        Write-Progress @InnerLoopProgressParameters
        Start-Sleep -Milliseconds 25
    }
}