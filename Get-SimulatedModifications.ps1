
<#
    * modifications.txt contains all the modifications in the log output
    * each is numbered
	E.g. of the start of that file:
	
	Modify user 1: "aadamson@district.k12.or.us"
	Change stored unique identifier to "RyaOeU9uTEaOQwuAyCBTtg"

    Modify user 2: "aaustin@district.k12.or.us"
	Change stored unique identifier to "2QWj1qwO9ES5oHYiyMSaSw"
	
	. . .

#>
$file = Get-Content .\modifications.txt

$currentUser = [PSCustomObject]@{
    Account = ""
    Actions = [ordered]@{
        NameTo = ""
        GivenNameTo = ""
        FamilyNameTo = ""
        SuspendUser = ""
        ReasonForSuspend = ""
        UpdateKey = ""
    }
}

$actionsPer = [ordered]@{}

$modifications = [PSCustomObject]@()



for ($i = 0; $i -lt $file.Count; $i++)
{
    if ($file[$i])
    {
        $indentation = ("$($file[$i])".Split("`t")).Count - 1

        if ($indentation -eq 0)
        {
            $currentUser.Account = "$($file[$i])".Split(' ')[3]
            #Write-Host "SET ACCOUNT TO $($currentUser.Account)" -ForegroundColor Yellow
        }

        elseif ($indentation -eq 1)
        {
            $wordsInAction = "$($file[$i])".Split(' ')
        
            # if action is to suspend
            if ($wordsInAction[0] -eq "`tSuspend")
            {
                $actionsPer["SuspendUser"] = "TRUE"
                $actionsPer["ReasonForSuspend"] = "$("$($file[$i + 1])".Split("`t")[1])"
                ++$i
                continue
            }
            elseif ($wordsInAction[0] -eq "`tRestore")
            {
                $actionsPer["RestoreUser"] = "TRUE"
            }
            
            # if action is to change a name or 'org'
            elseif ($wordsInAction[0] -eq "`tChange")
            {

                if ($wordsInAction[1] -eq "org")
                {
                    $actionsPer["NameTo"] = "$($wordsInAction[3]) $($wordsInAction[4])"
                }
                elseif ($wordsInAction[1] -eq "given")
                {
                    $actionsPer["GivenNameTo"] = "$($wordsInAction[4])"
                }
                elseif ($wordsInAction[1] -eq "family")
                {
                    $actionsPer["FamilyNameTo"] = "$($wordsInAction[4])"
                }
                elseif ($wordsInAction[1] -eq "stored")
                {
                    $actionsPer["UpdateKey"] = "$($wordsInAction[6])"
                }
                else 
                {
                    Write-Host "$($wordsInAction[1])"
                }
            }

            else
            {
                Write-Host $file[$i] -ForegroundColor Red
            }
        }
    }

    else
    {
        # Add previous object to list
        $currentUser.Actions = $actionsPer

        #Write-Host "CURRENTUSER ACCOUNT: $($currentUser.Account)" -ForegroundColor Cyan
        #Write-Host "  ACTIONS:           $($currentUser.Actions.Keys)`n" -ForegroundColor Cyan

        $modifications += $currentUser

        # Reset current user object
        #Write-Host "RESETTING CURRENTUSER OBJECT" -ForegroundColor Yellow
        $currentUser = [PSCustomObject]@{
            Account = ""
            Actions = [ordered]@{
                NameTo = ""
                GivenNameTo = ""
                FamilyNameTo = ""
                SuspendUser = ""
                ReasonForSuspend = ""
                RestoreUser = ""
                UpdateKey = ""
            }
        }

        $actionsPer = [ordered]@{}
    }
}

$justKeyChange = $modifications | Where-Object {$_.Actions.Count -eq 1 -and ($_.Actions).GetEnumerator().Name -eq "UpdateKey"}

$twoActions = $modifications | Where-Object {$_.Actions.Count -eq 2}


$keyAndCNChange = $twoActions | Where-Object {($_.Actions).GetEnumerator().Name -contains "NameTo"}
$suspended = $twoActions | Where-Object {($_.Actions).GetEnumerator().Name -contains "SuspendUser"}

$restored = $modifications | Where-Object {($_.Actions).GetEnumerator().Name -contains "RestoreUser"}

$nameChange = $modifications | Where-Object {($_.Actions).GetEnumerator().Name -contains "GivenNameTo" -or ($_.Actions).GetEnumerator().Name -contains "FamilyNameTo"}


Remove-Item .\mod-*


$keyAndCNChange | ForEach-Object {$line = "$($_.Account)".Split('"')[1]; Write-Output "$line" | Out-File -Append .\mod-name-and-key-updates.txt}
$justKeyChange | ForEach-Object {$line = "$($_.Account)".Split('"')[1]; Write-Output "$line" | Out-File -Append .\mod-just-key-updates.txt}
$nameChange | ForEach-Object {$line = "$($_.Account)".Split('"')[1]; Write-Output "$line" | Out-File -Append .\mod-name-changes.txt}
$restored | ForEach-Object {$line = "$($_.Account)".Split('"')[1]; Write-Output "$line" | Out-File -Append .\mod-restored-users.txt}
$suspended | ForEach-Object {$line = "$($_.Account)".Split('"')[1]; Write-Output "$line" | Out-File -Append .\mod-suspensions.txt}

Write-Host "NameAndKeyChange: $($keyAndCNChange.Count)`nJustKeyChange: $($justKeyChange.Count)`nNameChange: $($nameChange.Count)`nRestored: $($restored.Count)`nSuspended: $($suspended.Count)" -ForegroundColor Yellow