## **ROUTING BASED ON GENEVE OPTIONS HEADER**

Repository for k8s lab modified to add geneve tunnels and manage routing with geneve options.

It uses the header "Options" of the Geneve Tunnels to route the packets to their destination. This options are introduced with native linux application called Traffic Control (tc) and are based on the destination IP. The redirection is done with tc-flower.
 
The basic lab manual, in Spanish, is [here](doc/rdsv-p4.md)

It can be tested by executing the following command:

```bash
./config.sh
```

And when you are done:

```bash
./uninstall.sh
```
