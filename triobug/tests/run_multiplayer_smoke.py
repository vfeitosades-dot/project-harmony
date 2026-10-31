"""Run the complete game in three separate Godot processes on loopback UDP.
Test fixtures reposition robots and cores; abilities, movement, physics, puzzle
checks, doors, checkpoints, victory, pause, RPCs and disconnects remain production.
Requires Godot 4.6.x on PATH and a sandbox which permits local network sockets.
"""
from pathlib import Path
import os
import subprocess
import sys
import time

project = Path(__file__).resolve().parents[1]
logs = project.parent / 'multiplayer-test-logs'
logs.mkdir(exist_ok=True)
processes = []
for role in ('host', 'gravi', 'liga'):
    env = os.environ.copy()
    for key, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        path = logs / role / suffix
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    output = (logs / f'{role}.log').open('w')
    proc = subprocess.Popen(['godot', '--headless', '--path', str(project), '--script',
                             'res://tests/multiplayer_smoke.gd', '--', role],
                            stdout=output, stderr=subprocess.STDOUT, env=env)
    processes.append((role, proc, output))
    time.sleep(0.3)
failed = False
for role, proc, output in processes:
    try:
        proc.wait(timeout=45)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
    output.close()
    print(f'--- {role} exit={proc.returncode} ---')
    text = (logs / f'{role}.log').read_text()
    print('\n'.join(line for line in text.splitlines()
                    if line.startswith(('PASS ', 'FAIL ', 'RESULT ')) or 'ERROR:' in line))
    if proc.returncode or 'FAIL ' in text or 'ERROR:' in text:
        failed = True
print(f'Logs: {logs}')
sys.exit(1 if failed else 0)
