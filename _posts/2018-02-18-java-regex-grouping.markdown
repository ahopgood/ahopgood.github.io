---
layout: post
title:  "Java's Regex Grouping"
date: 2018-02-18
categories: Java Regex
---

I recently used Java's regex (regular expression) matching and powerful grouping feature and yet again remembered just how powerful it can be.  
I figured I'd do a recap here for prosperity.  

## Creating a Pattern and a Matcher
In this example I'm going to match on two simple numeric strings with a limit of 5 characters each and separated by a hyphen, e.g. *12345-67890*.
1. First you create a regex to match the behaviour we want
2. Then compile the regex into a `Pattern` object
3. This pattern object can then be used on an input string to create a `Matcher`
```
String myNumeric = "12345-67890";
Pattern myPattern = Pattern.compile("[0-9]{5}-[0-9]{5}");
Matcher myMatcher = myPattern.matcher(myNumeric);
myMatcher.matches();
```
A Matcher has a some key operations:
* `matches()` used to confirm a match for the entire input string, returning a boolean
* `find()` to find the next match to our pattern within the next subsequence of the input string.

A `Pattern` can be reused for multiple input strings, the matcher however is particular to the input string.  

## Grouping
To create a regex that supports grouping you need to make use of parentheses `()` (also known as brackets) to bound your group.  
Each set of parentheses will mark a group.  
Groups are identified by a number and are counted from the left most opening parantheses to the right most.   
In order to access the groups via `myMatcher.group(int group);` you will need to either call `matches()` or `find()` to parse the string with our regex.

Below are two examples of grouping using the same _general_ pattern.

`([0-9]{5})-([0-9]{5})`   
Group 0 = whole content of regex, group 1 = first group of five numbers, group 2 = second group of five numbers
Printing out the groups (0,1,2) produces:
>
12345-67890  
12345  
67890  

`(([0-9]{5})-)([0-9]{5})`   
Group 0 = whole content of regex, group 1 = first group of five numbers **incl** the hyphen, group 2 = first group of five numbers, group 3 = second group of five numbers
Printing out the groups (0,1,2,3) produces:
>
12345-67890  
12345-  
12345  
67890  

## Grouping by name
Grouping by name still makes use of the parentheses but includes additional syntax for assigning names.  
Using a question mark `?` followed by a name within two square brackets (`<>`) will denote your grouping name. 

`(?<first>[0-9]{5})-(?<second>[0-9]{5})` 
Here we've added two names; _first_ and _second_ to our existing groups.  
Now we can use `matcher.group("first")` and `matcher.group("second")` to view these groups, producing the following output:

>
12345
67890  

## Closing thoughts
Using grouping can make debugging and building up a regex much easier, you can print off the group content to see what it matches on and then continue with your expression.  
Using the naming feature makes following the matching much easier for other people to read your regex and understand your intentions.  

