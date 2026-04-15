<#
.SYNOPSIS
    Folder cleanup utility for M-Namikaz-Others workspace.

.DESCRIPTION
    Finds empty directories, stale folders, structural issues.
    Use -Apply to actually perform changes.

.PARAMETER RemoveEmpty
    Find empty directories.

.PARAMETER DetectStale
    Find stale folders.

.PARAMETER CheckStructure
    Validate repo structure.

.PARAMETER ArchiveOld
    Archive stale folders.

.PARAMETER ReportOnly
    Preview only (default).

.PARAMETER Apply
    Actually perform changes.

.PARAMETER Days
    Days threshold for stale detection (default: 30).

.EXAMPLE
    .\cleanup-folders.ps1 -ReportOnly

.NOTES
    Author: AI Prompting
    Date: 2026-04-14
#>

[CmdletBinding()]
param(
    [switch]$RemoveEmpty,
    [switch]$DetectStale,
    [switch]$CheckStructure,
    [switch]$ArchiveOld,
    [switch]$ReportOnly,
    [switch]$Apply,
    [int]$Days = 30
)

try {
    $ErrorActionPreference = "Continue"
    $WorkspaceRoot = "M:\M-Namikaz-Others"
$Results = @{
    EmptyDirs = @()
    StaleFolders = @()
    StructuralIssues = @()
    Archived = @()
}

function Test-IsIgnored {
    param([string]$Path)
    
    $ignoreFile = Join-Path $Path ".cleanup-ignore"
    if (Test-Path $ignoreFile) {
        return $true
    }
    return $false
}

function Get-LastActivity {
    param([string]$Path)
    
    $items = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        return $null
    }
    
    $latest = $items | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $latest.LastWriteTime
}

function Test-IsRepoFolder {
    param([string]$Path)
    
    $gitDir = Join-Path $Path ".git"
    if (Test-Path $gitDir) {
        return $true
    }
    
    $agentsFile = Join-Path $Path "AGENTS.md"
    if (Test-Path $agentsFile) {
        return $true
    }
    
    return $false
}

function Test-HasStructure {
    param([string]$Path)
    
    $issues = @()
    
    $requiredFiles = @("AGENTS.md", "README.md")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $Path $file
        if (-not (Test-Path $filePath)) {
            $issues += "Missing: $file"
        }
    }
    
    $templateDir = Join-Path $Path "templates"
    if (-not (Test-Path $templateDir)) {
        $issues += "Missing: templates directory"
    }
    
    return $issues
}

Write-Host "=== Folder Cleanup Report ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Apply) { 'APPLY' } else { 'REPORT ONLY' })" -ForegroundColor $(if ($Apply) { 'Yellow' } else { 'Green' })
Write-Host "Workspace: $WorkspaceRoot"
Write-Host ""

if ($RemoveEmpty) {
    Write-Host "[1/4] Scanning for empty directories..." -ForegroundColor Yellow
    
    $allDirs = Get-ChildItem -Path $WorkspaceRoot -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue
    
    foreach ($dir in $allDirs) {
        if (Test-IsIgnored -Path $dir.FullName) {
            continue
        }
        
        $hasFiles = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue
        $hasSubdirs = Get-ChildItem -Path $dir.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { 
            -not (Test-IsIgnored -Path $_.FullName) 
        }
        
        if ($hasFiles.Count -eq 0 -and $hasSubdirs.Count -eq 0) {
            $Results.EmptyDirs += $dir.FullName
            Write-Host "  Empty: $($dir.FullName)" -ForegroundColor Gray
        }
    }
    
    Write-Host "  Found $($Results.EmptyDirs.Count) empty directories" -ForegroundColor Magenta
}

