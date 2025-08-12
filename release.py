#!/usr/bin/env python3

import subprocess


subprocess.run(['mkdir', './release'], check=False)
subprocess.run(['rm', '-rf', './release/*'], check=False)

subprocess.run(['cp', 'int64.js', './release/int64.js'], check=False)
subprocess.run(['cp', 'offsets.js', './release/offsets.js'], check=False)
subprocess.run(['cp', 'pwn.js', './release/pwn.js'], check=False)
subprocess.run(['cp', 'stages.js', './release/stages.js'], check=False)
subprocess.run(['cp', 'utils.js', './release/utils.js'], check=False)
subprocess.run(['cp', 'index_release.html', './release/index.html'], check=False)