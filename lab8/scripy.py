hc = 523
hd = 587
he = 659
hf = 698
hg = 784
__ = '__'
g = 392
b = 494
e = 330
c = 262
f = 349
d = 294

dic = {hc : '`hc', hd : '`hd', he : '`he', hf : '`hf', hg : '`hg', __ : '',
       g : '`g', b : '`b', e : '`e', c : '`c', f : '`f', d : '`d'}

measures2 = [
    hg, he, he, __, hf, hd, hd, __,
    hc, hd, he, hf, hg, hg, hg, __,
    hg, he, he, __, hf, hd, hd, __,
    hc, he, hg, hg, he, he, he, __,
    hd, hd, hd, hd, hd, he, hf, __,
    he, he, he, he, he, hf, hg, __,
    hg, he, he, __, hf, hd, hd, __,
    hc, he, hg, hg, hc, __, __, __
]

measures = [
    hc, __, __, __, g, __, b, __,
    hc, __, __, __, g, __, b, __,
    hc, __, __, __, g, __, b, __,
    hc, __, g, __, e, __, c, __,
    g, __, __, __, f, __, d, __,
    c, __, __, __, g, __, b, __,
    hc, __, __, __, g, __, b, __,
    hc, __, g, __, c, __, __, __
]
i = 0

for idx, note in enumerate(measures):
    print("")
    for j in range(8):
        if i%2 == 0:
            print(f"12'd{i}: toneL = {dic[note]};", end='')
        else:
            if j == 7 and note != __ and idx+1 < len(measures) and measures[idx+1] == note:
                print(f"\t12'd{i}: toneL = `sil;")
            else:
                print(f"\t12'd{i}: toneL = {dic[note]};")
        i += 1
    dic[__] = dic[note]