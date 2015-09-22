---
layout: post
title:  "The Static Resource Location"
date: 2015-02-20
categories: java dropwizard
---

The **AssetsBundle** for dropwizard are designed to provide a way to server static resources via jetty.

Unfortunately the dropwizard dependencies don't tend to come with source code or javadoc to explain how they work.

It turns out that the **AssetsBundle** allows for five constructors:  

    public AssetsBundle()
	...
	public AssetsBundle(String path)
	...
	public AssetsBundle(String resourcePath, String uriPath)
	...  
	public AssetsBundle(String resourcePath, String uriPath, String indexFile)
	...  
	public AssetsBundle(String resourcePath, String uriPath, String indexFile, String assetsName)
	{
		Preconditions.checkArgument(resourcePath.startsWith("/"), "%s is not an absolute path", 	new Object[] { resourcePath });
    	Preconditions.checkArgument(!"/".equals(resourcePath), "%s is the classpath root", new 	Object[] { resourcePath });
    	this.resourcePath = (resourcePath + '/');
    	this.uriPath = (uriPath + '/');
    	this.indexFile = indexFile;
    	this.assetsName = assetsName;
	}

What none of this tells you is that the **AssetsBundle** will look for resources in the **/src/main/resources/** source folder and **anything** you add as a resource path will be appended to this location (and ergo will be found under this folder hierarchy) e.g. **mypages** will be found in **/src/main/resources/mypages/**

There is a good lesson to be learned here, it can be easy to take for granted that code will either:  
1. Have sufficient javadoc  
2. Source code will be available  
3. Source code will have sufficient code comments  
4. Source code will be self documenting