Import-Module DirColors 
#Import-Module posh-git 
Import-Module oh-my-posh
#Import-Module git-aliases

# 设置 Terminal theme
#Set-PoshPrompt -Theme atomicBit
Set-PoshPrompt -Theme myspace
#Set-PoshPrompt -Theme myspaceship
#Set-PoshPrompt -Theme myhunk

# 设置 autosuggestion（PredictionSource）字体颜色
Set-PSReadLineOption -Colors @{ InlinePrediction = "DarkGray" }
