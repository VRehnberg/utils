BEGIN {
    # Add header
    OFS = ","   # output field separator used by the print statement
    print "File", "Start time", "Stop time", "Runtime", "Run status", \
          "Last epoch", "Run index"
}
BEGINFILE {
    # Reset parameters
    runIndex = 1
}

# Run values
/"key": "run_start"/ {
    startTime = gensub(/.*"time_ms": ([0-9]+).*/, "\\1", 1, $0)
}

/"key": "epoch_stop"/ {
    epoch = gensub(/.*"epoch_num": ([0-9]+).*/, "\\1", 1, $0)
}

/"key": "run_stop"/ {
    # Compute results
    split(gensub(/.*"time_ms": ([0-9]+).*"status": "([a-z]+)".*/, "\\1|\\2", 1, $0), stopArr, "|")
    stopTime = stopArr[1]
    stopStatus = stopArr[2]
    runtime = (stopTime - startTime)

    # Add row
    print FILENAME, startTime, stopTime, runtime, stopStatus, epoch, runIndex++

    # Clear variables in preparation of next epoch
    startTime = ""
    epoch = ""
}
