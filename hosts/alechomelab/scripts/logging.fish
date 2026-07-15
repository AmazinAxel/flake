#!/usr/bin/env fish

function log
    set logFile /home/alec/logs.txt

    # Set file contents to the new log and the past 5 logs
    begin
        printf "%s\n" "$argv"
        cat $logFile 2>/dev/null
    end | head -n 5 > $logFile.tmp

    mv $logFile.tmp $logFile
end
