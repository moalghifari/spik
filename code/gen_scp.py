# pwd = "/home/rid9/Project/tugas/speech/tubes"
# pwd = "/home/rid9/Project/tugas/speech/tubes/wav"
pwd = "wav"

filelist = []

with open("filelist", "r") as f:
    for line in f:
        filelist.append(line.strip())

for f in filelist:
    print(f"{pwd}/{f}.wav {pwd}/{f}.mfc")
