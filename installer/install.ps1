[CmdletBinding()]
param(
    [Parameter()]
    [string]$Target,

    [Parameter()]
    [string[]]$Adapter
)

$SUCCESS = 0
$GENERAL_ERROR = 1
$INVALID_MANIFEST = 2
$CONFLICT_ABORTED = 3
$PARTIAL_FAILURE = 4
$UNSUPPORTED_ADAPTER = 5
$INVALID_TARGET = 6

function Fail([int]$Code, [string]$Message) {
    [Console]::Error.WriteLine("error: $Message")
    exit $Code
}

function Normalize-RelativePath([string]$Path) {
    return $Path.Replace('\', '/').Trim('/')
}

function Test-RelativePath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ([System.IO.Path]::IsPathRooted($Path)) { return $false }
    if ($Path -match '^[A-Za-z]:[\\/]') { return $false }
    foreach ($part in ($Path.Replace('\', '/') -split '/')) {
        if ($part -eq '..') { return $false }
    }
    return $true
}

function Join-ProjectPath([string]$Root, [string]$RelativePath) {
    if (-not (Test-RelativePath $RelativePath)) {
        throw "invalid relative path: $RelativePath"
    }

    $result = $Root
    foreach ($part in (Normalize-RelativePath $RelativePath -split '/')) {
        if (-not [string]::IsNullOrWhiteSpace($part)) {
            $result = [System.IO.Path]::Combine($result, $part)
        }
    }
    return $result
}

function Read-Manifest([string]$Path) {
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $lines = $text -split '\r?\n'
    $manifest = @{
        name = $null
        version = $null
        runtime = @{}
        bootstrap = @{}
        mappings = New-Object System.Collections.ArrayList
        adapters = @{}
    }
    $section = ''
    $currentMapping = $null
    $currentAdapter = $null

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^\s*#') { throw "comments are not supported in Manifest" }

        if ($line -match '^name:\s*(\S+)\s*$') {
            $manifest.name = $Matches[1]
            $section = ''
            continue
        }
        if ($line -match '^version:\s*(\S+)\s*$') {
            $manifest.version = $Matches[1]
            $section = ''
            continue
        }
        if ($line -match '^runtime:\s*$') {
            $section = 'runtime'
            continue
        }
        if ($line -match '^bootstrap:\s*$') {
            $section = 'bootstrap'
            continue
        }
        if ($line -match '^mappings:\s*$') {
            $section = 'mappings'
            $currentMapping = $null
            continue
        }
        if ($line -match '^adapters:\s*$') {
            $section = 'adapters'
            $currentAdapter = $null
            continue
        }

        if ($section -eq 'runtime' -and $line -match '^  ([A-Za-z0-9_-]+):\s*(\S+)\s*$') {
            $manifest.runtime[$Matches[1]] = $Matches[2]
            continue
        }
        if ($section -eq 'bootstrap' -and $line -match '^  ([A-Za-z0-9_-]+):\s*(\S+)\s*$') {
            $manifest.bootstrap[$Matches[1]] = $Matches[2]
            continue
        }

        if ($section -eq 'mappings' -and $line -match '^  - source:\s*(\S+)\s*$') {
            $currentMapping = @{
                source = $Matches[1]
                target = $null
                owner = $null
                update_policy = $null
                conflict_policy = $null
            }
            [void]$manifest.mappings.Add($currentMapping)
            continue
        }
        if ($section -eq 'mappings' -and $null -ne $currentMapping -and $line -match '^    ([A-Za-z0-9_-]+):\s*(\S+)\s*$') {
            $currentMapping[$Matches[1]] = $Matches[2]
            continue
        }

        if ($section -eq 'adapters' -and $line -match '^  ([A-Za-z0-9-]+):\s*$') {
            $currentAdapter = @{
                status = $null
                source = $null
                target = $null
                owner = $null
                update_policy = $null
                conflict_policy = $null
            }
            $manifest.adapters[$Matches[1]] = $currentAdapter
            continue
        }
        if ($section -eq 'adapters' -and $null -ne $currentAdapter -and $line -match '^    ([A-Za-z0-9_-]+):\s*(\S+)\s*$') {
            $currentAdapter[$Matches[1]] = $Matches[2]
            continue
        }

        throw "unrecognized or malformed manifest line: $line"
    }

    if ([string]::IsNullOrWhiteSpace($manifest.name) -or
        [string]::IsNullOrWhiteSpace($manifest.version) -or
        [string]::IsNullOrWhiteSpace($manifest.runtime['source_root']) -or
        [string]::IsNullOrWhiteSpace($manifest.runtime['target_root']) -or
        [string]::IsNullOrWhiteSpace($manifest.bootstrap['source']) -or
        [string]::IsNullOrWhiteSpace($manifest.bootstrap['target']) -or
        $manifest.mappings.Count -eq 0) {
        throw 'required Manifest field is missing'
    }

    foreach ($field in @('owner', 'update_policy', 'conflict_policy')) {
        if ([string]::IsNullOrWhiteSpace($manifest.bootstrap[$field])) {
            throw "bootstrap field is missing: $field"
        }
    }
    if ($manifest.bootstrap.owner -ne 'harness' -or
        $manifest.bootstrap.update_policy -ne 'managed' -or
        $manifest.bootstrap.conflict_policy -ne 'abort_on_user_change') {
        throw 'bootstrap policy is invalid'
    }

    foreach ($mapping in $manifest.mappings) {
        foreach ($field in @('source', 'target', 'owner', 'update_policy', 'conflict_policy')) {
            if ([string]::IsNullOrWhiteSpace($mapping[$field])) {
                throw "mapping field is missing: $field"
            }
        }
        if ($mapping.owner -ne 'harness' -or
            $mapping.update_policy -ne 'managed' -or
            $mapping.conflict_policy -ne 'abort_on_user_change') {
            throw 'runtime mapping policy is invalid'
        }
    }

    foreach ($entry in $manifest.adapters.GetEnumerator()) {
        foreach ($field in @('status', 'owner', 'update_policy', 'conflict_policy')) {
            if ([string]::IsNullOrWhiteSpace($entry.Value[$field])) {
                throw "adapter field is missing: $($entry.Key).$field"
            }
        }
        if ($entry.Value.owner -ne 'adapter' -or
            $entry.Value.update_policy -ne 'managed' -or
            $entry.Value.conflict_policy -ne 'abort_on_user_change') {
            throw "adapter policy is invalid: $($entry.Key)"
        }
        if ($entry.Value.status -eq 'stable') {
            $hasSource = -not [string]::IsNullOrWhiteSpace($entry.Value.source)
            $hasTarget = -not [string]::IsNullOrWhiteSpace($entry.Value.target)
            if ($hasSource -ne $hasTarget) {
                throw "stable adapter entry point is incomplete: $($entry.Key)"
            }
        }
    }

    return [PSCustomObject]$manifest
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-VersionRecord([string]$Path) {
    $record = @{
        name = $null
        version = $null
        hashes = @{}
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [PSCustomObject]$record
    }

    $lines = [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
    $currentPath = $null
    foreach ($line in $lines) {
        if ($line -match '^name:\s*(\S+)\s*$') {
            $record.name = $Matches[1]
        } elseif ($line -match '^version:\s*(\S+)\s*$') {
            $record.version = $Matches[1]
        } elseif ($line -match '^  - path:\s*(\S+)\s*$') {
            $currentPath = Normalize-RelativePath $Matches[1]
        } elseif ($null -ne $currentPath -and $line -match '^    sha256:\s*([0-9A-Fa-f]{64})\s*$') {
            $record.hashes[$currentPath] = $Matches[1].ToLowerInvariant()
            $currentPath = $null
        }
    }
    return [PSCustomObject]$record
}

try {
    $repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    $manifestPath = Join-Path $repositoryRoot 'manifest/harness.yaml'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Fail $INVALID_MANIFEST 'manifest not found'
    }

    try {
        $manifest = Read-Manifest $manifestPath
    } catch {
        Fail $INVALID_MANIFEST $_.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $targetPath = (Get-Location).Path
    } else {
        $targetPath = $Target
    }
    if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
        Fail $INVALID_TARGET "target is not a directory: $targetPath"
    }
    $targetPath = (Resolve-Path -LiteralPath $targetPath).Path
    $repositoryPath = (Resolve-Path -LiteralPath $repositoryRoot).Path
    if ($targetPath -eq $repositoryPath) {
        Fail $INVALID_TARGET 'refusing to install into the Harness source repository'
    }

    $sourceRootRelative = Normalize-RelativePath $manifest.runtime['source_root']
    $targetRootRelative = Normalize-RelativePath $manifest.runtime['target_root']
    if (-not (Test-RelativePath $sourceRootRelative) -or
        -not (Test-RelativePath $targetRootRelative)) {
        Fail $INVALID_MANIFEST 'runtime roots must be relative paths'
    }

    $managedFiles = New-Object System.Collections.ArrayList
    $bootstrapSource = Normalize-RelativePath $manifest.bootstrap.source
    $bootstrapTarget = Normalize-RelativePath $manifest.bootstrap.target
    if (-not (Test-RelativePath $bootstrapSource) -or
        -not (Test-RelativePath $bootstrapTarget)) {
        Fail $INVALID_MANIFEST 'invalid bootstrap path'
    }
    $bootstrapSourcePath = Join-ProjectPath $repositoryRoot $bootstrapSource
    if (-not (Test-Path -LiteralPath $bootstrapSourcePath -PathType Leaf)) {
        Fail $INVALID_MANIFEST "bootstrap source not found: $bootstrapSource"
    }
    [void]$managedFiles.Add([PSCustomObject]@{
        Source = $bootstrapSourcePath
        Target = $bootstrapTarget
    })

    foreach ($mapping in $manifest.mappings) {
        $mappingSource = Normalize-RelativePath $mapping.source
        $mappingTarget = Normalize-RelativePath $mapping.target
        if (-not (Test-RelativePath $mappingSource) -or
            -not (Test-RelativePath $mappingTarget)) {
            Fail $INVALID_MANIFEST "invalid mapping path: $mappingSource -> $mappingTarget"
        }
        if ($mappingSource -ne $sourceRootRelative -and
            -not $mappingSource.StartsWith("$sourceRootRelative/")) {
            Fail $INVALID_MANIFEST "mapping source is outside source_root: $mappingSource"
        }

        $sourceDirectory = Join-ProjectPath $repositoryRoot $mappingSource
        if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
            Fail $INVALID_MANIFEST "mapped source directory not found: $mappingSource"
        }

        foreach ($file in (Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse)) {
            $relative = $file.FullName.Substring($sourceDirectory.Length).TrimStart('\', '/')
            $destinationRelative = Normalize-RelativePath "$mappingTarget/$relative"
            [void]$managedFiles.Add([PSCustomObject]@{
                Source = $file.FullName
                Target = $destinationRelative
            })
        }
    }

    $selectedAdapters = @(
        $Adapter |
            ForEach-Object { $_ -split ',' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    )
    foreach ($adapterName in $selectedAdapters) {
        if (-not $manifest.adapters.ContainsKey($adapterName)) {
            Fail $UNSUPPORTED_ADAPTER "unsupported Adapter: $adapterName"
        }
        $adapterEntry = $manifest.adapters[$adapterName]
        if ($adapterEntry.status -ne 'stable') {
            Fail $UNSUPPORTED_ADAPTER "Adapter is not stable: $adapterName"
        }
        if ([string]::IsNullOrWhiteSpace($adapterEntry.source) -and
            [string]::IsNullOrWhiteSpace($adapterEntry.target)) {
            continue
        }
        $adapterSource = Normalize-RelativePath $adapterEntry.source
        $adapterTarget = Normalize-RelativePath $adapterEntry.target
        if (-not (Test-RelativePath $adapterSource) -or
            -not (Test-RelativePath $adapterTarget)) {
            Fail $INVALID_MANIFEST "invalid Adapter path: $adapterName"
        }
        $adapterSourcePath = Join-ProjectPath $repositoryRoot $adapterSource
        if (-not (Test-Path -LiteralPath $adapterSourcePath -PathType Leaf)) {
            Fail $INVALID_MANIFEST "Adapter source not found: $adapterSource"
        }
        [void]$managedFiles.Add([PSCustomObject]@{
            Source = $adapterSourcePath
            Target = $adapterTarget
        })
    }

    $versionPath = Join-ProjectPath $targetPath "$targetRootRelative/VERSION"
    $versionRecord = Read-VersionRecord $versionPath
    $existingVersion = Test-Path -LiteralPath $versionPath -PathType Leaf
    $versionMatches = $existingVersion -and
        $versionRecord.name -eq $manifest.name -and
        $versionRecord.version -eq $manifest.version
    if ($existingVersion -and -not $versionMatches) {
        Fail $CONFLICT_ABORTED 'existing VERSION has unknown ownership or version'
    }

    foreach ($entry in $managedFiles) {
        $destination = Join-ProjectPath $targetPath $entry.Target
        if (Test-Path -LiteralPath $destination) {
            if (-not $versionMatches -or -not $versionRecord.hashes.ContainsKey($entry.Target)) {
                Fail $CONFLICT_ABORTED "conflict: existing user-owned file: $($entry.Target)"
            }
            if ((Get-Sha256 $destination) -ne $versionRecord.hashes[$entry.Target]) {
                Fail $CONFLICT_ABORTED "conflict: user-modified managed file: $($entry.Target)"
            }
        }
    }

    $runtimeDirectory = Join-ProjectPath $targetPath $targetRootRelative
    if (Test-Path -LiteralPath $runtimeDirectory -PathType Leaf) {
        Fail $INVALID_TARGET "runtime target is a file: $targetRootRelative"
    }
    New-Item -ItemType Directory -Path $runtimeDirectory -Force | Out-Null

    foreach ($stateRelative in @('state/approvals', 'state/checkpoints/tasks')) {
        try {
            $stateDirectory = Join-ProjectPath $runtimeDirectory $stateRelative
            if (Test-Path -LiteralPath $stateDirectory -PathType Leaf) {
                Fail $INVALID_TARGET "runtime state target is a file: $stateRelative"
            }
            New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
        } catch {
            Fail $PARTIAL_FAILURE "cannot initialize runtime state directory: $stateRelative"
        }
    }

    foreach ($entry in $managedFiles) {
        try {
            $destination = Join-ProjectPath $targetPath $entry.Target
            $destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $entry.Source -Destination $destination -Force
        } catch {
            Fail $PARTIAL_FAILURE "cannot copy: $($entry.Target)"
        }
    }

    $versionLines = New-Object System.Collections.Generic.List[string]
    [void]$versionLines.Add("name: $($manifest.name)")
    [void]$versionLines.Add("version: $($manifest.version)")
    [void]$versionLines.Add('')
    [void]$versionLines.Add('installed_adapters:')
    foreach ($adapterName in $selectedAdapters) {
        [void]$versionLines.Add("  - $adapterName")
    }
    [void]$versionLines.Add('')
    [void]$versionLines.Add('managed_files:')
    foreach ($entry in ($managedFiles | Sort-Object Target)) {
        [void]$versionLines.Add("  - path: $($entry.Target)")
        [void]$versionLines.Add("    sha256: $(Get-Sha256 (Join-ProjectPath $targetPath $entry.Target))")
    }

    $versionTemporary = Join-ProjectPath $targetPath "$targetRootRelative/.VERSION.tmp"
    $versionText = ($versionLines -join ([char]10)) + [char]10
    [System.IO.File]::WriteAllText(
        $versionTemporary,
        $versionText,
        (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false)
    )
    try {
        Move-Item -LiteralPath $versionTemporary -Destination $versionPath -Force
    } catch {
        Fail $PARTIAL_FAILURE 'cannot write .ai/VERSION'
    }

    Write-Output "Installed $($manifest.name) $($manifest.version) into $targetPath"
    exit $SUCCESS
}
catch {
    Fail $GENERAL_ERROR $_.Exception.Message
}
