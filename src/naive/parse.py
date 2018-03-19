import csv

# taking in some collection of values, leave only 4 or 5 inner values,
# removing outliers depending on whether the source list was even or odd
def dump_outliers(values):
    length = len(values)
    if length < 5:
        return values

    target_len = 4 + (length % 2)
    to_drop = int((length - target_len) / 2)
    return values[to_drop:(length - to_drop)]

csvs = {}

# read in the 4 different results files for the various optimisation levels
for i in range(0, 4):
    csvs["O{}".format(i)] = csv.reader(open("resultsO{}.csv".format(i)))

results = {}

# parse each csv into dicts
# { "olevel": # O0, O1 etc.
#   { "alloc_type": # Dynamic, stack, etc
#     { "item_count": # 1, 8, 16, etc
#       [ <times> ]
#     }
#   }
# }
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

# transform the preceding dict into
# { "olevel":
#   { "item_count":
#     {
#       "avgs": [ (<time>, "alloc_type"), ... ],
#       "mins": [ (<time>, "alloc_type"), ... ],
#       "maxs": [ (<time>, "alloc_type"), ... ]
#     }
#   }
# }
# however, when calculating the avgs/mins/maxs, dump the outliers first
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

            current = dump_outliers(sorted(results[olevel][memtype][i_count]))
            i_stats["avgs"].append((sum(current) / len(current), memtype))
            i_stats["maxs"].append((max(current), memtype))
            i_stats["mins"].append((min(current), memtype))

# produce sorted lists indicating the relative performance of each method
# the first item in each list was the fastest and so forth
for olevel in computed:
    for i_count in computed[olevel]:
        for category in computed[olevel][i_count]:
            results = sorted(computed[olevel][i_count][category])
            computed[olevel][i_count][category] = list(map((lambda x: [x[0]/results[0][0], x[1]]), results))

print(computed)
