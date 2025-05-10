#!/bin/bash

LOG="info"
mkdir -p results
SUMMARY="results/summary.txt"
> "$SUMMARY"

# Check if the log file exists
if [ ! -f "$LOG" ]; then
  echo "❌ Log file '$LOG' not found!"
  exit 1
fi

echo "🔍 Starting analysis on log file '$LOG'..."

# -------------------------------
# 1. Request Counts
# -------------------------------
total=$(wc -l < "$LOG")
get=$(grep -c '"GET' "$LOG")
post=$(grep -c '"POST' "$LOG")
echo -e "Total Requests: $total\nGET Requests: $get\nPOST Requests: $post" > results/request_counts.txt

# -------------------------------
# 2. Unique IPs and Request Type per IP
# -------------------------------
unique_ips=$(awk '{print $1}' "$LOG" | sort -u | wc -l)
echo "Unique IPs: $unique_ips" > results/unique_ips.txt
awk '{print $1, $6}' "$LOG" | grep -E '"(GET|POST)' |
awk '{gsub(/"/,"",$2); count[$1][$2]++} END {
  for (ip in count)
    print ip, "GET:", count[ip]["GET"]+0, "POST:", count[ip]["POST"]+0
}' > results/ip_requests.txt

# -------------------------------
# 3. Failed Requests (4xx/5xx)
# -------------------------------
failures=$(awk '$9 ~ /^[45]/ {n++} END {print n+0}' "$LOG")
fail_pct=$(awk -v f=$failures -v t=$total 'BEGIN {printf "%.2f", (f/t)*100}')
echo -e "Failed Requests: $failures\nFailure Rate: $fail_pct%" > results/failure_counts.txt

# -------------------------------
# 4. Most Active IP
# -------------------------------
awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head -1 > results/most_active_ip.txt

# -------------------------------
# 5. Daily Request Averages
# -------------------------------
days=$(awk '{print $4}' "$LOG" | cut -d: -f1 | sort -u | wc -l)
avg_per_day=$(awk -v t=$total -v d=$days 'BEGIN {printf "%.2f", t/d}')
echo "Average Daily Requests: $avg_per_day" > results/average_daily_requests.txt

# -------------------------------
# 6. Failure Analysis by Day
# -------------------------------
awk '$9 ~ /^[45]/ {gsub(/\[|\]/,"",$4); split($4,d,":"); print d[1]}' "$LOG" |
sort | uniq -c | sort -nr > results/failures_per_day.txt

# -------------------------------
# 7. Requests Per Hour
# -------------------------------
awk '{gsub(/\[|\]/,"",$4); split($4,t,":"); print t[2]}' "$LOG" |
sort | uniq -c | sort -n > results/hourly_requests.txt

# -------------------------------
# 8. Request Trends by Hour & Day
# -------------------------------
awk '{gsub(/\[|\]/,"",$4); split($4,dt,":"); print dt[1], dt[2]}' "$LOG" |
sort | uniq -c | awk '{print $2, $3, $1}' > results/request_trends.txt

# -------------------------------
# 9. Status Code Breakdown
# -------------------------------
awk '{codes[$9]++} END {
  total=0;
  for (code in codes) total += codes[code];
  for (code in codes) {
    pct = (codes[code]/total)*100;
    meaning = "Unknown";
    if (code == 200) meaning="OK";
    else if (code == 301) meaning="Moved Permanently";
    else if (code == 302) meaning="Found (Redirect)";
    else if (code == 400) meaning="Bad Request";
    else if (code == 401) meaning="Unauthorized";
    else if (code == 403) meaning="Forbidden";
    else if (code == 404) meaning="Not Found";
    else if (code == 500) meaning="Internal Server Error";
    else if (code == 503) meaning="Service Unavailable";
    printf "Status %s (%s): %d requests (%.2f%%)\n", code, meaning, codes[code], pct;
  }
}' "$LOG" | sort > results/status_codes_detailed.txt

# -------------------------------
# 10. Most Active IP by GET
# -------------------------------
awk '$6 ~ /"GET/ {g[$1]++} END {for (ip in g) print ip, g[ip]}' "$LOG" |
sort -k2 -nr > results/top_get_ips.txt

# -------------------------------
# 11. Most Active IP by POST
# -------------------------------
awk '$6 ~ /"POST/ {p[$1]++} END {for (ip in p) print ip, p[ip]}' "$LOG" |
sort -k2 -nr > results/top_post_ips.txt

# -------------------------------
# 12. Failure Patterns by Hour
# -------------------------------
awk '$9 ~ /^[45]/ {gsub(/\[|\]/,"",$4); split($4,t,":"); print t[2]}' "$LOG" |
sort | uniq -c | sort -nr > results/failure_by_hour.txt

# -------------------------------
# Final Summary Output
# -------------------------------
{
echo "===== 📊 LOG ANALYSIS SUMMARY ====="
echo "Total Requests: $total"
echo "GET Requests: $get"
echo "POST Requests: $post"
echo "Unique IPs: $unique_ips"
echo "Failed Requests: $failures ($fail_pct%)"
echo "Most Active IP: $(awk '{print $2 " (" $1 " requests)"}' results/most_active_ip.txt)"
echo "Average Daily Requests: $avg_per_day"
echo -e "\nTop Failure Hours:"; head -5 results/failure_by_hour.txt
echo -e "\nTop GET IPs:"; head -3 results/top_get_ips.txt
echo -e "\nTop POST IPs:"; head -3 results/top_post_ips.txt
echo -e "\nTop Failure Days:"; head -5 results/failures_per_day.txt
echo -e "\nStatus Code Breakdown:"; cat results/status_codes_detailed.txt

# -------------------------------
# Suggestions
# -------------------------------
echo -e "\n===== 🧠 SUGGESTIONS ====="
echo "1. Reduce 4xx/5xx errors by improving input validation and server stability."
echo "2. Investigate failure spikes on top failure hours and days."
echo "3. Monitor IPs with unusually high GET/POST activity for potential abuse."
echo "4. Use rate limiting for IPs making excessive requests."
echo "5. Consider improving caching or load balancing if many 500 errors appear during peak hours."
} | tee "$SUMMARY"

echo -e "\n✅ Log analysis complete. Results are saved in the 'results/' folder."
