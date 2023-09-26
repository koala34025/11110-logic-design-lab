with open('base.txt') as fh:
    with open('result.txt', 'w') as fhw:
        for line in fh.readlines():
            fhw.write("12'h" + line)