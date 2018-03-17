import csv

csvs = {}

for i in range(0, 4):
    csvs["O{}".format(i)] = csv.reader(open("resultsO{}.csv".format(i)))

results = {}

for olevel in csvs:
    results[olevel] = {}
    for row in csvs[olevel]:
        memtype = row[0]
        size = row[1]
        time = float(row[2][:-1])

        if memtype not in results[olevel]:
            results[olevel][memtype] = {}

        if size not in results[olevel][memtype]:
            results[olevel][memtype][size] = []

        results[olevel][memtype][size].append(time)

computed = {}

for olevel in results:
    computed[olevel] = {}
    for memtype in results[olevel]:
        for i_count in results[olevel][memtype]:
            i_stats = None
            if i_count not in computed[olevel]:
                i_stats = {
                    "mins": [],
                    "avgs": [],
                    "maxs": []
                }
                computed[olevel][i_count] = i_stats
            else:
                i_stats = computed[olevel][i_count]

            current = results[olevel][memtype][i_count]
            i_stats["avgs"].append((sum(current) / len(current), memtype))
            i_stats["maxs"].append((max(current), memtype))
            i_stats["mins"].append((min(current), memtype))

for olevel in computed:
    for i_count in computed[olevel]:
        for category in computed[olevel][i_count]:
            results = sorted(computed[olevel][i_count][category])
            computed[olevel][i_count][category] = list(map((lambda x: [x[0]/results[0][0], x[1]]), results))

print(computed)
