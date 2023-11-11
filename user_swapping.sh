#!/usr/bin/env bash
# Get current swap usage for all running processes

ml purge
ml SciPy-bundle

# Get paths to process statuses
tmpfile=$(mktemp /tmp/.swap_usage_monitoring.XXXXXX)
status_files=( $(find /proc/ -maxdepth 2 -type f -regex '^/proc/[0-9]+/status$') )
if [ "${#status_files[@]}" = 0 ]; then
    echo No status files found > /dev/stderr
    rm $tmpfile
    exit 1
fi

# Get pid and swap information from status files
awk '
BEGIN {OFS=","}
BEGINFILE {
    split(FILENAME,a,"/"); pid=a[3]; sum=0
}
/^VmSwap/ {
    sum+=$2
}
ENDFILE {
    if (sum>0){print pid,sum}
}
' "${status_files[@]}" 2>/dev/null > "$tmpfile" || true
if [ ! -s "$tmpfile" ]; then
    echo "No swap usage found" > /dev/stderr
    rm $tmpfile
    exit 1
fi

# Prepend user for each pid
pids=$(awk -F "," '{print $1}' "$tmpfile" | paste -sd "," -)
cp "$tmpfile" "${tmpfile}_2"
paste -d "," <(ps -p "$pids" -o user --noheaders) "${tmpfile}_2" > $tmpfile
rm "${tmpfile}_2"
cat $tmpfile > tmp.txt

# Pretty print information
python -c "
import pandas as pd

data = pd.read_csv(
    filepath_or_buffer='$tmpfile',
    header=None,
    names=['User', 'PID', 'Swap (KB)'],
)
data['Swap (MB)'] = data['Swap (KB)'] // 1024
print(data.groupby('User', sort=False).sum()['Swap (MB)'].sort_values(ascending=False).head(n=10))
"

rm $tmpfile
