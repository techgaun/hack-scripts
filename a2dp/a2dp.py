#! /usr/bin/env python3.5
"""

Fixing bluetooth stereo headphone/headset problem in ubuntu 16.04 and also debian jessie, with bluez5.

Workaround for bug: https://bugs.launchpad.net/ubuntu/+source/indicator-sound/+bug/1577197
Run it with python3.5 or higher after pairing/connecting the bluetooth stereo headphone.

This will be only fixes the bluez5 problem mentioned above .

Licence: Freeware

See ``python3.5 a2dp.py -h``.

Shorthands:

    $ alias speakers="a2dp.py 10:08:C1:44:AE:BC"
    $ alias headphones="a2dp.py 00:22:37:3D:DA:50"
    $ alias headset="a2dp.py 00:22:37:F8:A0:77 -p hsp"

    $ speakers



Check here for the latest updates: https://gist.github.com/pylover/d68be364adac5f946887b85e6ed6e7ae

Thanks to:

 * https://github.com/DominicWatson, for adding the ``-p/--profile`` argument.
 * https://github.com/IzzySoft, for mentioning wait before connecting again.
 * https://github.com/AmploDev, for v0.4.0
 * https://github.com/Mihara, for autodetect & autorun service
 * https://github.com/dabrovnijk, for systemd service

Change Log
----------

- 0.5.2
  * Increasing the number of tries to 15.

- 0.5.2
  * Optimizing waits.

- 0.5.1
  * Increasing WAIT_TIME and TRIES

- 0.5.0
  * Autodetect & autorun service

- 0.4.1
  * Sorting device list

- 0.4.0
  * Adding ignore_fail argument by @AmploDev.
  * Sending all available streams into selected sink, after successfull connection by @AmploDev.

- 0.3.3
  * Updating default sink before turning to ``off`` profile.

- 0.3.2
  * Waiting a bit: ``-w/--wait`` before connecting again.

- 0.3.0
  * Adding -p / --profile option for using the same script to switch between headset and A2DP audio profiles

- 0.2.5
  * Mentioning [mac] argument.

- 0.2.4
  * Removing duplicated devices in select device list.

- 0.2.3
  * Matching ANSI escape characters. Tested on 16.10 & 16.04

- 0.2.2
  * Some sort of code enhancements.

- 0.2.0
  * Adding `-V/--version`, `-w/--wait` and `-t/--tries` CLI arguments.

- 0.1.1
  * Supporting the `[NEW]` prefix for devices & controllers as advised by @wdullaer
  * Drying the code.

"""

import sys
import re
import asyncio
import subprocess as sb
import argparse


__version__ = '0.5.2'


HEX_DIGIT_PATTERN = '[0-9A-F]'
HEX_BYTE_PATTERN = '%s{2}' % HEX_DIGIT_PATTERN
MAC_ADDRESS_PATTERN = ':'.join((HEX_BYTE_PATTERN, ) * 6)
DEVICE_PATTERN = re.compile('^(?:.*\s)?Device\s(?P<mac>%s)\s(?P<name>.*)' % MAC_ADDRESS_PATTERN)
CONTROLLER_PATTERN = re.compile('^(?:.*\s)?Controller\s(?P<mac>%s)\s(?P<name>.*)' % MAC_ADDRESS_PATTERN)
WAIT_TIME = 2.25
TRIES = 15
PROFILE = 'a2dp'


_profiles = {
    'a2dp': 'a2dp_sink',
    'hsp': 'headset_head_unit',
    'off': 'off'
}

# CLI Arguments
parser = argparse.ArgumentParser(prog=sys.argv[0])
parser.add_argument('-e', '--echo', action='store_true', default=False,
                    help='If given, the subprocess stdout will be also printed on stdout.')
parser.add_argument('-w', '--wait', default=WAIT_TIME, type=float,
                    help='The seconds to wait for subprocess output, default is: %s' % WAIT_TIME)
parser.add_argument('-t', '--tries', default=TRIES, type=int,
                    help='The number of tries if subprocess is failed. default is: %s' % TRIES)
