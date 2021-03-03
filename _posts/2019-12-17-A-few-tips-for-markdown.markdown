---
layout: post
title:  "A few tips for markdown in Jekyll"
date: 2019-12-17
categories: jekyll markdown
---

In my previous post on a [table of contents in hugo](/hugo/markdown/2018/10/18/hugo-toc.html) I became aware that I didn't necessarily like the formatting of code blocks in Jekyll.  
Yes it provides multi-line blocks but the way it renders leaves me feeling somewhat unhappy as the highlight formatting for the code only goes as far as the text content of the line. This results in a distracting two-tone saw tooth effect when using the three backtick code block \`\`\`code here\`\`\` method:  
```
testing a rather long line 
a shorter line
another longer line to provide emphasis on the highlighting/formatting issue
now for a readlly long line that forces some sort of line wrapping behaviour to highlight how ugly this code block really can get when pushed.
```
I also discovered that markdown does not handle double braces {\{some content\}} at all.  
So in order to present the following hugo code snippet I had to find an alternative to the three backtick method: 

<pre><code>
{&#123; if .Params.toc  &#125;}
{&#123; partial "toc-ignore-h1.html" .  &#125;}  
{&#123; end  &#125;}
</code></pre>

You can create better code blocks in Jekyll's markdown by using the `<pre><code></code></pre>` blocks directly.  

>\<code><pre>  
>{&#123; if .Params.toc  &#125;}  
>{&#123; partial "toc-ignore-h1.html" .  &#125;}    
>{&#123; end  &#125;}  
>\</code></pre>  

This provides a multi-line block whose formatting/highlighting covers the whole block regardless of the text content, line wrapping still isn't handled but I actually think that is a "good thing" but hey I'm a bit weird.  
  
In the case of characters that markdown cannot handle within typical code blocks you use the [html encoded character references](https://en.wikipedia.org/wiki/Character_encodings_in_HTML#Character_references) for these characters:
* `&#123;` &#123; - left brace
	* `{&#123;` {&#123; - **double** left brace
* `&#125;` &#125; - right brace
	* `&#125;}` &#125;} - **double** right brace
* `&#8226;` &#8226; - bullet point
* `&amp;` &amp; - ampersand
* `&cent;` &cent; - cent
* `&copy;` &copy; - copyright symbol
* `&lt;` &lt; - less than / left, angled bracket
* `&gt;` &gt; - greater than / right, angled bracket

So now I have the means to render a code block including any characters that cannot be escaped easily with the usual backslash `\` technique.