if ($DetectStale) {
    Write-Host "[2/4] Scanning for stale folders (>$Days days)..." -ForegroundColor Yellow
    
    $allDirs = Get-ChildItem -Path $WorkspaceRoot -Directory -Recurse -Depth 1 -ErrorAction SilentlyContinue
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    
    foreach ($dir in $allDirs) {
        if (Test-IsIgnored -Path $dir.FullName) {
            continue
        }
        
        $lastWrite = Get-LastActivity -Path $dir.FullName
        
        if ($lastWrite -and $lastWrite -lt $cutoffDate) {
            $age = ((Get-Date) - $lastWrite).Days
            $isRepo = Test-IsRepoFolder -Path $dir.FullName
            
            $Results.StaleFolders += @{
                Path = $dir.FullName
                LastActivity = $lastWrite
                DaysOld = $age
                IsRepo = $isRepo
            }
            
            $color = if ($isRepo) { 'Yellow' } else { 'Gray' }
            Write-Host "  Stale ($age days): $($dir.Name)" -ForegroundColor $color
            if ($isRepo) {
                Write-Host "    -> $lastWrite" -ForegroundColor DarkYellow
                Write-Host "    -> May be important (has .git or AGENTS.md)" -ForegroundColor DarkYellow
            }
        }
    }
    
    Write-Host "  Found $($Results.StaleFolders.Count) stale folders" -ForegroundColor Magenta
    $repoCount = ($Results.StaleFolders | Where-Object { $_.IsRepo }).Count
    if ($repoCount -gt 0) {
        Write-Host "  Note: $repoCount folders appear to be repos - review before archiving!" -ForegroundColor Yellow
    }
}

if ($CheckStructure) {
    Write-Host "[3/4] Checking repo structure..." -ForegroundColor Yellow
    
    $subdirs = Get-ChildItem -Path $WorkspaceRoot -Directory -ErrorAction SilentlyContinue
    
    foreach ($dir in $subdirs) {
        if (Test-IsIgnored -Path $dir.FullName) {
            continue
        }
        
        $issues = Test-HasStructure -Path $dir.FullName
        
        if ($issues.Count -gt 0) {
            $Results.StructuralIssues += @{
                Path = $dir.FullName
                Issues = $issues
            }
            
            Write-Host "  $($dir.Name):" -ForegroundColor Yellow
            foreach ($issue in $issues) {
                Write-Host "    - $issue" -ForegroundColor DarkYellow
            }
        }
    }
    
    Write-Host "  Found $($Results.StructuralIssues.Count) repos with structural issues" -ForegroundColor Magenta
}

if ($ArchiveOld) {
    Write-Host "[4/4] Identifying archive candidates..." -ForegroundColor Yellow
    
    $candidates = $Results.StaleFolders | Where-Object { -$_.IsRepo }
    
    if ($candidates.Count -eq 0) {
        Write-Host "  No non-repo stale folders to archive" -ForegroundColor Gray
    }
    else {
        Write-Host "  Found $($candidates.Count) archive candidates (non-repo stale folders)" -ForegroundColor Magenta
        
        if ($Apply) {
            $archiveDir = Join-Path $WorkspaceRoot "archive"
            if (-not (Test-Path $archiveDir)) {
                New-Item -ItemType Directory -Path $archiveDir | Out-Null
            }
            
            foreach ($candidate in $candidates) {
                $name = Split-Path $candidate.Path -Leaf
                $dest = Join-Path $archiveDir $name
                
                if (Test-Path $dest) {
                    $dest = Join-Path $archiveDir "$name-$(Get-Date -Format 'yyyyMMdd')"
                }
                
                Move-Item -Path $candidate.Path -Destination $dest
                $Results.Archived += $candidate.Path
                Write-Host "  Archived: $name" -ForegroundColor Green
            }
            
            Write-Host "  Archived $($Results.Archived.Count) folders" -ForegroundColor Magenta
        }
    }
}

if ($Apply -and $RemoveEmpty -and $Results.EmptyDirs.Count -gt 0) {
    Write-Host "`nApplying: Removing empty directories..." -ForegroundColor Yellow
    
    foreach ($emptyDir in $Results.EmptyDirs) {
        Remove-Item -Path $emptyDir -Force
        Write-Host "  Removed: $emptyDir" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Empty directories: $($Results.EmptyDirs.Count)"
Write-Host "Stale folders: $($Results.StaleFolders.Count)"
Write-Host "Structural issues: $($Results.StructuralIssues.Count)"
Write-Host "Archived: $($Results.Archived.Count)"

if (-not $Apply -and ($RemoveEmpty -or $DetectStale -or $CheckStructure -or $ArchiveOld)) {
    Write-Host ""
    Write-Host "Run with -Apply to actually perform changes" -ForegroundColor Yellow
}

if ($Apply) {
        Write-Host "Changes have been applied!" -ForegroundColor Green
    }
    else {
        Write-Host "This was a preview. Use -Apply to make changes." -ForegroundColor Green
    }

    return $Results
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}
