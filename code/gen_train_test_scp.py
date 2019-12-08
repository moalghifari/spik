import random 

pwd = "wav"

filelist = []

with open("filelist", "r") as f:
    for line in f:
        filelist.append(line.strip())


# Random
random.shuffle(filelist)

with open('train.scp', 'w') as f:
	train = filelist[len(filelist)//10:len(filelist)]
	train.sort()
	for file_name in train:
		f.write(f"{pwd}/{file_name}.mfc\n")


with open('test.scp', 'w') as f:
	test = filelist[:len(filelist)//10]
	test.sort()
	for file_name in test:
		f.write(f"{pwd}/{file_name}.mfc\n")