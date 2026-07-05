# Codetronics Exocore - Git Control Panel
# A minimal WinForms GUI wrapping exactly the git workflow this repo needs:
# commit, push, tag-and-release, pull. No install required -- PowerShell and
# .NET WinForms ship with Windows already.
#
# Guardrails baked in (from real failures hit while setting this repo up):
#   - Push checks for a missing 'origin' remote and offers to add it instead
#     of just failing with "does not appear to be a git repository."
#   - Push checks the branch is actually named 'main' (not 'master', git's
#     old default) and offers to rename it instead of failing with
#     "src refspec main does not match any."
#   - A rejected (non-fast-forward) push offers force-push as an explicit,
#     separate, clearly-labeled confirmation -- never silent.
#   - Tag & Release validates the version format and refuses to push a
#     duplicate tag.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

$RepoPath = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    [System.Windows.Forms.MessageBox]::Show(
        "No .git folder found at:`r`n$RepoPath`r`n`r`nThis script expects to live in <repo>\tools\git-gui.ps1.",
        "Not a git repo", "OK", "Error") | Out-Null
    exit
}

try {
    git --version | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "git.exe isn't on your PATH. Install Git for Windows first: https://git-scm.com/download/win",
        "Git not found", "OK", "Error") | Out-Null
    exit
}

function Invoke-Git {
    param([string[]]$GitArgs)
    Push-Location $RepoPath
    try {
        $result = & git @GitArgs 2>&1 | Out-String
    } catch {
        $result = "ERROR: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
    return $result
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Codetronics Exocore - Git Control Panel"
$form.Size = New-Object System.Drawing.Size(780, 580)
$form.MinimumSize = New-Object System.Drawing.Size(600, 420)
$form.StartPosition = "CenterScreen"

$lblRepo = New-Object System.Windows.Forms.Label
$lblRepo.Text = "Repo: $RepoPath"
$lblRepo.Location = New-Object System.Drawing.Point(10, 8)
$lblRepo.Size = New-Object System.Drawing.Size(740, 18)
$lblRepo.Anchor = "Top,Left,Right"
$form.Controls.Add($lblRepo)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Location = New-Object System.Drawing.Point(10, 30)
$txtLog.Size = New-Object System.Drawing.Size(745, 400)
$txtLog.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($txtLog)

function Write-Log {
    param([string]$Text)
    $stamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$stamp] $Text`r`n")
    $txtLog.AppendText("----------------------------------------------------------------`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
}

function New-GitButton($text, $x, $y, $w = 175) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, 34)
    $btn.Anchor = "Bottom,Left"
    $form.Controls.Add($btn)
    return $btn
}

$row1 = 440
$row2 = 480

$btnStatus = New-GitButton "Refresh / Status" 10 $row1
$btnCommit = New-GitButton "Commit All Changes" 195 $row1
$btnPush   = New-GitButton "Push" 380 $row1
$btnTag    = New-GitButton "Tag && Release" 565 $row1
$btnPull   = New-GitButton "Pull" 10 $row2

function Show-Status {
    $branch = (Invoke-Git @('branch', '--show-current')).Trim()
    $remotes = Invoke-Git @('remote', '-v')
    $status = Invoke-Git @('status', '--short')
    $log = Invoke-Git @('log', '--oneline', '-10')
    $body = "Branch: $branch`r`n`r`nRemotes:`r`n$remotes`r`nUncommitted changes:`r`n"
    if ([string]::IsNullOrWhiteSpace($status)) { $body += "(none)`r`n" } else { $body += "$status`r`n" }
    $body += "`r`nLast 10 commits:`r`n$log"
    Write-Log $body
}

$btnStatus.Add_Click({ Show-Status })

$btnCommit.Add_Click({
    $msg = [Microsoft.VisualBasic.Interaction]::InputBox("Commit message:", "Commit All Changes", "")
    if ([string]::IsNullOrWhiteSpace($msg)) {
        Write-Log "Commit cancelled (empty message)."
        return
    }
    Write-Log (Invoke-Git @('add', '-A'))
    Write-Log (Invoke-Git @('commit', '-m', $msg))
})

$btnPush.Add_Click({
    $remotes = Invoke-Git @('remote')
    if ($remotes -notmatch 'origin') {
        $url = [Microsoft.VisualBasic.Interaction]::InputBox(
            "No 'origin' remote configured. Enter the GitHub repo URL:",
            "Add Remote", "https://github.com/codetronicsiotworld/codetronics-exocore.git")
        if ([string]::IsNullOrWhiteSpace($url)) {
            Write-Log "Push cancelled (no remote URL provided)."
            return
        }
        Write-Log (Invoke-Git @('remote', 'add', 'origin', $url))
    }

    $branch = (Invoke-Git @('branch', '--show-current')).Trim()
    if ($branch -ne 'main') {
        $rename = [System.Windows.Forms.MessageBox]::Show(
            "Current branch is '$branch', not 'main'. Rename it to 'main' now?",
            "Branch name mismatch", "YesNo", "Question")
        if ($rename -eq 'Yes') {
            Write-Log (Invoke-Git @('branch', '-M', 'main'))
            $branch = 'main'
        }
    }

    $result = Invoke-Git @('push', '-u', 'origin', $branch)
    Write-Log $result

    if ($result -match 'rejected|non-fast-forward') {
        $force = [System.Windows.Forms.MessageBox]::Show(
            "Push was rejected -- the remote has commits your local repo doesn't. " +
            "Force push and OVERWRITE the remote with your local history? " +
            "Only do this if you're sure nothing on GitHub needs to be kept.",
            "Force push?", "YesNo", "Warning")
        if ($force -eq 'Yes') {
            Write-Log (Invoke-Git @('push', '-u', 'origin', $branch, '--force'))
        }
    }
})

$btnTag.Add_Click({
    $version = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Version number, e.g. 1.0.1 (no 'v' prefix):", "Tag && Release", "1.0.0")
    if ($version -notmatch '^\d+\.\d+\.\d+$') {
        [System.Windows.Forms.MessageBox]::Show(
            "Version must look like 1.0.0 (three numbers separated by dots).",
            "Invalid version", "OK", "Error") | Out-Null
        return
    }
    $tag = "v$version"
    $existing = (Invoke-Git @('tag', '-l', $tag)).Trim()
    if ($existing -eq $tag) {
        [System.Windows.Forms.MessageBox]::Show("Tag $tag already exists.", "Duplicate tag", "OK", "Error") | Out-Null
        return
    }
    Write-Log (Invoke-Git @('tag', $tag))
    $result = Invoke-Git @('push', 'origin', $tag)
    Write-Log $result
    Write-Log "Tag $tag pushed. Check the Actions tab on GitHub -- the release workflow should start within a few seconds and will publish package_kratos_hermes_vyper_index.json once it finishes."
})

$btnPull.Add_Click({
    Write-Log (Invoke-Git @('pull', 'origin', 'main'))
})

Show-Status
[void]$form.ShowDialog()
