cat source/low.lab | cut -d' ' -f1 > filelist
cat source/low.lex | python sort.py > source/sort.lex
cat source/low.lab | cut -d' ' -f2- | fmt -1 | sort | uniq > wlist
HDMan -m -w wlist -n monophones1 -i -l dlog dict source/sort.lex
python3 code/mlf.py < source/low.lab > words.mlf
HLEd -l '*' -d dict -i phones0.mlf mkphones0.led words.mlf
HLEd -l '*' -d dict -i phones1.mlf mkphones1.led words.mlf
python3 code/gen_scp.py > codetr.scp
HCopy -T 1 -C config -S codetr.scp
python3 code/gen_scp.py > train.scp
; create proto file
mkdir hmm0
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