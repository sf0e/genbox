# Services in genbox

A **service** is a program that runs in the background - networking, a web
server, the SSH daemon, and so on. genbox uses its own service manager, but it
is designed to feel like OpenRC, so the commands will look familiar.

---

## The four commands

| Command | What it does |
| --- | --- |
| `rc-service` | Start, stop, restart, or check one service |
| `rc-update` | Choose which services start automatically at boot |
| `rc-status` | Show what is running right now |
| `/etc/init.d/<name>` | Run a service script directly |

---

## Looking at services

List every service script:

```sh
ls /etc/init.d/
```

See a service's description and its extra commands:

```sh
rc-service sshd describe
```

---

## Controlling a service right now

These take effect immediately but do **not** change what happens at boot:

```sh
rc-service sshd start
rc-service sshd stop
rc-service sshd restart
rc-service sshd status
```

You usually need to be root:

```sh
su -
rc-service sshd restart
```

---

## Choosing what starts at boot (runlevels)

A **runlevel** is a named group of services. genbox uses the OpenRC runlevel
names:

| Runlevel | When it runs | Typical services |
| --- | --- | --- |
| `sysinit` | Very early | device and filesystem setup |
| `boot` | Early | hostname, swap, system clock |
| `default` | Normal boot | networking, sshd |
| `shutdown` | On power-off | stop services, unmount |
| `nonetwork` | Alternate | boot without networking |

### Add a service to a runlevel

```sh
su -
rc-update add sshd default
```

### Remove a service from a runlevel

```sh
su -
rc-update del sshd default
```

### Show all runlevels and their services

```sh
rc-update show
```

---

## Seeing what is running

```sh
rc-status
```

Output shows each runlevel and whether each service is **started** or
**stopped**.

---

## Editing a service's settings

Service settings live in `/etc/conf.d/`. For example, the hostname:

```sh
# /etc/conf.d/hostname
hostname="mylaptop"
```

After editing, restart the service:

```sh
su -
rc-service hostname restart
```

---

## How the service scripts work

A service script in `/etc/init.d/` is just a shell script. It starts with:

```sh
#!/sbin/openrc-run
```

and usually defines a few functions:

```sh
#!/sbin/openrc-run

description="My example service"

depend() {
    need localmount
    after network
}

start() {
    ebegin "Starting my service"
    /usr/bin/mydaemon --daemon
    eend $?
}

stop() {
    ebegin "Stopping my service"
    killall mydaemon
    eend $?
}
```

- `description` is shown by `rc-service <name> describe`.
- `depend()` says what this service needs and in what order.
- `start()` and `stop()` do the work.
- `ebegin`/`eend` print the familiar `[ ok ]` / `[ !! ]` messages.

Most packages that ship an OpenRC script work unchanged in genbox.

---

## Writing your own service

1. Create the script:

   ```sh
   su -
   nano /etc/init.d/myservice
   ```

2. Make it executable:

   ```sh
   chmod +x /etc/init.d/myservice
   ```

3. Test it:

   ```sh
   rc-service myservice start
   ```

4. Make it permanent:

   ```sh
   rc-update add myservice default
   ```

For services that just run a single command (no special start/stop logic), the
script can be very short:

```sh
#!/sbin/openrc-run

description="My daemon"

command="/usr/sbin/mydaemon"
command_args="--foreground"
command_user="mydaemon"
pidfile="/run/mydaemon.pid"
command_background="yes"

depend() {
    need net
}
```

genbox provides the `start`/`stop`/`status` logic for you in that case.

---

## Dependency order (`depend()`)

Inside `depend()` you can say:

| Keyword | Meaning |
| --- | --- |
| `need X` | Start X first. Fail if X is not in a runlevel. |
| `use X` | Start X first **if** it is available. |
| `want X` | Start X first, but do not fail if missing. |
| `after X` | Start after X if X is present. |
| `before X` | Start before X. |
| `provide X` | This service provides the virtual name X. |

---

## If a service will not start

1. Run it in the foreground to see errors:
   ```sh
   su -
   /etc/init.d/myservice start
   ```
2. Check its configuration in `/etc/conf.d/`.
3. Check the logs in `/var/log/`.
4. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Under the hood

genbox's service manager lives in `/usr/libexec/genbox/` and provides its own
`/sbin/openrc-run`. It is **not** OpenRC - it is a small, independent
reimplementation that speaks the same language. See
[ARCHITECTURE.md](ARCHITECTURE.md).
