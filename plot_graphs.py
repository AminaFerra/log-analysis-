import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set(style="whitegrid")
out = "results/"

# 1. Requests per Hour
df_hour = pd.read_csv(out + "hourly_requests.txt", sep="\s+", names=["Count", "Hour"])
plt.figure(figsize=(10,4))
sns.barplot(data=df_hour, x="Hour", y="Count", palette="Blues_d")
plt.title("Requests Per Hour")
plt.savefig(out + "graph_hourly_requests.png")
plt.close()

# 2. Status Codes Breakdown
try:
    # Using 'on_bad_lines' to skip problematic lines
    df_status = pd.read_csv(out + "status_codes_detailed.txt", sep="\s+", names=["_1", "Code", "_2", "Count", "_3", "Percent"], engine='python', on_bad_lines='skip')
    df_status = df_status[["Code", "Count"]]
    plt.figure(figsize=(8, 4))
    sns.barplot(data=df_status, x="Code", y="Count", palette="Set2")
    plt.title("HTTP Status Codes")
    plt.savefig(out + "graph_status_codes.png")
    plt.close()
except pd.errors.ParserError as e:
    print(f"Error reading status_codes_detailed.txt: {e}")
    exit()

# 3. Failures per Day
df_fail = pd.read_csv(out + "failures_per_day.txt", sep="\s+", names=["Count", "Date"])
plt.figure(figsize=(12,4))
sns.barplot(data=df_fail, x="Date", y="Count", palette="Reds")
plt.xticks(rotation=45)
plt.title("Failures Per Day")
plt.tight_layout()
plt.savefig(out + "graph_failures_per_day.png")
plt.close()

# 4. Top GET IPs
df_get = pd.read_csv(out + "top_get_ips.txt", sep="\s+", names=["IP", "Count"])
plt.figure(figsize=(8,4))
sns.barplot(data=df_get.head(10), x="IP", y="Count", palette="Purples_d")
plt.xticks(rotation=45)
plt.title("Top GET IPs")
plt.savefig(out + "graph_top_get_ips.png")
plt.close()

# 5. Top POST IPs
df_post = pd.read_csv(out + "top_post_ips.txt", sep="\s+", names=["IP", "Count"])
plt.figure(figsize=(8,4))
sns.barplot(data=df_post.head(10), x="IP", y="Count", palette="Greens_d")
plt.xticks(rotation=45)
plt.title("Top POST IPs")
plt.savefig(out + "graph_top_post_ips.png")
plt.close()

print("✅ Graphs saved to 'results/' as PNG files.")
