#!/usr/bin/env fish

set -l blue '\033[0;34m';
set -l cyan '\033[0;36m';
set -l white '\033[0;37m';

set -l disk (df -BG / | awk -v cyan="$cyan" -v white="$white" 'NR==2 {print $3 "B / " $2 "B (" cyan $5 white ")"}');
set -l memory (free -h --si | awk -v cyan="$cyan" -v white="$white" '/Mem/ {u=$3; t=$2} END {printf "%.1fGB / %.1fGB (" cyan "%.1f%%" white ")", u, t, (u/t*100)}');
set -l cpu (top -bn1 | sed -n '/Cpu/p' | awk '{print $2}');

echo -e "$blue  ▗▄   $cyan▗▄ ▄▖     $white┌───────────────────────────────┐";
echo -e "$blue ▄▄🬸█▄▄▄$cyan🬸█▛ $blue▃";
echo -e "$cyan   ▟▛    ▜$blue▃▟🬕     $cyan CPU:$white $cpu%";
echo -e "$cyan🬋🬋🬫█      $blue█🬛🬋🬋    $cyan Disk:$white $disk";
echo -e "$cyan 🬷▛🮃$blue▙    ▟▛       $cyan Memory:$white $memory";
echo -e "$cyan 🮃$blue ▟█🬴$cyan▀▀▀█🬴▀▀";
echo -e "$blue  ▝▀ ▀▘   $cyan▀▘     $white└───────────────────────────────┘";