parser.add_argument('-p', '--profile', default=PROFILE,
                    help='The profile to switch to. available options are: hsp, a2dp. default is: %s' % PROFILE)
parser.add_argument('-V', '--version', action='store_true', help='Show the version.')
parser.add_argument('mac', nargs='?', default=None)


# Exceptions
class SubprocessError(Exception):
    pass


class RetryExceededError(Exception):
    pass


class BluetoothctlProtocol(asyncio.SubprocessProtocol):
    def __init__(self, exit_future, echo=True):
        self.exit_future = exit_future
        self.transport = None
        self.output = None
        self.echo = echo

    def listen_output(self):
        self.output = ''

    def not_listen_output(self):
        self.output = None

    def pipe_data_received(self, fd, raw):
        d = raw.decode()
        if self.echo:
            print(d, end='')

        if self.output is not None:
            self.output += d

    def process_exited(self):
        self.exit_future.set_result(True)

    def connection_made(self, transport):
        self.transport = transport
        print('Connection MADE')

    async def send_command(self, c):
        stdin_transport = self.transport.get_pipe_transport(0)
        # noinspection PyProtectedMember
        stdin_transport._pipe.write(('%s\n' % c).encode())

    async def search_in_output(self, expression, fail_expression=None):
        if self.output is None:
            return None

        for l in self.output.splitlines():
            if fail_expression and re.search(fail_expression, l, re.IGNORECASE):
                raise SubprocessError('Expression "%s" failed with fail pattern: "%s"' % (l, fail_expression))

            if re.search(expression, l, re.IGNORECASE):
                return True

    async def send_and_wait(self, cmd, wait_expression, fail_expression='fail'):
        try:
            self.listen_output()
            await self.send_command(cmd)
            while not await self.search_in_output(wait_expression.lower(), fail_expression=fail_expression):
                await wait()
        finally:
            self.not_listen_output()

    async def disconnect(self, mac):
        print('Disconnecting the device.')
        await self.send_and_wait('disconnect %s' % ':'.join(mac), 'Successful disconnected')

    async def connect(self, mac):
        print('Connecting again.')
        await self.send_and_wait('connect %s' % ':'.join(mac), 'Connection successful')

    async def trust(self, mac):
        await self.send_and_wait('trust %s' % ':'.join(mac), 'trust succeeded')

    async def quit(self):
        await self.send_command('quit')

    async def get_list(self, command, pattern):
        result = set()
        try:
            self.listen_output()
            await self.send_command(command)
            await wait()
            for l in self.output.splitlines():
                m = pattern.match(l)
                if m:
                    result.add(m.groups())
            return sorted(list(result), key=lambda i: i[1])
        finally:
            self.not_listen_output()

    async def list_devices(self):
        return await self.get_list('devices', DEVICE_PATTERN)

    async def list_paired_devices(self):
        return await self.get_list('paired-devices', DEVICE_PATTERN)

    async def list_controllers(self):
        return await self.get_list('list', CONTROLLER_PATTERN)

    async def select_paired_device(self):
        print('Selecting device:')
        devices = await self.list_paired_devices()
        count = len(devices)

        if count < 1:
            raise SubprocessError('There is no connected device.')
        elif count == 1:
            return devices[0]

        for i, d in enumerate(devices):
            print('%d. %s %s' % (i+1, d[0], d[1]))
        print('Select device[1]:')
        selected = input()
        return devices[0 if not selected.strip() else (int(selected) - 1)]


async def wait(delay=None):
    return await asyncio.sleep(WAIT_TIME or delay)


async def execute_command(cmd, ignore_fail=False):
    p = await asyncio.create_subprocess_shell(cmd, stdout=sb.PIPE, stderr=sb.PIPE)
    stdout, stderr = await p.communicate()
    stdout, stderr = \
        stdout.decode() if stdout is not None else '', \
        stderr.decode() if stderr is not None else ''
    if p.returncode != 0 or stderr.strip() != '':
        message = 'Command: %s failed with status: %s\nstderr: %s' % (cmd, p.returncode, stderr)
        if ignore_fail:
            print('Ignoring: %s' % message)
        else:
            raise SubprocessError(message)
    return stdout


