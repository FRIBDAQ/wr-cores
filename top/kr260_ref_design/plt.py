import sys
import matplotlib.pyplot as plt

res = []
with open(sys.argv[1]) as f:
    for line in f:
        res.append(int(line))

plt.plot(res)
plt.ylabel('some numbers')
plt.show()

