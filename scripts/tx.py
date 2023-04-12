# Author: Michiel Sandra, Lund University
import numpy as np

def zch(u, Nzc, q = 0, dtype=np.complex64):
    n = np.arange(Nzc)
    cf = np.mod(Nzc, 2)
    return np.exp(-1j * np.pi * u * n * (n + cf + 2*q)/Nzc, dtype=dtype)

dt = np.dtype([('re', np.int16), ('im', np.int16)])

# Parameters
f = 813 # amount of frequency points # floor(400 MHz / 500 MHz *1024 )
l = 1024 # L 
p = 1024 # p must be a multiple of l (for the current version of this code)
m = 128 # M 
ntx = 4
ntx_offset = 0
period = 2500000
r = period - ntx * ((m*l) + p)

# Generate ZCH sequence in freq domain and convert to time domain
yzch = zch(1, f)
y = np.concatenate((yzch, np.zeros(l-f)))
y = np.roll(y, -int(np.floor(f/2)))
y = np.fft.ifft(y)

# Some scaling
factor = 0.85 * 1/max(np.max(abs(y.real)),np.max(abs(y.imag)))
y = factor*y

# Change data format to sc16
y16 = np.zeros(l, dt)
y16['re'] = (y.real * (2**15))
y16['im'] = (y.imag * (2**15))

for i in range(ntx_offset, ntx):
    out = np.array([],dtype=dt)
    for j in range(ntx_offset, ntx):
        if j == i:
            out = np.append(out, np.tile(y16,m+int(p/l)))
        else:
            out = np.append(out, np.zeros(m*l+p,dt))

        print(np.size(out))

    out = np.append(out, np.zeros(r,dt))

    out.tofile('tx{}.dat'.format(i))
