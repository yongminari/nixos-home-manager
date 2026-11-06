"""Manual integration check; run inside a logged-in user session.

Usage: python3 checks/dbus-service-dedup.py ORIGINAL_LAUNCHER PATCHED_LAUNCHER
Creates private buses only; never restarts the session/system bus.
"""
import os, pathlib, socket, subprocess, tempfile, time, signal, argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('original')
parser.add_argument('patched')
args=parser.parse_args()
original=args.original
patched=args.patched
def run(binary,conf,base):
    address=str(base/'socket'); listener=socket.socket(socket.AF_UNIX); listener.bind(address); listener.listen()
    log=base/'log'; pid=os.fork()
    if pid==0:
        os.dup2(listener.fileno(),3); os.set_inheritable(3,True)
        out=os.open(log,os.O_CREAT|os.O_WRONLY,0o600); os.dup2(out,2)
        env=dict(os.environ,LISTEN_PID=str(os.getpid()),LISTEN_FDS='1')
        os.execve(binary,[binary,'--scope','user','--config-file',str(conf)],env)
    listener.close()
    try:
        for _ in range(40):
            result=subprocess.run(['busctl','--address=unix:path='+address,'--timeout=1','call','org.freedesktop.DBus','/org/freedesktop/DBus','org.freedesktop.DBus','ListActivatableNames'],capture_output=True,text=True)
            if result.returncode==0: break
            time.sleep(.1)
        assert result.returncode==0,log.read_text()+result.stderr
        time.sleep(.2)
        journal=subprocess.check_output(['journalctl','-b',f'_PID={pid}','--no-pager','-o','cat'],text=True)
        return result.stdout,journal+log.read_text()
    finally:
        os.kill(pid,signal.SIGTERM); os.waitpid(pid,0)
with tempfile.TemporaryDirectory(prefix='dbus-dedup-') as tmp:
    root=pathlib.Path(tmp)
    for variant in ('same','conflict'):
        first=root/(variant+'-first'); first.mkdir(); second=root/(variant+'-second'); second.mkdir()
        content='[D-BUS Service]\nName=org.example.DedupTest\nExec=/bin/false\n'
        (first/'org.example.DedupTest.service').write_text(content)
        if variant=='same': (second/'org.example.DedupTest.service').symlink_to(first/'org.example.DedupTest.service')
        else: (second/'org.example.DedupTest.service').write_text(content.replace('/bin/false','/bin/true'))
        conf=root/(variant+'.conf'); conf.write_text(f'<busconfig><type>session</type><servicedir>{first}</servicedir><servicedir>{second}</servicedir><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>')
        results=[]
        for name,binary in [('original',original),('patched',patched)]:
            base=root/(variant+'-'+name); base.mkdir(); names,logs=run(binary,conf,base)
            warning='Ignoring duplicate name' in logs
            assert warning==(name=='original' or variant=='conflict'),logs
            results.append(names)
            print(variant,name,'duplicate warning:',warning)
        assert results[0]==results[1],results
    # Exercise real session configuration on a private socket; no live bus restart.
    results=[]
    for name,binary in [('original',original),('patched',patched)]:
        base=root/('real-'+name);base.mkdir()
        names,logs=run(binary,pathlib.Path('/etc/dbus-1/session.conf'),base)
        results.append(sorted(names.split()))
        print('real configuration',name,'warnings:',logs.count('Ignoring duplicate name'))
        if name=='patched': assert 'Ignoring duplicate name' not in logs,logs
    assert results[0]==results[1], 'activatable services changed'
    print('PASS: service lists preserved; same-file duplicates removed; real conflicts still reported')
