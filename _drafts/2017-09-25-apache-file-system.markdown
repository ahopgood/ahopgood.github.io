---
layout: post
title:  "Apache Virtual File System (VFS) and Secure File Transfer Protocol (SFTP)"
date: 2017-09-25
categories: Java Apache VFS SFTP
---

The Apache [Virtual File System](#VFS) provides an abstraction for file systems enabling a Java program to reliably access different types of file system through the same abstraction / contract such as being able to access both a local file system and a remote SFTP server.  

When using the SFTP provider it is worth noting that the JSch (Java Secure Channel) maven dependency is required:

```
<dependency>
    <groupId>com.jcraft</groupId>
    <artifactId>jsch</artifactId>
    <version>0.1.54</version>
</dependency>

``` 
Without this you will get nonsensical error messages when attempting to connect to the SFTP server, this information is buried in the JavaDoc of the [SFTPClientFactory](#SFTPClientFactory).  

There is a bug finding the [isReadable](#isReadable) value over the SFTP provider when using version **2.1 or higher** so if that is a deal breaker I'd recommend using version **2.0** until the linked bug report is resolved.

[VFS]:	https://commons.apache.org/proper/commons-vfs/
[SFTPClientFactory]:		https://commons.apache.org/proper/commons-vfs/apidocs/org/apache/commons/vfs2/provider/sftp/SftpClientFactory.html
[isReadble]: https://issues.apache.org/jira/browse/VFS-617