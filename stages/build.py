#!/usr/bin/env python3

import subprocess

# Build stage3
subprocess.run(['rm', 'stage3.h'], check=False)
subprocess.run(['make', 'clean'], check=True, cwd='stage3')
subprocess.run(['rm', '-rf', '.theos'], check=True, cwd='stage3')
subprocess.run(['make'], check=True, cwd='stage3')
subprocess.run(['ldid', '-S./entitlements.plist', '-M', '-Ksigncert.p12', '.theos/obj/arm64/stage3'], check=True, cwd='stage3')
subprocess.run(['./PayloadMaker.py', '.theos/obj/arm64/stage3', '../stage3.h'], check=True, cwd='stage3')

# Build stage1 & stage2
subprocess.run(['make', 'clean'], check=True)
subprocess.run(['make'], check=True)

# Convert the stages to a JS array literal
stages = open('stages', 'rb').read()

js = 'var stages = new Uint8Array(['
js += ','.join(map(str, stages))
js += ']);\n'
js += '''
stages.replace = function(oldVal, newVal) {
    for (var idx = 0; idx < this.length; idx++) {
        var found = true;
        for (var j = idx; j < idx + 8; j++) {
            if (this[j] != oldVal.byteAt(j - idx)) {
                found = false;
                break;
            }
        }
        if (found)
            break;
    }
    this.set(newVal.bytes(), idx);
};
'''

with open('stages.js', 'w') as f:
    f.write(js)

EXPORTS = [
        {'path': 'stages.js', 'content_type': 'text/javascript; charset=UTF-8'}
]

subprocess.run(['cp', 'stages.js', '..'], check=True)
subprocess.run(['rm', 'stages.js'], check=True)