#!/usr/bin/python3
import sys
import numpy as np

from dash import Dash, dcc, html, Input, Output
import plotly.graph_objects as go
from scipy.signal import resample_poly

from os import listdir
from os.path import isfile, join, isdir
import parse

def zch(u, Nzc, q = 0, dtype=np.complex64):
    n = np.arange(Nzc)
    cf = np.mod(Nzc, 2)
    return np.exp(-1j * np.pi * u * n * (n + cf + 2*q)/Nzc, dtype=dtype)

app = Dash(__name__)

app.layout = html.Div(children=[
    dcc.Dropdown(['live','not live'], 'live', id='dropdown2'),
    dcc.Dropdown(['pdp','freq','phase'], 'pdp', id='dropdown'),
    dcc.Graph(id='graph'),
    dcc.Input(
        id='input-text',
        type='text',
        value='.'
    ),
    dcc.Input(
        id='input-text2',
        type='text',
        value=''
    ),
    dcc.Input(
        id='input-number',
        type='number',
        value=0
    ),
    dcc.Interval(
        id='interval-component',
        interval=1000,
        n_intervals=0
    )
])


@app.callback([
              Output('graph', 'figure'),
              Output('input-number','value'),
              Output('input-text','value'),
              Output('input-text2','value')
              ],
              [
               Input('input-number', 'value'),
               Input('input-text','value'),
               Input('dropdown','value'),
               Input('interval-component','n_intervals'),
               Input('dropdown2','value'),
               Input('input-text2','value')
               ])
def update_graph(*vals):
    # parameters
    L = 1024
    F = 813
    choice = vals[2]
    upsamp = 1 # only for visibility

    fig = go.Figure()

    file_parse_form = 'rx_ch0_{}.dat'
    measdir_parse_form = '{}_{}'

    datadir = vals[1]
    measdir = vals[5]
    file_id = int(vals[0])
    meas_id = 0
    nrx = 1


    if vals[4] == 'live':
        # find measdir
        meas_id = 0
        for f in listdir(datadir):
            if isdir(join(datadir,f)):
                res = parse.parse(measdir_parse_form, f)
                if res is not None:
                    if int(res[1]) > meas_id:
                        meas_id = int(res[1])
                        measdir = '{}_{}'.format(res[0], res[1])

    # find most recent file
    file_id_max = 0
    for f in listdir(measdir):
        if isfile(join(measdir,f)):
            res = parse.parse(file_parse_form, f)
            if res is not None:
                if int(res[0]) > file_id_max:
                    file_id_max = int(res[0])

    # put some bounds on file_id
    if vals[4] == 'live':
        file_id = file_id_max
    else:
        if file_id < 0:
            file_id = 0
        elif file_id > file_id_max:
            file_id = file_id_max


    # detect the number of channels
    while True:
        fn = '{}/{}/rx_ch{}_{}.dat'.format(datadir, measdir, nrx, file_id)
        if (not isfile(fn)):
            break
        else:
            nrx = nrx + 1

    for ch in range(nrx):
        # get the file
        dt = np.dtype([('re', np.int16), ('im', np.int16)])

        fn = '{}/{}/rx_ch{}_{}.dat'.format(datadir, measdir, ch, file_id)

        a = np.fromfile(fn, dtype=dt)
        b = np.zeros(len(a),dtype=np.complex64)
        b[:].real = a['re']/(2**15)
        b[:].imag= a['im']/(2**15)
        y = b[:L]

        # freq
        # y = np.fft.fftshift(np.fft.fft(y))

        # time 
        xzch = zch(1, F)

        if choice == 'pdp':
            y = np.fft.fft(y)
            y = np.roll(y, int(np.floor(F/2)))
            y = y[:F]
            y = 20*np.log10(abs(np.fft.ifft(y[:F]/xzch)))
            y = resample_poly(y, upsamp, 1)

            # make graph
            fig.add_trace(go.Scatter(x=np.arange(L*upsamp),
                    y=y, mode='lines',name='ch{}'.format(ch)))
        elif choice == 'phase':
            y = np.fft.fft(y)
            y = np.roll(y, int(np.floor(F/2)))
            y0 = y[:F]
            y = 20*np.log10(abs(np.fft.ifft(y[:F]/xzch)))
            yidx = np.argmax(y)
            y = y0 * np.exp(1j*2*np.pi*yidx/F*np.arange(F))
            y = np.angle(y[:F]/xzch)

            fig.add_trace(go.Scatter(x=np.arange(L),
                    y=y, mode='lines',name='ch{}'.format(ch)))
        elif choice == 'freq':
            y = np.fft.fft(y)
            y = np.roll(y, int(np.floor(F/2)))
            y0 = y[:F]
            y = 20*np.log10(abs(y0))

            fig.add_trace(go.Scatter(x=np.arange(L*upsamp),
                    y=y, mode='lines',name='ch{}'.format(ch)))

    if choice == 'pdp':
        fig.update_layout(xaxis_title='Delay', yaxis_title='Channel gain [dB]', height=550)
    elif choice == 'phase':
        fig.update_layout(yaxis_range=[-3.14,3.14],xaxis_title='Frequency', yaxis_title='Phase [rad]', height=550)
    elif choice == 'freq':
        fig.update_layout(yaxis_range=[-3.14,3.14],xaxis_title='Frequency', yaxis_title='Channel gain [dB]', height=550)

    if vals[4] == 'live':
        fig['layout']['uirevision'] = 'interval-component'
    else:
        fig['layout']['uirevision'] = 'interval-number'

    return fig, file_id, datadir, measdir


if __name__ == '__main__':
    app.run_server(host='0.0.0.0',debug=True, port=8050)
