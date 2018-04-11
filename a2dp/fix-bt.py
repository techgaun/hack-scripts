#!/usr/bin/python

import dbus
from dbus.mainloop.glib import DBusGMainLoop
import gobject

import subprocess
import time

# Where you keep the above script. Must be executable, obviously.
A2DP = '/home/mihara/.local/bin/a2dp'

# A list of device IDs that you wish to run it on.
DEV_IDS = ['00:18:09:30:FC:D8','FC:58:FA:B1:2D:25']

device_paths = []
devices = []

dbus_loop = DBusGMainLoop()
bus = dbus.SystemBus(mainloop=dbus_loop)

def generate_handler(device_id):

    last_ran = [0] # WHOA, this is crazy closure behavior: A simple variable does NOT work.

    def cb(*args, **kwargs):
        if args[0] == 'org.bluez.MediaControl1':
            if args[1].get('Connected'):
                print("Connected {}".format(device_id))
                if last_ran[0] < time.time() - 120:
                    print("Fixing...")
                    subprocess.call([A2DP,device_id])
                    last_ran[0] = time.time()
            else:
                print("Disconnected {}".format(device_id))

    return cb

# Figure out the path to the headset
man = bus.get_object('org.bluez', '/')
iface = dbus.Interface(man, 'org.freedesktop.DBus.ObjectManager')
for device in iface.GetManagedObjects().keys():
    for id in DEV_IDS:
        if device.endswith(id.replace(':','_')):
            device_paths.append((id, device))

for id, device in device_paths:
    headset = bus.get_object('org.bluez', device)
    headset.connect_to_signal("PropertiesChanged", generate_handler(id), dbus_interface='org.freedesktop.DBus.Properties')
    devices.append(headset)

loop = gobject.MainLoop()
loop.run()