async def execute_find(cmd, pattern, tries=0, fail_safe=False):
    tries = tries or TRIES

    message = 'Cannot find `%s` using `%s`.' % (pattern, cmd)
    retry_message = message + ' Retrying %d more times'
    while True:
        stdout = await execute_command(cmd)
        match = re.search(pattern, stdout)

        if match:
            return match.group()
        elif tries > 0:
            await wait()
            print(retry_message % tries)
            tries -= 1
            continue

        if fail_safe:
            return None

        raise RetryExceededError('Retry times exceeded: %s' % message)


async def find_dev_id(mac, **kw):
    return await execute_find('pactl list cards short', 'bluez_card.%s' % '_'.join(mac), **kw)


async def find_sink(mac, **kw):
    return await execute_find('pacmd list-sinks', 'bluez_sink.%s' % '_'.join(mac), **kw)


async def set_profile(device_id, profile):
    print('Setting the %s profile' % profile)
    try:
        return await execute_command('pactl set-card-profile %s %s' % (device_id, _profiles[profile]))
    except KeyError:
        print('Invalid profile: %s, please select one one of a2dp or hsp.' % profile, file=sys.stderr)
        raise SystemExit(1)


async def set_default_sink(sink):
    print('Updating default sink to %s' % sink)
    return await execute_command('pacmd set-default-sink %s' % sink)


async def move_streams_to_sink(sink):
    streams = await execute_command('pacmd list-sink-inputs | grep "index:"', True)
    for i in streams.split():
        i = ''.join(n for n in i if n.isdigit())
        if i != '':
            print('Moving stream %s to sink' % i)
            await execute_command('pacmd move-sink-input %s %s' % (i, sink))
    return sink


async def main(args):
    global WAIT_TIME, TRIES

    if args.version:
        print(__version__)
        return 0

    mac = args.mac

    # Hacking, Changing the constants!
    WAIT_TIME = args.wait
    TRIES = args.tries

    exit_future = asyncio.Future()
    transport, protocol = await asyncio.get_event_loop().subprocess_exec(
        lambda: BluetoothctlProtocol(exit_future, echo=args.echo), 'bluetoothctl'
    )

    try:

        if mac is None:
            mac, _ = await protocol.select_paired_device()

        mac = mac.split(':' if ':' in mac else '_')
        print('Device MAC: %s' % ':'.join(mac))

        device_id = await find_dev_id(mac, fail_safe=True)
        if device_id is None:
            print('It seems device: %s is not connected yet, trying to connect.' % ':'.join(mac))
            await protocol.trust(mac)
            await protocol.connect(mac)
            device_id = await find_dev_id(mac)

        sink = await find_sink(mac, fail_safe=True)
        if sink is None:
            await set_profile(device_id, args.profile)
            sink = await find_sink(mac)

        print('Device ID: %s' % device_id)
        print('Sink: %s' % sink)

        await set_default_sink(sink)
        await wait()

        await set_profile(device_id, 'off')

        if args.profile is 'a2dp':
            await protocol.disconnect(mac)
            await wait()
            await protocol.connect(mac)

        device_id = await find_dev_id(mac)
        print('Device ID: %s' % device_id)

        await wait(2)
        await set_profile(device_id, args.profile)
        await set_default_sink(sink)
        await move_streams_to_sink(sink)

    except (SubprocessError, RetryExceededError) as ex:
        print(str(ex), file=sys.stderr)
        return 1
    finally:
        print('Exiting bluetoothctl')
        await protocol.quit()
        await exit_future

        # Close the stdout pipe
        transport.close()

    if args.profile == 'a2dp':
        print('"Enjoy" the HiFi stereo music :)')
    else:
        print('"Enjoy" your headset audio :)')


if __name__ == '__main__':
    sys.exit(asyncio.get_event_loop().run_until_complete(main(parser.parse_args())))
