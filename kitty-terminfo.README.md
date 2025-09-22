This is what is needed for kitty
```
infocmp -x xterm-kitty > /tmp/xterm-kitty.terminfo
scp /tmp/xterm-kitty.terminfo imac.cg.home.arpa:/tmp/
ssh imac.cg.home.arpa 'mkdir -p ~/.terminfo && tic -x /tmp/xterm-kitty.terminfo && rm /tmp/xterm-kitty.terminfo'
```

Basic (single host):

    ./deploy-kitty-terminfo.sh imac.cg.home.arpa

Multiple hosts:

    ./deploy-kitty-terminfo.sh host1 host2 host3

From a file:

    cat hosts.txt
    imac.cg.home.arpa
    ./deploy-kitty-terminfo.sh --hosts-file hosts.txt

./deploy-kitty-terminfo.sh --force imac.cg.home.arpa

Dry run (no changes):

    ./deploy-kitty-terminfo.sh --dry-run imac.cg.home.arpa

Parallel (4 at a time):

    ./deploy-kitty-terminfo.sh --hosts-file hosts.txt --parallel 4

Verbose debug:

    ./deploy-kitty-terminfo.sh -v imac.cg.home.arpa

Quick Check After Deployment

    ssh imac.cg.home.arpa 'infocmp xterm-kitty >/dev/null && echo OK'
