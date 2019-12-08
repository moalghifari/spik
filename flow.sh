cat source/low.lab | cut -d' ' -f1 > filelist
cat source/low.lex | python sort.py > source/sort.lex
cat source/low.lab | cut -d' ' -f2- | fmt -1 | sort | uniq > wlist
HDMan -m -w wlist -n monophones1 -i -l dlog dict source/sort.lex
python3 code/mlf.py < source/low.lab > words.mlf
HLEd -l '*' -d dict -i phones0.mlf mkphones0.led words.mlf
HLEd -l '*' -d dict -i phones1.mlf mkphones1.led words.mlf
python3 code/gen_scp.py > codetr.scp
HCopy -T 1 -C config -S codetr.scp

; INFO: remove SOURCEFORMAT = WAV for .mfc file
; for closed
; for open please use python3 code/gen_train_test_scp.py
python3 code/gen_train_scp.py > train.scp
; create proto file
HCompV -A -D -T 1 -C config -f 0.01 -m -S train.scp -M hmm0 proto
; create `monophones0` from `monophones1` + sil
; create hmmdefs
; create macros file
HERest -A -D -T 1 -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm0/macros -H hmm0/hmmdefs -M hmm1 monophones0
HERest -A -D -T 1 -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm1/macros -H hmm1/hmmdefs -M hmm2 monophones0
HERest -A -D -T 1 -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm2/macros -H hmm2/hmmdefs -M hmm3 monophones0
cp -r hmm3 hmm4
; modify hmm4.hmmdefs
; create sil.hed
HHEd -A -D -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1

HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1
HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm6/macros -H  hmm6/hmmdefs -M hmm7 monophones1

HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm7/macros -H  hmm7/hmmdefs -M hmm8 monophones1
HERest -A -D -T 1 -C config  -I phones1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm8/macros -H  hmm8/hmmdefs -M hmm9 monophones1

; triphone
HLEd -A -D -T 1 -n triphones1 -l '*' -i wintri.mlf mktri.led aligned.mlf

julia code/mktrihed.jl monophones1 triphones1 mktri.hed

HHEd -A -D -T 1 -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1 
HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 1000.0 -S train-triphone.scp -H hmm10/macros -H hmm10/hmmdefs -M hmm11 triphones1
HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S train-triphone.scp -H hmm11/macros -H hmm11/hmmdefs -M hmm12 triphones1

; create maketriphones.ded
HDMan -A -D -T 1 -b sp -n fulllist0 -g maketriphones.ded -l flog dict-tri source/sort.lex
julia code/fixfulllist.jl fulllist0 monophones0 fulllist
julia code/mkclscript.jl monophones0 tree.hed

HHEd -A -D -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train-triphone.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train-triphone.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train-triphone.scp -H hmm15/macros -H hmm15/hmmdefs -M hmm16 tiedlist
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train-triphone.scp -H hmm16/macros -H hmm16/hmmdefs -M hmm17 tiedlist
HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train-triphone.scp -H hmm17/macros -H hmm17/hmmdefs -M hmm18 tiedlist

; create n-gram
; cat source/low.lab | cut -d' ' -f2- > source/clean.lab
; remove <> from clean.lab
; mkdir ngram.0
; LNewMap -f WFC ngram empty.wmap 
; LGPrep -T 1 -a 100000 -b 200000 -d ngram.0 -n 4 -s "ngram" empty.wmap source/clean.lab
; LGCopy -T 1 -b 200000 -d ngram.1 ngram.0/wmap ngram.0/gram.*

; change test.scp / train.scp here
; experiment
HLStats -b bigfn -o wlist words.mlf
; create wlistfn from wlist and add !ENTER !EXIT
HBuild -n bigfn wlistfn wdnet
; add !ENTER and !EXIT to dict
; !ENTER [] sil and !EXIT [] sil

; for closed experiment
; for open please use test.scp
HVite -C config -H hmm18/macros -H hmm18/hmmdefs -S train.scp -l '*' -i recout.mlf -w wdnet -p 0.0 -s 5.0 dict-ngram tiedlist
HResults -I words.mlf tiedlist recout.mlf
