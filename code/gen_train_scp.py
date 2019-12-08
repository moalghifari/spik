pwd = "wav"

filelist = []

with open("filelist", "r") as f:
    for line in f:
        filelist.append(line.strip())

for f in filelist:
    print(f"{pwd}/{f}.mfc")
