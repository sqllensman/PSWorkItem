Function Get-PSWorkItem {
    [cmdletbinding(DefaultParameterSetName = "days")]
    [alias('gwi')]
    [outputType('PSWorkItem')]
    Param(
        [Parameter(
            Position = 0,
            HelpMessage = "The name of the work item. Wilcards are supported.",
            ValueFromPipelineByPropertyName,
            ParameterSetName = "name"
        )]
        [ValidateNotNullOrEmpty()]
        [alias("task")]
        [string]$Name,

        [Parameter(
            HelpMessage = "The task ID.",
            ValueFromPipelineByPropertyName,
            ParameterSetName = "id"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ID,

        [Parameter(
            HelpMessage = "Get open tasks due in the number of days between 1 and 365.",
             ParameterSetName = "days"
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 365)]
        [int]$DaysDue = 10,

        [Parameter(
            HelpMessage = "Get all open tasks",
            ParameterSetName = "all"
        )]
        [switch]$All,

        [Parameter(
            HelpMessage = "Get all open tasks by category",
            ParameterSetName = "category"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Category,

        [Parameter(HelpMessage = "The path to the PSWorkitem SQLite database file. It should end in .db")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("\.db$")]
        [ValidateScript({
            if (Test-Path $_) {
                Return $True
            }
            else {
                Throw "Failed to validate $_"
                Return $False
            }
            })]
        [string]$Path = $PSWorkItemPath
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] $($myinvocation.mycommand): Starting "
    } #begin

    Process {
        Switch ($PScmdlet.ParameterSetName) {
            "all" {$query = "Select *,RowID from tasks"}
            "category" {$query = "Select *,RowID from tasks where category ='$Category' collate nocase"}
            "days" {
                $d = (Get-Date).AddDays($DaysDue)
                $query = "Select *,RowID from tasks where duedate <= '$d' collate nocase"
            }
            "id" {$query = "Select *,RowID from tasks where RowID ='$ID'"}
            "name" {
                if ($Name -match "\*") {
                    $Name = $name.replace("*","%")
                    $query = "Select *,RowID from tasks where name like '$Name' collate nocase"
                }
                else {
                    $query = "Select *,RowID from tasks where name = '$Name' collate nocase"
                }
            }
        }

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($myinvocation.mycommand): $query"
        $tasks = invoke-MySQLiteQuery -query $query -Path $Path
        if ($tasks.count -gt 0) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($myinvocation.mycommand): Found $($tasks.count) matching tasks"
           $results = foreach ($task in $tasks) {
            _newWorkItem $task
           }
           $results | Sort-Object -Property DueDate
        }
        else {
            Write-Warning "Failed to find any matching tasks"
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] $($myinvocation.mycommand): Ending."
    } #end

}
