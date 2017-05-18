@# Example input file for `run_tests.py'.
@# 
@# Original Author: David Banas
@# Original Date:   July 20, 2012
@# 
@# Copyright (c) 2012 David Banas; All rights reserved World wide.

<test>
    <name>@(name)</name>
    <result>Visual</result>
    <description>Model frequency response for: @(description)</description>
    <output>
@{
from pylab import *
import pyibisami.amimodel as ami
figure(1)
cla()
figure(2)
cla()
ref = None
for cfg in data:
    cfg_name = cfg[0]
    params = cfg[1]
    if(len(cfg) > 2):
        reference = ref_dir + '/' + name.split()[0] + '/' + cfg[2]
    else:
        reference = None
    initializer = ami.AMIModelInitializer(params[0])
    items = params[1].items()
    items.sort(reverse=True)  # Note: This step is MANDATORY!
    for item in items:
        exec ('initializer.' + item[0] + ' = ' + repr(item[1]))
    model.initialize(initializer)
    print '        <block name="Model Initialization (' + cfg_name + ')" type="text">'
    print "MUT:"
    print model.msg
    print model.ami_params_out
    h = model.initOut
    T = model.sample_interval
    t = array([i * T for i in range(len(h))])
    s = cumsum(h) * T  # Step response.
    # The weird shifting by half the h-vector length is to better accomodate frequency-domain models.
    half_len = len(h) // 2
    s2 = model.getWave(array([0.0] * half_len + [1.0] * half_len))
    # s2 = pad(s2[half_len:], (0, half_len), 'edge')
    h2 = diff(s2)
    H = fft(h)
    H *= s[-1] / abs(H[0])  # Normalize for proper d.c.
    H2 = fft(h2)
    H2 *= s2[-1] / abs(H2[0])
    f = array([i * 1.0 / (T * len(h)) for i in range(len(h) / 2)])
    rgb_main, rgb_ref = plot_colors.next()
    color_main = "#%02X%02X%02X" % (rgb_main[0] * 0xFF, rgb_main[1] * 0xFF, rgb_main[2] * 0xFF)
    color_ref = "#%02X%02X%02X" % (rgb_ref[0] * 0xFF, rgb_ref[1] * 0xFF, rgb_ref[2] * 0xFF)
    semilogx(f / 1.e9, 20. * log10(abs(H[:len(f)])),        label=cfg_name+'_Init',    color=color_main)
    semilogx(f / 1.e9, 20. * log10(abs(H2[:len(f)])), '.',  label=cfg_name+'_GetWave', color=color_main)
    if(reference):
        try:
            if(ref is None):
                ref = ami.AMIModel(reference)
            initializer.root_name = 'easic_rx'
            ref.initialize(initializer)
            print "Reference:"
            print ref.msg
            print ref.ami_params_out
            href = ref.initOut
            sref = cumsum(href) * T
            Href = fft(href)
            Href *= sref[-1] / abs(Href[0])  # Normalize for proper d.c.
            r = Href
        except:
            r = ami.interpFile(reference, T)
        semilogx(f / 1.e9, 20. * log10(abs(r[:len(r)/2])), label=cfg_name+'_ref', color=color_ref)
    print '        </block>'
title('Model Frequency Response')
xlabel('Frequency (GHz)')
ylabel('|H(f)| (dB)')
axis(xmin=0.1, xmax=20, ymin=-30)
legend(loc='lower left')
filename = plot_names.next()
savefig(filename)
}
        <block name="Model Frequency Response" type="image">@(filename)</block>
    </output>
</test>

